//
//  DetailSettingsViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/23.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class DetailSettingsViewController: NSViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        
        let view = DetailSettingsView()
        self.view = view
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class DetailSettingsView: NSView {
    let licenseButton = NSButton()
    
    init() {
        super.init(frame: SettingsWindow.contentRect)
        
        self.addSubview(licenseButton)
        
        setProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        func setButtonStyle(button: NSButton) {
            button.bezelStyle = .regularSquare
        }
        
        licenseButton.title = I18n.get("BUTTON_LICENSE")
        setButtonStyle(button: licenseButton)
    }
    
    override func layout() {
        let viewWidth = SettingsWindow.contentRect.width - SettingsViewController.width
        
        self.frame = NSRect(x: SettingsViewController.width,
                            y: 0,
                            width: viewWidth,
                            height: SettingsWindow.contentRect.height)
    }
}

