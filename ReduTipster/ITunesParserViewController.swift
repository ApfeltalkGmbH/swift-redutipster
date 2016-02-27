//
//  ITunesParserViewController.swift
//  ReduTipster
//
//  Created by Tobias Scholze on 30.01.16.
//  Copyright © 2016 Tobias Scholze. All rights reserved.
//

import Foundation
import Cocoa
import SwiftyJSON

class ITunesViewController: TableViewController
{
    // MARK: - Constants -
    
    private let appStoreIphoneApiUrl    = "https://itunes.apple.com/de/rss/toppaidapplications/limit=10/json"
    private let appStoreIpadApiUrl      = "https://itunes.apple.com/de/rss/toppaidipadapplications/limit=10/json"
    private let appStoreMacApiUrl       = "https://itunes.apple.com/de/rss/toppaidmacapps/limit=10/json"
    
    // MARK: - Outlets
    
    @IBOutlet var includeIPhoneButton   : NSButton!
    @IBOutlet var includeIPadButton     : NSButton!
    @IBOutlet var includeMacButton      : NSButton!
    
    // MARK: - Overriding TableViewController methods -
    
    override func setupView()
    {
        super.setupView()
        
        let chartSorting = NSSortDescriptor(key: "chartRank", ascending: true)
        tableView.sortDescriptors.append(chartSorting)
    }
    
    
    override func parseDataFromUrl() -> [RTApp]
    {
        // Clear deprecated data
        var foundApps: [RTApp] = []
        
        // Iterate over all selected data sources
        if includeIPhoneButton.state == NSOnState
        {
            foundApps.appendContentsOf(parseITunesFeed(appStoreIphoneApiUrl, platform: RTPlatform.iPhone))
        }
        
        if includeIPadButton.state == NSOnState
        {
            foundApps.appendContentsOf(parseITunesFeed(appStoreIpadApiUrl, platform: RTPlatform.iPad))
            
        }
        
        if includeMacButton.state == NSOnState
        {
            foundApps.appendContentsOf(parseITunesFeed(appStoreMacApiUrl, platform: RTPlatform.Mac))
        }
        
        return foundApps
    }
    
    // MARK: - Helper -
    
    /// Loads and parses the iTunes feed data
    ///
    /// - parameter itunesFeedUrl: Related feed url
    /// - parameter platform: RTPlatform identifier
    /// - returns: A list of found apps
    private func parseITunesFeed(itunesFeedUrl: String, platform: RTPlatform) -> [RTApp]
    {
        var foundApps: [RTApp] = []
        
        guard let url = NSURL(string: itunesFeedUrl) else
        {
            return foundApps
        }
        
        guard let data = NSData(contentsOfURL: url) else
        {
            return foundApps
        }
        
        let json = JSON(data: data)

        if let entries = json["feed"]["entry"].array
        {
            var chartRank: Int = 0
            for entry in entries
            {
                chartRank += 1
                let app = RTApp()
                
                if let appTitle = entry["title"]["label"].string
                {
                    app.title = appTitle
                }
                
                if let appStoreLink = entry["link"]["attributes"]["href"].string
                {
                    app.appStoreLink = appStoreLink
                }
                
                if let appId = entry["id"]["attributes"]["im:id"].string
                {
                    app.appId = appId
                }
                
                if let appIconLink = entry["im:image"][2]["label"].string
                {
                    app.iconLink = appIconLink
                }
                
                if var undiscountedPrice = entry["im:price"]["attributes"]["amount"].string
                {
                    undiscountedPrice = (undiscountedPrice as NSString).substringToIndex(undiscountedPrice.characters.count - 3)
                    app.undiscountedPrice = undiscountedPrice
                }
                
                // Set calculated values
                app.platform    = platform
                app.chartRank   = String(chartRank)
                
                foundApps.append(app)
            }
        }
        
        return foundApps
    }
}
