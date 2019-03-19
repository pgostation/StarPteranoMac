//
//  FilterAccountViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/17.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class FilterAccountViewController: NSViewController {
    let index: Int
    
    init(index: Int) {
        self.index = index
        
        super.init(nibName: nil, bundle: nil)
        
        let view = FilterAccountView(index: index)
        self.view = view
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidDisappear() {
        guard let view = self.view as? FilterAccountView else { return }
        
        SettingsData.setFilterAccount(index: index, str: view.textView.stringValue)
    }
}

final class FilterAccountView: NSView {
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
        helpLabel.stringValue = I18n.get("FILTER_HELP_ACCOUNT")
        helpLabel.isEditable = false
        helpLabel.isBordered = false
        helpLabel.isSelectable = false
        helpLabel.drawsBackground = false
        
        textView.stringValue = SettingsData.filterAccounts(index: index).joined(separator: " ")
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
