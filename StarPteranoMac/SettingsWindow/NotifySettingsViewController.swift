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
        
        view.mentionButton.action = #selector(mentionAction(_:))
        view.mentionButton.target = self
        view.favButton.action = #selector(favAction(_:))
        view.favButton.target = self
        view.boostButton.action = #selector(boostAction(_:))
        view.boostButton.target = self
        view.followButton.action = #selector(followAction(_:))
        view.followButton.target = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func mentionAction(_ sender: NSButton) {
        SettingsData.notifyMentions = (sender.state == .on)
    }
    
    @objc func favAction(_ sender: NSButton) {
        SettingsData.notifyFavorites = (sender.state == .on)
    }
    
    @objc func boostAction(_ sender: NSButton) {
        SettingsData.notifyBoosts = (sender.state == .on)
    }
    
    @objc func followAction(_ sender: NSButton) {
        SettingsData.notifyFollows = (sender.state == .on)
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
        
        mentionButton.title = I18n.get("BUTTON_NOTIFY_MENTION")
        setCheckboxStyle(button: mentionButton)
        mentionButton.state = SettingsData.notifyMentions ? .on : .off
        
        favButton.title = I18n.get("BUTTON_NOTIFY_FAVORITE")
        setCheckboxStyle(button: favButton)
        favButton.state = SettingsData.notifyFavorites ? .on : .off
        
        boostButton.title = I18n.get("BUTTON_NOTIFY_BOOST")
        setCheckboxStyle(button: boostButton)
        boostButton.state = SettingsData.notifyBoosts ? .on : .off
        
        followButton.title = I18n.get("BUTTON_NOTIFY_FOLLOW")
        setCheckboxStyle(button: followButton)
        followButton.state = SettingsData.notifyFollows ? .on : .off
    }
    
    override func layout() {
        let viewWidth = SettingsWindow.contentRect.width - SettingsViewController.width
        
        self.frame = NSRect(x: SettingsViewController.width,
                            y: 0,
                            width: viewWidth,
                            height: SettingsWindow.contentRect.height)
        
        mentionButton.frame = NSRect(x: 30,
                                     y: SettingsWindow.contentRect.height - 50,
                                     width: 200,
                                     height: 20)
        
        favButton.frame = NSRect(x: 30,
                                 y: SettingsWindow.contentRect.height - 100,
                                 width: 200,
                                 height: 20)
        
        boostButton.frame = NSRect(x: 30,
                                   y: SettingsWindow.contentRect.height - 150,
                                   width: 200,
                                   height: 20)
        
        followButton.frame = NSRect(x: 30,
                                    y: SettingsWindow.contentRect.height - 200,
                                    width: 200,
                                    height: 20)
    }
}
