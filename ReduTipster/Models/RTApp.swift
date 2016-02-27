//
//  RTApp.swift
//  ReduTipster
//
//  Created by Tobias Scholze on 23/01/16.
//  Copyright © 2016 Tobias Scholze. All rights reserved.
//

import Foundation

/// Represents an app with its platform and discount
class RTApp: NSObject
{
    /// iTunes App Store ID
    var appId: String?
    
    /// App title / name
    var title: String?
    
    /// Indicates the platform (iPhone, iPad, Universal)
    var platform: RTPlatform?

    /// Link to the icon
    var iconLink: String?
    
    /// Link to the iTunes App Store
    var appStoreLink: String?
    
    /// New, discounted price
    var discountedPrice: String?
    
    /// Old, not discounted price
    var undiscountedPrice: String?
    
    /// Discsount in percent
    var discountPercentage: String?
    
    /// Price delta between discounted and not
    var discountedPriceDelta: String?
    
    /// iTunes Charts rank
    var chartRank: String?
    
    /// Primary category
    var genre: String?
    
    /// Workaorund attribute for sorting
    var platformStringValue: String?
    {
        return platform?.rawValue
    }
    
    /// Description contains app name and undiscounted proce
    override var description: String
    {
        guard let _title = title, _undiscountedPrice = undiscountedPrice else
        {
            return "Some data is missing for this app"
        }
        
        return String(format:"%@ for just: %@ Euro", _title, _undiscountedPrice)
    }
}
