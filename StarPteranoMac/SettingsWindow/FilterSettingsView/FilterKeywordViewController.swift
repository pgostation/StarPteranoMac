//
//  FilterKeywordViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/17.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class FilterKeywordViewController: NSViewController {
    let index: Int
    
    init(index: Int) {
        self.index = index
        
        super.init(nibName: nil, bundle: nil)
        
        let view = FilterKeywordView(index: index)
        self.view = view
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidDisappear() {
        guard let view = self.view as? FilterKeywordView else { return }
        
        SettingsData.setFilterKeyword(index: index, str: view.textView.stringValue)
    }
}

final class FilterKeywordView: NSView {
    let helpLabel = NSTextField()
    let textView = NSTextField()
    
    init(index: Int) {
        super.init(frame: FilterSettingsView.contentRect)
        
        self.addSubview(helpLabel)
        self.addSubview(textView)
        
        setProperties(index: index)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties(index: Int) {
        helpLabel.stringValue = I18n.get("FILTER_HELP_KEYWORD")
        helpLabel.isEditable = false
        helpLabel.isBordered = false
        helpLabel.isSelectable = false
        helpLabel.drawsBackground = false
        helpLabel.maximumNumberOfLines = 2
        
        textView.stringValue = SettingsData.filterKeywords(index: index).joined(separator: " ")
        textView.maximumNumberOfLines = 20
    }
    
    override func layout() {
        helpLabel.frame = NSRect(x: 10,
                                 y: self.frame.height - 55,
                                 width: self.frame.width - 20,
                                 height: 50)
        
        textView.frame = NSRect(x: 10,
                                y: 25,
                                width: self.frame.width - 20,
                                height: self.frame.height - 85)
    }
}
