//
//  NotifySettingsViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/23.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class NotifySettingsViewController: NSViewController, NSTextFieldDelegate {
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
        
        view.pushMentionButton.action = #selector(pushMentionAction(_:))
        view.pushMentionButton.target = self
        view.pushFavButton.action = #selector(pushFavAction(_:))
        view.pushFavButton.target = self
        view.pushBoostButton.action = #selector(pushBoostAction(_:))
        view.pushBoostButton.target = self
        view.pushFollowButton.action = #selector(pushFollowAction(_:))
        view.pushFollowButton.target = self
        
        view.deviceTokenField.delegate = self
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
    
    @objc func pushMentionAction(_ sender: NSButton) {
        SettingsData.pushNotifyMentions = (sender.state == .on)
    }
    
    @objc func pushFavAction(_ sender: NSButton) {
        SettingsData.pushNotifyFavorites = (sender.state == .on)
    }
    
    @objc func pushBoostAction(_ sender: NSButton) {
        SettingsData.pushNotifyBoosts = (sender.state == .on)
    }
    
    @objc func pushFollowAction(_ sender: NSButton) {
        SettingsData.pushNotifyFollows = (sender.state == .on)
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let view = self.view as? NotifySettingsView else { return }
        
        if view.deviceTokenField.stringValue != "" {
            SettingsData.deviceToken = view.deviceTokenField.stringValue
        } else {
            SettingsData.deviceToken = nil
        }
        
        view.refresh()
    }
}

final class NotifySettingsView: NSView {
    let mentionButton = NSButton()
    let favButton = NSButton()
    let boostButton = NSButton()
    let followButton = NSButton()
    let pushMentionButton = NSButton()
    let pushFavButton = NSButton()
    let pushBoostButton = NSButton()
    let pushFollowButton = NSButton()
    let deviceTokenField = NSTextField()
    
    init() {
        super.init(frame: SettingsWindow.contentRect)
        
        self.addSubview(mentionButton)
        self.addSubview(favButton)
        self.addSubview(boostButton)
        self.addSubview(followButton)
        self.addSubview(pushMentionButton)
        self.addSubview(pushFavButton)
        self.addSubview(pushBoostButton)
        self.addSubview(pushFollowButton)
        self.addSubview(deviceTokenField)
        
        setProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func refresh() {
        setProperties()
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
        
        pushMentionButton.title = I18n.get("BUTTON_PUSH_NOTIFY_MENTION")
        setCheckboxStyle(button: pushMentionButton)
        pushMentionButton.state = SettingsData.pushNotifyMentions ? .on : .off
        
        pushFavButton.title = I18n.get("BUTTON_PUSH_NOTIFY_FAVORITE")
        setCheckboxStyle(button: pushFavButton)
        pushFavButton.state = SettingsData.pushNotifyFavorites ? .on : .off
        
        pushBoostButton.title = I18n.get("BUTTON_PUSH_NOTIFY_BOOST")
        setCheckboxStyle(button: pushBoostButton)
        pushBoostButton.state = SettingsData.pushNotifyBoosts ? .on : .off
        
        pushFollowButton.title = I18n.get("BUTTON_PUSH_NOTIFY_FOLLOW")
        setCheckboxStyle(button: pushFollowButton)
        pushFollowButton.state = SettingsData.pushNotifyFollows ? .on : .off
        
        pushMentionButton.isEnabled = (SettingsData.deviceToken != nil)
        pushFavButton.isEnabled = (SettingsData.deviceToken != nil)
        pushBoostButton.isEnabled = (SettingsData.deviceToken != nil)
        pushFollowButton.isEnabled = (SettingsData.deviceToken != nil)
        
        deviceTokenField.stringValue = SettingsData.deviceToken ?? ""
        deviceTokenField.font = NSFont.systemFont(ofSize: 10)
        deviceTokenField.placeholderString = I18n.get("PLACEHOLDER_DEVICETOKEN")
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
        
        pushMentionButton.frame = NSRect(x: 230,
                                     y: SettingsWindow.contentRect.height - 50,
                                     width: 250,
                                     height: 20)
        
        pushFavButton.frame = NSRect(x: 230,
                                 y: SettingsWindow.contentRect.height - 100,
                                 width: 250,
                                 height: 20)
        
        pushBoostButton.frame = NSRect(x: 230,
                                   y: SettingsWindow.contentRect.height - 150,
                                   width: 250,
                                   height: 20)
        
        pushFollowButton.frame = NSRect(x: 230,
                                    y: SettingsWindow.contentRect.height - 200,
                                    width: 250,
                                    height: 20)
        
        deviceTokenField.frame = NSRect(x: 30,
                                        y: SettingsWindow.contentRect.height - 250,
                                        width: 450,
                                        height: 30)
    }
}
