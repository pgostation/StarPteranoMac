//
//  NotifySettingsViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/23.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class NotifySettingsViewController: NSViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        
        let view = NotifySettingsView()
        self.view = view
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class NotifySettingsView: NSView {
    let mentionButton = NSButton()
    let favButton = NSButton()
    let boostButton = NSButton()
    let followButton = NSButton()
    
    init() {
        super.init(frame: SettingsWindow.contentRect)
        
        self.addSubview(mentionButton)
        self.addSubview(favButton)
        self.addSubview(boostButton)
        self.addSubview(followButton)
        
        setProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        func setCheckboxStyle(button: NSButton) {
            button.setButtonType(NSButton.ButtonType.switch)
        }
        
        mentionButton.title = I18n.get("BUTTON_MENTION")
        setCheckboxStyle(button: mentionButton)
        
        favButton.title = I18n.get("BUTTON_MENTION")
        setCheckboxStyle(button: favButton)
        
        boostButton.title = I18n.get("BUTTON_MENTION")
        setCheckboxStyle(button: boostButton)
        
        followButton.title = I18n.get("BUTTON_MENTION")
        setCheckboxStyle(button: followButton)
    }
    
    override func layout() {
        let viewWidth = SettingsWindow.contentRect.width - SettingsViewController.width
        
        self.frame = NSRect(x: SettingsViewController.width,
                            y: 0,
                            width: viewWidth,
                            height: SettingsWindow.contentRect.height)
    }
}
