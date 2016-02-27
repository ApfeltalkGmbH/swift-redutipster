//
//  TableViewController.swift
//  ReduTipster
//
//  Created by Tobias Scholze on 30.01.16.
//  Copyright © 2016 Tobias Scholze. All rights reserved.
//

import Foundation
import Cocoa
import Mustache


/// Generic TableViewController with RT specific attributes
/// subclass it for tableviews that contains a list of apps.
class TableViewController: NSViewController
{
    /// Green which indicats a positive trend
    private let RTGreen = NSColor(hex: 0x00b200)
    
    /// Gray which indicate neutral or disabled values
    private let RTGray = NSColor.lightGrayColor()
    
    /// NSUserDefaults identifier for affilate code string value
    private let userDefaultsAffilateCodeIdentifier = "rt-affiliate-code"
    
    /// NSUserDefaults identifier for shuffle item bool value
    private let userDefaultsShuffleItemsIdentifier = "rt-shuffle-items"
    
    /// NSUserDefaults identifier for uses app box template bool value
    private let userDefaultsUseAppBoxesIdentifier = "rt-use-app-boxes"
    
    /// NSUserDefaults identifier for customized affilate code string value
    private let userDefaultsUseOwnAffiliateCodeIdentifier = "rt-own-affilate code"
    
    /// NSUserDefaults identifier for adding a header template bool value
    private let userDefaultsAddHeaderIdentifier = "rt-add-header"

    /// NSUserDefaults identifier for adding a footer template bool value
    private let userDefaultsAddFooterIdentifier = "rt-add-footer"
    
    /// User defaults instance of the application
    internal let userDefaults = NSUserDefaults.standardUserDefaults()
    
    /// List of all apps
    internal var apps: [RTApp] = []
    {
        didSet
        {
            generateArticleButton.enabled   = apps.count > 0
            apps                            = sortAppsByTableViewSorting(apps)
            tableView.reloadData()
        }
    }
    
    // MARK: - Outlets -
    
    @IBOutlet var tableView                 : NSTableView!
    @IBOutlet var generateArticleButton     : NSButton!
    @IBOutlet var affiliateCodeTextField    : NSTextField!
    @IBOutlet var shuffleItemsButton        : NSButton?
    @IBOutlet var useAppBoxesButton         : NSButton!
    @IBOutlet var useOwnAffiliateCodeButton : NSButton!
    @IBOutlet var addHeaderButton           : NSButton!
    @IBOutlet var addFooterButton           : NSButton!
    
    // MARK: - Overriding UIViewController methods
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.title                          = "ReduTipster"
        tableView.selectionHighlightStyle   = NSTableViewSelectionHighlightStyle.SourceList
        tableView.backgroundColor           = NSColor.whiteColor()
        
