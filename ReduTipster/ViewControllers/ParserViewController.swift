//
//  ParserViewController.swift
//  ReduTipster
//
//  Created by Tobias Scholze on 23/01/16.
//  Copyright © 2016 Tobias Scholze. All rights reserved.
//

import Cocoa
import Kanna
import SwiftyJSON

class ParserViewController: TableViewController
{
    //  MARK: - Constants -
    
    private let userDefaultsDatsSourceIdentifier    = "rt-datasource"
    private let userDefaultsItemLimitIdentifier     = "rt-itemlimit"
    
    // MARK: - Outlets -
    
    @IBOutlet var dataSourceTextField   : NSTextField!
    @IBOutlet var itemLimitTextField    : NSTextField!
    
    // MARK: - Overriding TableViewController methods -
    
    override func setupView()
    {
        super.setupView()
        
        if let dataSource = userDefaults.stringForKey(userDefaultsDatsSourceIdentifier)
        {
            dataSourceTextField.stringValue = dataSource
        }
        
        if let itemLimit = userDefaults.stringForKey(userDefaultsItemLimitIdentifier)
        {
            itemLimitTextField.stringValue = itemLimit
        }
    }
    
    override func willNavigateToGeneratedContentView()
    {
        super.willNavigateToGeneratedContentView()
        
        userDefaults.setObject(dataSourceTextField.stringValue, forKey: userDefaultsDatsSourceIdentifier)
        userDefaults.setObject(itemLimitTextField.stringValue, forKey: userDefaultsItemLimitIdentifier)
    }
    
    /// Parses a url and compresses / enriches the data into RTApp objects
    ///
    /// - return: List of found RTApp objects
    override func parseDataFromUrl() -> [RTApp]
    {
        var foundApps = [RTApp]()
        
        guard let tickerHtml = getTickerHtml() else
        {
            return foundApps
        }
        
        if let document = Kanna.HTML(html: tickerHtml, encoding: NSUTF8StringEncoding)
        {
            // Title & App Store Link
            for item in document.xpath("//*[contains(@class, 'title')]/a")
            {
                let app = RTApp()
                app.title = "Nice app name"
                
                if let link = item["href"]
                {
                    if useOwnAffiliateCodeButton.state == NSOnState
                    {
                        let components = link.componentsSeparatedByString("?")
                        
                        guard components.count > 1 else
                        {
                            app.appStoreLink = link
                            continue
                        }
                        
                        app.appStoreLink = components[0]
                        
                        if !affiliateCodeTextField.stringValue.isEmpty
                        {
                            app.appStoreLink? += "?\(affiliateCodeTextField.stringValue)"
                        }
                    }
                        
                    else
                    {
                        app.appStoreLink = link
                    }
                    
                    let components = link.componentsSeparatedByString("/")
                    guard var appId = components.last else
                    {
                        continue
                    }
                    
                    appId = appId.stringByReplacingOccurrencesOfString("id", withString: "")
                    
                    if appId.containsString("?")
                    {
                        appId = appId.substringToIndex(appId.characters.indexOf("?")!)
                    }
                    
                    app.appId = appId
                }
                
                foundApps.append(app)
            }
            
            // Platform identifier
            var i = 0
            for item in document.xpath("//div[contains(@class, 'device')]")
            {
                let identifier = item.text!.stringByReplacingOccurrencesOfString("\t", withString: "").stringByReplacingOccurrencesOfString("\n", withString: "")
                //foundApps[i].platformStringValue = identifier
                foundApps[i].platform = RTPlatform(rawValue: identifier)
                i++
            }
            
            // Undiscounted Price
            i = 0
            for item in document.xpath("//*[contains(@class, 'oldprice')]")
            {
                if var appOldPrice = item.text
                {
                    appOldPrice = appOldPrice.stringByReplacingOccurrencesOfString("Gratis", withString: "0.00")
                    appOldPrice = appOldPrice.stringByReplacingOccurrencesOfString("€", withString: "")
                    appOldPrice = appOldPrice.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    foundApps[i].undiscountedPrice = appOldPrice
                    i++
                }
            }
            
            // Discounted Price
            i = 0
            for item in document.xpath("//*[contains(@class, 'newprice')]")
            {
                if var appNewPrice = item.text
                {
                    appNewPrice = appNewPrice.stringByReplacingOccurrencesOfString("Gratis", withString: "0.00")
                    appNewPrice = appNewPrice.stringByReplacingOccurrencesOfString("€", withString: "")
                    appNewPrice = appNewPrice.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    foundApps[i].discountedPrice = appNewPrice
                    i++
                }
            }
            
            // Discount percentage
            for app in foundApps
            {
                guard let oldPrice = app.undiscountedPrice, let newPrice = app.discountedPrice else
                {
                    continue
                }
                
                guard let p1 = Double(oldPrice), p2 = Double(newPrice) else
                {
                    continue
                }
                
                guard !p1.isZero else
                {
                    continue
                }
                
                let percentage = (1 - p2 / p1) * 100
                let priceDelta = p1 - p2
                
                app.discountPercentage = String(format: "%.0f", percentage)
                app.discountedPriceDelta = String(format: "%.2f", priceDelta)
            }
        }
        
        //
        
        var ids: [String] = []
        ids = foundApps.map { item in
            
            if let appId = item.appId
            {
                return appId
            }
            
            fatalError("No app id found")
        }
        
        let searchQuery = String(format: "https://itunes.apple.com/lookup?id=%@", ids.joinWithSeparator(","))
        
        guard let url = NSURL(string: searchQuery) else
        {
            return foundApps
        }
        
        guard let data = NSData(contentsOfURL: url) else
        {
            return foundApps
        }
        
        let json = JSON(data: data)
        
        guard let items = json["results"].array else
        {
            return foundApps
        }
        
        for item in items
        {
            let appId = item["trackId"].stringValue
            guard let app = appById(appId, appsToIterate: foundApps) else
            {
                continue
            }
            
            if let genre = item["primaryGenreName"].string
            {
                app.genre = genre
            }
            
            // Further enrichment
        }
        
        return foundApps
    }
    
    // MARK: - Helper -
    
    /// Looks for an app in app list by the given app id
    ///
    /// - parameter appID: App id
    /// - parameter appsToIterate: List of RTApp objects to browse through
    /// - returns found RTApp object
    private func appById(appId: String, appsToIterate: [RTApp]) -> RTApp?
    {
        for app in appsToIterate
        {
            guard let currentId = app.appId else
            {
                continue
            }
            
            if currentId == appId
            {
                return app
            }
        }
        
        return nil
    }
    
    /// Gets the parameterized string for the data source url
    ///
    /// Returns Parameterized string for the data source url
    private func getTickerHtml() -> String?
    {
        var urlString = dataSourceTextField.stringValue
        
        if !itemLimitTextField.stringValue.isEmpty
        {
            urlString += "&limit=\(itemLimitTextField.stringValue)"
        }
        
        guard let url = NSURL(string: urlString) else
        {
            return nil
        }
        
        do
        {
            return try NSString(contentsOfURL: url, encoding: NSUTF8StringEncoding) as String
        }
            
        catch
        {
            let alert               = NSAlert()
            alert.messageText       = "An error occured"
            alert.informativeText   = "Please check your settings"
            alert.alertStyle        = NSAlertStyle.CriticalAlertStyle
            alert.addButtonWithTitle("Ok")
            alert.runModal()
            
            return nil
        }
    }
}
