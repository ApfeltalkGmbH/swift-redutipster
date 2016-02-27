//
//  Array+randomItem.swift
//  ReduTipster
//
//  Created by Tobias Scholze on 30.01.16.
//  Copyright © 2016 Tobias Scholze. All rights reserved.
//

import Foundation

extension Array
{
    /// Returns a random item of the array
    /// Credits: http://stackoverflow.com/questions/24003191/pick-a-random-element-from-an-array
    func randomItem() -> Element
    {
        let index = Int(arc4random_uniform(UInt32(self.count)))
        return self[index]
    }
}
