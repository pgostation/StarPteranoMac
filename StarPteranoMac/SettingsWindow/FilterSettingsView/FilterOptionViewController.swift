//
//  FilterOptionViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/19.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class FilterOptionViewController: NSViewController {
    let index: Int
    
    init(index: Int) {
        self.index = index
        
        super.init(nibName: nil, bundle: nil)
        
        let view = FilterOptionView(index: index)
        self.view = view
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidDisappear() {
        guard let view = self.view as? FilterOptionView else { return }
        
        SettingsData.setFilterName(index: index, str: view.nameField.stringValue)
        
        SettingsData.setFilterLocalNotification(index: index, isOn: view.localNotificationButton.state == .on)
        
        SettingsData.setFilterPushNotification(index: index, isOn: view.pushNotificationButton.state == .on)
    }
}

final class FilterOptionView: NSView {
    let nameField = NSTextField()
    let localNotificationButton = NSButton()
    let pushNotificationButton = NSButton()
    
    init(index: Int) {
        super.init(frame: FilterSettingsView.contentRect)
        
        self.addSubview(nameField)
        self.addSubview(localNotificationButton)
        self.addSubview(pushNotificationButton)
        
        setProperties(index: index)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties(index: Int) {
        nameField.stringValue = SettingsData.filterName(index: index) ?? ""
        nameField.placeholderString = I18n.get("PLACEHOLDER_NAME")
        
        localNotificationButton.title = I18n.get("BUTTON_LOCAL_NOTIFICATION")
        localNotificationButton.setButtonType(.switch)
        localNotificationButton.state = SettingsData.filterLocalNotification(index: index) ? .on : .off
        
        pushNotificationButton.title = I18n.get("BUTTON_PUSH_NOTIFICATION")
        pushNotificationButton.setButtonType(.switch)
        pushNotificationButton.state = SettingsData.filterPushNotification(index: index) ? .on : .off
        pushNotificationButton.isEnabled = (SettingsData.deviceToken != nil)
    }
    
    override func layout() {
        nameField.frame = NSRect(x: 100,
                                 y: self.frame.height - 55,
                                 width: 200,
                                 height: 25)
        
        localNotificationButton.frame = NSRect(x: 100,
                                 y: self.frame.height - 100,
                                 width: 200,
                                 height: 20)
        
        pushNotificationButton.frame = NSRect(x: 100,
                                              y: self.frame.height - 150,
                                              width: 200,
                                              height: 20)
    }
}
