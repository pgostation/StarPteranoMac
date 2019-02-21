//
//  SettingsSelectProtectMode.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/19.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa


final class SettingsSelectProtectMode {
    static func showActionSheet(hostName: String, accessToken: String, callback: @escaping ((SettingsData.ProtectMode)->Void)) {
        for subVC in MainViewController.instance?.subVCList ?? [] {
            if accessToken == subVC.tootVC.accessToken {
                if let view = subVC.view.viewWithTag(123) {
                    view.removeFromSuperview()
                } else {
                    subVC.view.addSubview(ProtectModeView(hostName: hostName, accessToken: accessToken, y: subVC.tootVC.view.frame.minY, callback: callback))
                }
                break
            }
        }
    }
}

final class ProtectModeView: NSView {
    override var tag: Int {
        return 123
    }
    
    private let publicButton = NSButton()
    private let unlistedButton = NSButton()
    private let privateButton = NSButton()
    private let directButton = NSButton()
    private let callback: ((SettingsData.ProtectMode)->Void)
    
    init(hostName: String, accessToken: String, y: CGFloat, callback: @escaping ((SettingsData.ProtectMode)->Void)) {
        self.callback = callback
        
        super.init(frame: NSRect(x: 0, y: y - 160, width: 150, height: 160))
        
        self.addSubview(publicButton)
        self.addSubview(unlistedButton)
        self.addSubview(privateButton)
        self.addSubview(directButton)
        
        setProperties()
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.wantsLayer = true
        self.layer?.backgroundColor = ThemeColor.viewBgColor.cgColor
        
        publicButton.title = I18n.get("PROTECTMODE_PUBLIC")
        publicButton.bezelStyle = .shadowlessSquare
        publicButton.target = self
        publicButton.action = #selector(publicAction)
        
        unlistedButton.title = I18n.get("PROTECTMODE_UNLISTED")
        unlistedButton.bezelStyle = .shadowlessSquare
        unlistedButton.target = self
        unlistedButton.action = #selector(unlistedAction)
        
        privateButton.title = I18n.get("PROTECTMODE_PRIVATE")
        privateButton.bezelStyle = .shadowlessSquare
        privateButton.target = self
        privateButton.action = #selector(privateAction)
        
        directButton.title = I18n.get("PROTECTMODE_DIRECT")
        directButton.bezelStyle = .shadowlessSquare
        directButton.target = self
        directButton.action = #selector(directAction)
        
        self.needsLayout = true
    }
    
    @objc func publicAction() {
        callback(SettingsData.ProtectMode.publicMode)
        self.removeFromSuperview()
    }
    
    @objc func unlistedAction() {
        callback(SettingsData.ProtectMode.unlisted)
        self.removeFromSuperview()
    }
    
    @objc func privateAction() {
        callback(SettingsData.ProtectMode.privateMode)
        self.removeFromSuperview()
    }
    
    @objc func directAction() {
        callback(SettingsData.ProtectMode.direct)
        self.removeFromSuperview()
    }
    
    override func layout() {
        publicButton.frame = NSRect(x: 0,
                                    y: 120,
                                    width: 150,
                                    height: 40)
        
        unlistedButton.frame = NSRect(x: 0,
                                      y: 80,
                                      width: 150,
                                      height: 40)
        
        privateButton.frame = NSRect(x: 0,
                                     y: 40,
                                     width: 150,
                                     height: 40)
        
        directButton.frame = NSRect(x: 0,
                                    y: 0,
                                    width: 150,
                                    height: 40)
    }
}