        apps = parseDataFromUrl()
    }
    
    override func viewWillAppear()
    {
        super.viewWillAppear()
        
        setupView()
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "showGeneratedContent"
        {
            let vc = segue.destinationController as! GeneratedContentViewController
            vc.content = sender as? String
        }
    }
    
    // MARK: - Overrideable TableViewController methods -
    
    /// Sets up the view with persistet data, ui styling, etc.
    /// Override this method with a super call to setup the
    /// subclassed view.
    ///
    /// Method will be called in super.viewWillAppear().
    /// Suiteable to persist the data again would be 
    /// `willNavigateToGeneratedContentView()`
    internal func setupView()
    {
        if let affiliateCode = userDefaults.stringForKey(userDefaultsAffilateCodeIdentifier)
        {
            affiliateCodeTextField.stringValue = affiliateCode
        }
        
        shuffleItemsButton?.state           = userDefaults.boolForKey(userDefaultsShuffleItemsIdentifier) ? NSOnState : NSOffState
        useAppBoxesButton?.state            = userDefaults.boolForKey(userDefaultsUseAppBoxesIdentifier) ? NSOnState : NSOffState
        useOwnAffiliateCodeButton.state     = userDefaults.boolForKey(userDefaultsUseOwnAffiliateCodeIdentifier) ? NSOnState : NSOffState
        addHeaderButton.state               = userDefaults.boolForKey(userDefaultsAddHeaderIdentifier) ? NSOnState : NSOffState
        addFooterButton.state               = userDefaults.boolForKey(userDefaultsAddFooterIdentifier) ? NSOnState : NSOffState
    }
    
    /// Get called before navigating to the generated content view.
    /// Persists data for the UI elements.
    /// Override this method with a super call to do custom things
    ///
    /// Method will be default called if clicking the `generate` button 
    internal func willNavigateToGeneratedContentView()
    {
        userDefaults.setObject(affiliateCodeTextField.stringValue, forKey: userDefaultsAffilateCodeIdentifier)
        userDefaults.setBool(shuffleItemsButton?.state == NSOnState, forKey: userDefaultsShuffleItemsIdentifier)
        userDefaults.setBool(useAppBoxesButton?.state == NSOnState, forKey: userDefaultsUseAppBoxesIdentifier)
        userDefaults.setBool(useOwnAffiliateCodeButton?.state == NSOnState, forKey: userDefaultsUseOwnAffiliateCodeIdentifier)
        userDefaults.setBool(addHeaderButton?.state == NSOnState, forKey: userDefaultsAddHeaderIdentifier)
        userDefaults.setBool(addFooterButton?.state == NSOnState, forKey: userDefaultsAddFooterIdentifier)
    }
    
    // MARK: - Actions -
    
    /// Generates an article accrording to the settings made
    /// Generats an empty string if no data is selected
    ///
    /// - parameter sender: AnyObject given by the UI
    @IBAction func generateArticleClicked(sender: AnyObject)
    {
        let indexes = tableView.selectedRowIndexes
        var selectedApps: [RTApp] = []
        
        if indexes.count == 0
        {
            selectedApps = apps
        }
            
        else
        {
            for index in indexes
            {
                selectedApps.append(apps[index])
            }
        }
        
        selectedApps = sortAppsByTableViewSorting(selectedApps)
        
        if let _shuffleItemsButton = shuffleItemsButton
        {
            if _shuffleItemsButton.state == NSOnState
            {
                selectedApps.sortInPlace { (_,_) in arc4random() < arc4random() }
            }
        }
        
        var articleContent = ""
        
        // Header
        if addHeaderButton.state == NSOnState
        {
            if appsContainsDiscountedPrice(selectedApps)
            {
                articleContent += renderTemplateHeaderWithDiscountedPrice(selectedApps)
            }
            
            else
            {
                articleContent += renderTemplateHeaderNeutral(selectedApps)
            }
        }
        
        // App list
        var listContent = ""
        for app in selectedApps
        {
            if useAppBoxesButton.state == NSOnState
            {
                if appsContainsDiscountedPrice(selectedApps)
                {
                    listContent += renderTemplateAppBoxWithDiscountedPrice(app)
                }
                    
                else
                {
                    listContent += renderTemplateAppBox(app)
                }
            }
            
            else
            {
                if appsContainsDiscountedPrice(selectedApps)
                {
                    listContent += renderTemplateListItemWithDiscountedPrice(app)
                }
                    
                else
                {
                    listContent += renderTemplateListItem(app)
                }
            }
        }
        
        let containerData       = ["list" : listContent]
        let containerTemplate   = try! Template(named: "article-container")
        let containerContent    = try! containerTemplate.render(Box(containerData))
        
        articleContent += containerContent
        
        // Footer
        if addFooterButton.state == NSOnState
        {
            let footerTemplate  = try! Template(named: "article-footer")
            let footerContent   = try! footerTemplate.render()
            
            articleContent += footerContent
        }
        
        willNavigateToGeneratedContentView()
        performSegueWithIdentifier("showGeneratedContent", sender: articleContent)
    }
    
    @IBAction func refreshPressed(sender: AnyObject)
    {
        apps = parseDataFromUrl()
    }
    
    // MARK: - Helper -
    
    /// Returns true if the given list of apps contains a discounted price
    /// Only the first item will be checked
    ///
    /// - parameter appsToCheck: List of RTApp objects
    /// - returns: true of the first app contains a discounted price
    private func appsContainsDiscountedPrice(appsToCheck: [RTApp]) -> Bool
    {
        if  let firstItem = appsToCheck.first
        {
            // If discounted price is available
            return  firstItem.discountedPrice != nil
        }
        
        return false
    }
    
    /// Renders template "app-list-item".
    ///
    /// - parameter app: RTApp to use as data source
    /// - returns: Rendered content string
    func renderTemplateListItem(app: RTApp) -> String
    {
        let template = try! Template(named: "app-list-item")
        let itemData = ["link": app.appStoreLink!, "title": app.title!, "undiscountedPrice" : formatPrice(app.undiscountedPrice!)]
        
        return try! template.render(Box(itemData))
    }
    
    /// Renders template "app-list-item-advanced".
    ///
    /// - parameter app: RTApp to use as data source
    /// - returns: Rendered content string
    func renderTemplateListItemWithDiscountedPrice(app: RTApp) -> String
    {
        let template = try! Template(named: "app-list-item-advanced")
        let itemData = ["link": app.appStoreLink!, "title": app.title!, "discountedPrice" : formatPrice(app.discountedPrice!), "undiscountedPrice" : formatPrice(app.undiscountedPrice!)]
        
        return try! template.render(Box(itemData))
    }
    
    /// Renders template "app-box-list-item-advanced".
    ///
    /// - parameter app: RTApp to use as data source
    /// - returns: Rendered content string
    private func renderTemplateAppBoxWithDiscountedPrice(app: RTApp) -> String
    {
        let template = try! Template(named: "app-box-list-item-advanced")
        let itemData = ["link": app.appStoreLink!, "title": app.title!, "discountedPrice" : formatPrice(app.discountedPrice!), "undiscountedPrice" : formatPrice(app.undiscountedPrice!), "appId" : app.appId!]
        
        return try! template.render(Box(itemData))
    }
   
    /// Renders template "app-box-list-item".
    ///
    /// - parameter app: RTApp to use as data source
    /// - returns: Rendered content string
    private func renderTemplateAppBox(app: RTApp) -> String
    {
        let template = try! Template(named: "app-box-list-item")
        let itemData = ["link": app.appStoreLink!, "title": app.title!, "undiscountedPrice" : formatPrice(app.undiscountedPrice!), "appId" : app.appId!]
        
        return try! template.render(Box(itemData))
    }
    
    /// Renders template "article-header".
    ///
    /// - parameter appsToRender: List of RTApp objects to use as data source
    /// - returns: Rendered content string
    private func renderTemplateHeaderNeutral(appsToRender: [RTApp]) -> String
    {
        guard !appsToRender.isEmpty else
        {
            return ""
        }
        
        let randomApp = appsToRender.randomItem()
        if let appTitle = randomApp.title,
            let appStoreLink = randomApp.appStoreLink,
            let appPrice = randomApp.undiscountedPrice,
            let appPlatform = randomApp.platformStringValue
        {
            let headerData = ["title" : appTitle, "link" : appStoreLink, "price" : formatPrice(appPrice), "platform": appPlatform]
            let headerTemplate = try! Template(named: "article-header")
            let headerContent = try! headerTemplate.render(Box(headerData))
            
            return headerContent
        }
        
        return ""
    }
    
    /// Renders template "article-header-advanced".
    ///
    /// - parameter appsToRender: List of RTApp objects to use as data source
    /// - returns: Rendered content string
    private func renderTemplateHeaderWithDiscountedPrice(appsToRender: [RTApp]) -> String
    {
        guard !appsToRender.isEmpty else
        {
            return ""
        }
        
        guard let highestDiscountedApp = appsToRender.maxElement({ (lhs, rhs) -> Bool in
            
            guard let lhsDelta = lhs.discountedPriceDelta, let rhsDelta = rhs.discountedPriceDelta else
            {
                return false
            }
            
            return Double(lhsDelta)! < Double(rhsDelta)!
        }) else
        {
            return ""
        }
        
        if let randomAppTitle = highestDiscountedApp.title,
            let randomAppStoreLink = highestDiscountedApp.appStoreLink,
            let randomAppPrice = highestDiscountedApp.discountedPrice
        {
            let headerData = ["randomAppTitle" : randomAppTitle, "randomAppStoreLink" : randomAppStoreLink, "randomAppPrice" : formatPrice(randomAppPrice)]
            let headerTemplate = try! Template(named: "article-header-advanced")
            let headerContent = try! headerTemplate.render(Box(headerData))
            
            return headerContent
        }
        
        return ""
    }
    
    /// Sorts apps according to the tableview's sorting descriptors
    ///
    /// - parameter unsortedApps: list of unsorted apps
    /// - return sorted list of apps
    internal func sortAppsByTableViewSorting(unsortedApps: [RTApp]) -> [RTApp]
    {        
        return (unsortedApps as NSArray).sortedArrayUsingDescriptors(tableView.sortDescriptors) as! Array
    }
    
    /// Formats a given price for German human beings
    ///
    /// - parameter price: Computer formatted price as string
    /// - returns German localed, human readable price as string
    internal func formatPrice(var price: String) -> String
    {
        price = price.stringByReplacingOccurrencesOfString(".", withString: ",")
        price += " €"
        
        return price
    }
    
    /// Renders article container template with header, content and footer
    /// Uses templates according to available values
    /// Uses `tableView` as data source
    ///
    /// - returns: Optional string with rendered content
    internal func renderArticleContent() -> String?
    {        
        let indexes = tableView.selectedRowIndexes
        var selectedItems: [RTApp] = []
        
        if indexes.count == 0
        {
            selectedItems = apps
        }
            
        else
        {
            for index in indexes
            {
                selectedItems.append(apps[index])
            }
        }
        
        selectedItems = sortAppsByTableViewSorting(selectedItems)
        
        var articleContent = ""
        
        // Header
        if addHeaderButton.state == NSOnState
        {
            guard let highestDiscountedApp = selectedItems.maxElement({ (a, b) -> Bool in
                return Double(a.discountedPriceDelta!)! < Double(b.discountedPriceDelta!)!
            })
                
                else
            {
                return nil
            }
            
            guard let randomAppTitle = highestDiscountedApp.title,
                let randomAppStoreLink = highestDiscountedApp.appStoreLink,
                let randomAppPrice = highestDiscountedApp.discountedPrice else
            {
                return nil
            }
            
            let headerData = ["randomAppTitle" : randomAppTitle, "randomAppStoreLink" : randomAppStoreLink, "randomAppPrice" : formatPrice(randomAppPrice)]
            let headerTemplate = try! Template(named: "article-header")
            let headerContent = try! headerTemplate.render(Box(headerData))
            
            articleContent += headerContent
        }
        
        
        // App list
        var listContent = ""
        for item in selectedItems
        {
            let templateName = useAppBoxesButton.state == NSOnState ? "app-box-list-item" : "app-list-item"
            let template = try! Template(named: templateName)
            let itemData = ["link": item.appStoreLink!, "title": item.title!, "discountedPrice" : formatPrice(item.discountedPrice!), "undiscountedPrice" : formatPrice(item.undiscountedPrice!), "appId" : item.appId!]
            let itemContent = try! template.render(Box(itemData))
            
            listContent += itemContent
        }
        
        let containerData = ["list" : listContent]
        let containerTemplate = try! Template(named: "article-container")
        let containerContent = try! containerTemplate.render(Box(containerData))
        
        articleContent += containerContent
        
        // Footer
        if addFooterButton.state == NSOnState
        {
            let footerTemplate = try! Template(named: "article-footer")
            let footerContent = try! footerTemplate.render()
            
            articleContent += footerContent
        }
        
        return articleContent
    }
}

