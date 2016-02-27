//
//  NSColor+hex.swift
//  ReduTipster
//
//  Created by Tobias Scholze on 23/01/16.
//  Copyright © 2016 Tobias Scholze. All rights reserved.
//

import Foundation
import Cocoa

extension NSColor
{
    /// Uses a hex string like 0xFF0000 to get an UIColor
    ///
    /// - parameter hex: Color in hex code like 0xFF00FF
    convenience init(hex: Int)
    {
        let components = (
            r: CGFloat((hex >> 16) & 0xff) / 0xff,
            g: CGFloat((hex >> 08) & 0xff) / 0xff,
            b: CGFloat((hex >> 00) & 0xff) / 0xff
        )
        
        self.init(red: components.r, green: components.g, blue: components.b, alpha: 1)
    }
}
