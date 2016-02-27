//
//  GeneratedContentViewController.swift
//  ReduTipster
//
//  Created by Tobias Scholze on 23/01/16.
//  Copyright © 2016 Tobias Scholze. All rights reserved.
//

import Cocoa

class GeneratedContentViewController: NSViewController
{
    // MARK: - Properties
    
    /// Contains the content of the text view
    var content: String?
    
    // MARK: - Outlets -
    
    @IBOutlet var textView: NSTextView!
    
    // MARK: Overriding NSViewController methods
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        title = "Generated article template"
        
        guard let _content = content else
        {
            return
        }
        
        textView.textContainer?.textView?.string = _content
    }
}
