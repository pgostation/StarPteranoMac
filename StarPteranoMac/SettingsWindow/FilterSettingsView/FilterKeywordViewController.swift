//
//  FilterKeywordViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/17.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class FilterKeywordViewController: NSViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        
        let view = FilterKeywordView()
        self.view = view
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidDisappear() {
        guard let view = self.view as? FilterKeywordView else { return }
        
        SettingsData.setFilterKeyword(str: view.textView.stringValue)
    }
}

final class FilterKeywordView: NSView {
    let helpLabel = NSTextField()
    let textView = NSTextField()
    
    init() {
        super.init(frame: FilterSettingsView.contentRect)
        
        self.addSubview(helpLabel)
        self.addSubview(textView)
        
        setProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        helpLabel.stringValue = I18n.get("FILTER_HELP_KEYWORD")
        helpLabel.isEditable = false
        helpLabel.isBordered = false
        helpLabel.isSelectable = false
        helpLabel.drawsBackground = false
        helpLabel.maximumNumberOfLines = 2
        
        textView.stringValue = SettingsData.filterKeywords.joined(separator: " ")
        textView.maximumNumberOfLines = 20
    }
    
    override func layout() {
        helpLabel.frame = NSRect(x: 10,
                                 y: self.frame.height - 55,
                                 width: self.frame.width - 20,
                                 height: 50)
        
        textView.frame = NSRect(x: 10,
                                y: 5,
                                width: self.frame.width - 20,
                                height: self.frame.height - 65)
    }
}
