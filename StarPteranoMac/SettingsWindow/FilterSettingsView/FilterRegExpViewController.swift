//
//  FilterRegExpViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/17.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class FilterRegExpViewController: NSViewController {
    let index: Int
    
    init(index: Int) {
        self.index = index
        
        super.init(nibName: nil, bundle: nil)
        
        let view = FilterRegExpView(index: index)
        self.view = view
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidDisappear() {
        guard let view = self.view as? FilterRegExpView else { return }
        
        SettingsData.setFilterRegExp(index: index, str: view.textView.stringValue)
    }
}

final class FilterRegExpView: NSView {
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
        helpLabel.stringValue = I18n.get("FILTER_HELP_REGEXP")
        helpLabel.isEditable = false
        helpLabel.isBordered = false
        helpLabel.isSelectable = false
        helpLabel.drawsBackground = false
        helpLabel.maximumNumberOfLines = 2
        
        textView.stringValue = SettingsData.filterRegExp(index: index)?.pattern ?? ""
    }
    
    override func layout() {
        helpLabel.frame = NSRect(x: 10,
                                 y: self.frame.height - 25,
                                 width: self.frame.width - 20,
                                 height: 20)
        
        textView.frame = NSRect(x: 10,
                                y: self.frame.height - 60,
                                width: self.frame.width - 20,
                                height: 30)
    }
}
