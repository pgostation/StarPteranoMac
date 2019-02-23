//
//  SearchSettingsViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/23.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class SearchSettingsViewController: NSViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        
        let view = SearchSettingsView()
        self.view = view
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SearchSettingsView: NSView {
    init() {
        super.init(frame: SettingsWindow.contentRect)
        
        setProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
    }
    
    override func layout() {
        let viewWidth = SettingsWindow.contentRect.width - SettingsViewController.width
        
        self.frame = NSRect(x: SettingsViewController.width,
                            y: 0,
                            width: viewWidth,
                            height: SettingsWindow.contentRect.height)
    }
}