// MARK: - NSTableViewDataSource -

extension TableViewController: NSTableViewDataSource
{
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int
    {
        return apps.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let cellView: NSTableCellView = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner: self) as! NSTableCellView
        
        // Reset cell
        cellView.textField?.stringValue = ""
        cellView.textField?.textColor = NSColor.labelColor()
        
        guard let _tableColumn = tableColumn else
        {
            return cellView
        }
        
        switch _tableColumn.identifier
        {
            
        case "chartRank":
            
            if let chartRank = apps[row].chartRank
            {
                cellView.textField!.stringValue = chartRank
            }
                
            else
            {
                cellView.textField!.stringValue = "N/A"
            }
            
        case "title":
            
            if let appTitle = apps[row].title
            {
                cellView.textField!.stringValue = CFXMLCreateStringByUnescapingEntities(nil, appTitle, nil) as String
            }
                
            else
            {
                cellView.textField!.stringValue = "N/A"
            }
            
        case "discountPercentage":
            
            if let discountPercentage = apps[row].discountPercentage
            {
                cellView.textField!.stringValue = discountPercentage
                
                if discountPercentage == "100"
                {
                    cellView.textField!.textColor = RTGreen
                }
            }
                
            else
            {
                cellView.textField!.stringValue = "N/A"
                cellView.textField!.textColor = RTGray
            }
            
        case "undiscountedPrice":
            
            if let undiscountedPrice = apps[row].undiscountedPrice
            {
                cellView.textField!.stringValue = formatPrice(undiscountedPrice)
            }
                
            else
            {
                cellView.textField!.stringValue = "N/A"
                cellView.textField!.textColor = RTGray
            }
            
        case "discountedPrice":
            
            if let discountedPrice = apps[row].discountedPrice
            {
                cellView.textField!.stringValue = formatPrice(discountedPrice)
                
                if discountedPrice == "0.00"
                {
                    cellView.textField!.textColor = RTGreen
                }
            }
                
            else
            {
                cellView.textField!.stringValue = "N/A"
                cellView.textField!.textColor = RTGray
            }
            
        case "platform":
            
            if let platform = apps[row].platform
            {
                cellView.textField!.stringValue = platform.rawValue
            }
                
            else
            {
                cellView.textField!.stringValue = "N/A"
                cellView.textField!.textColor = RTGray
            }
            
        case "appId":
            
            if let appId = apps[row].appId
            {
                cellView.textField!.stringValue = appId
            }
                
            else
            {
                cellView.textField!.stringValue = "N/A"
                cellView.textField!.textColor = RTGray
            }
            
        case "genre":
            
            if let genre = apps[row].genre
            {
                cellView.textField!.stringValue = genre
            }
                
            else
            {
                cellView.textField!.stringValue = "N/A"
                cellView.textField!.textColor = RTGray
            }
            
            
        default:
            NSLog("Column \(_tableColumn.identifier)")
        }
        
        
        return cellView
    }
}

// MARK: - NSTableViewDelegate -

extension TableViewController: NSTableViewDelegate
{
    func tableView(tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor])
    {
        apps = sortAppsByTableViewSorting(apps)
        tableView.reloadData()
    }
}

// MARK: - TableViewDataProviderDelegate -

extension TableViewController: TableViewDataProviderDelegate
{
    /// Implements the TableViewDataProviderDelegate protocol
    /// No super call required
    func parseDataFromUrl() -> [RTApp]
    {
        return []
    }
}

/// Used to describe the data provider for RT table views
protocol TableViewDataProviderDelegate
{
    /// Parses data into a list if RTApp objects
    ///
    /// - returns: Parsed list of RTApp objects
    func parseDataFromUrl() -> [RTApp]
}
