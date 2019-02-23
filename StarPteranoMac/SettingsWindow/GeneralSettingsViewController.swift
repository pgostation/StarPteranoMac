//
//  GeneralSettingsViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/23.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class GeneralSettingsViewController: NSViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        
        let view = GeneralSettingsView()
        self.view = view
        
        view.protectModeButton.action = #selector(protectModeAction(_:))
        view.protectModeButton.target = self
        view.useStreamingButton.action = #selector(useStreamingAction(_:))
        view.useStreamingButton.target = self
        view.defaultNSFWButton.action = #selector(defaultNSFWAction(_:))
        view.defaultNSFWButton.target = self
        view.clearCacheButton.action = #selector(clearCacheAction)
        view.clearCacheButton.target = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func protectModeAction(_ sender: NSButton) {
        guard let view = view as? GeneralSettingsView else { return }
        
        let protectView = ProtectModeView(y: view.protectModeButton.frame.minY, callback: { mode in
            SettingsData.protectMode = mode
            view.setProperties()
            
            MainWindow.window?.close()
            DispatchQueue.main.async {
                MainWindow.show()
            }
        })
        view.addSubview(protectView)
        
        protectView.frame.origin.x = sender.frame.minX
    }
    
    @objc func useStreamingAction(_ sender: NSButton) {
        SettingsData.isStreamingMode = (sender.state == .on)
    }
    
    @objc func defaultNSFWAction(_ sender: NSButton) {
        SettingsData.defaultNSFW = (sender.state == .on)
        
        MainWindow.window?.close()
        DispatchQueue.main.async {
            MainWindow.show()
        }
    }
    
    @objc func clearCacheAction() {
        //####
    }
}

final class GeneralSettingsView: NSView {
    let protectModeButton = NSButton()
    let useStreamingButton = NSButton()
    let defaultNSFWButton = NSButton()
    let clearCacheButton = NSButton()
    
    init() {
        super.init(frame: SettingsWindow.contentRect)
        
        self.addSubview(protectModeButton)
        self.addSubview(useStreamingButton)
        self.addSubview(defaultNSFWButton)
        self.addSubview(clearCacheButton)
        
        setProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setProperties() {
        func setButtonStyle(button: NSButton) {
            button.bezelStyle = .regularSquare
        }
        func setCheckboxStyle(button: NSButton) {
            button.setButtonType(NSButton.ButtonType.switch)
        }
        
        var titleStr = I18n.get("SETTINGS_PROTECTMODE") + ": "
        switch SettingsData.protectMode {
        case .publicMode:
            titleStr += I18n.get("PROTECTMODE_PUBLIC")
        case .unlisted:
            titleStr += I18n.get("PROTECTMODE_UNLISTED")
        case .privateMode:
            titleStr += I18n.get("PROTECTMODE_PRIVATE")
        case .direct:
            titleStr += I18n.get("PROTECTMODE_DIRECT")
        }
        protectModeButton.title = titleStr
        setButtonStyle(button: protectModeButton)
        
        useStreamingButton.title = I18n.get("BUTTON_USESTREAMING")
        setCheckboxStyle(button: useStreamingButton)
        useStreamingButton.state = SettingsData.isStreamingMode ? .on : .off
        
        defaultNSFWButton.title = I18n.get("BUTTON_DEFAULT_NSFW")
        setCheckboxStyle(button: defaultNSFWButton)
        defaultNSFWButton.state = SettingsData.defaultNSFW ? .on : .off
        
        clearCacheButton.title = I18n.get("BUTTON_CLEARCACHE")
        setButtonStyle(button: clearCacheButton)
    }
    
    override func layout() {
        let viewWidth = SettingsWindow.contentRect.width - SettingsViewController.width
        
        self.frame = NSRect(x: SettingsViewController.width,
                            y: 0,
                            width: viewWidth,
                            height: SettingsWindow.contentRect.height)
        
        protectModeButton.frame = NSRect(x: 30,
                                         y: SettingsWindow.contentRect.height - 50,
                                         width: 200,
                                         height: 35)
        
        useStreamingButton.frame = NSRect(x: 30,
                                          y: SettingsWindow.contentRect.height - 90,
                                          width: 200,
                                          height: 20)
        
        defaultNSFWButton.frame = NSRect(x: 30,
                                         y: SettingsWindow.contentRect.height - 150,
                                         width: 200,
                                         height: 20)
        
        clearCacheButton.frame = NSRect(x: 30,
                                        y: SettingsWindow.contentRect.height - 200,
                                        width: 200,
                                        height: 35)
    }
}
