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
        
        view.licenseButton.target = self
        view.licenseButton.action = #selector(licenseAction)
        view.storageCacheButton.action = #selector(storageCacheAction(_:))
        view.storageCacheButton.target = self
        view.ramCacheStepper.action = #selector(ramCacheAction(_:))
        view.ramCacheStepper.target = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func licenseAction() {
        guard let path = Bundle.main.path(forResource: "License", ofType: "text") else { return }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return }
        guard let licenseStr = String(data: data, encoding: String.Encoding.utf8) else { return }
        
        let textView = NSTextView()
        textView.string = licenseStr
        textView.frame = NSRect(x: 0, y: 0, width: 600, height: 500)
        textView.sizeToFit()
        
        let scrollView = NSScrollView()
        scrollView.frame = NSRect(x: 0, y: 0, width: 600, height: 500)
        scrollView.documentView = textView
        
        Dialog.showWithView(message: "", okName: "OK", view: scrollView)
    }
    
    @objc func storageCacheAction(_ sender: NSButton) {
        SettingsData.useStorageCache = (sender.state == .on)
    }
    
    @objc func ramCacheAction(_ sender: NSButton) {
        SettingsData.ramCacheCount = min(999, max(1, sender.integerValue))
        
        guard let view = self.view as? DetailSettingsView else { return }
        view.setProperties()
        view.needsLayout = true
    }
    
}

final class DetailSettingsView: NSView {
    let licenseButton = NSButton()
    let storageCacheButton = NSButton()
    let ramCacheStepper = NSStepper()
    let ramCacheLabel = CATextLayer()
    
    init() {
        super.init(frame: SettingsWindow.contentRect)
        
        self.wantsLayer = true
        
        self.addSubview(licenseButton)
        self.addSubview(storageCacheButton)
        self.addSubview(ramCacheStepper)
        self.layer?.addSublayer(ramCacheLabel)
        
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
        
        licenseButton.title = I18n.get("BUTTON_LICENSE")
        setButtonStyle(button: licenseButton)
        
        storageCacheButton.title = I18n.get("BUTTON_USE_STORAGE_CACHE")
        setCheckboxStyle(button: storageCacheButton)
        storageCacheButton.state = SettingsData.useStorageCache ? .on : .off
        
        ramCacheStepper.minValue = 60
        ramCacheStepper.maxValue = 999
        ramCacheStepper.increment = 10
        ramCacheStepper.integerValue = SettingsData.ramCacheCount
        
        ramCacheLabel.string = I18n.get("LABEL_RAMCACHECOUNT") + ": " + "\(SettingsData.ramCacheCount)"
        ramCacheLabel.fontSize = 12
        ramCacheLabel.contentsScale = (NSScreen.main?.backingScaleFactor)!
        ramCacheLabel.foregroundColor = NSColor.black.cgColor
    }
    
    override func layout() {
        let viewWidth = SettingsWindow.contentRect.width - SettingsViewController.width
        
        self.frame = NSRect(x: SettingsViewController.width,
                            y: 0,
                            width: viewWidth,
                            height: SettingsWindow.contentRect.height)
        
        storageCacheButton.frame = NSRect(x: 30,
                                          y: SettingsWindow.contentRect.height - 50,
                                          width: 200,
                                          height: 20)
        
        let ramCacheLabelSize = ramCacheLabel.preferredFrameSize()
        ramCacheLabel.frame = NSRect(x: 30,
                                     y: SettingsWindow.contentRect.height - 100,
                                     width: ramCacheLabelSize.width,
                                     height: 20)
        
        ramCacheStepper.frame = NSRect(x: ramCacheLabel.frame.maxX + 5,
                                       y: SettingsWindow.contentRect.height - 100,
                                       width: 20,
                                       height: 30)
        
        licenseButton.frame = NSRect(x: 30,
                                     y: SettingsWindow.contentRect.height - 150,
                                     width: 250,
                                     height: 30)
    }
}

