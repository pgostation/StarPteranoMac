//
//  SettingsSelectProtectMode.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/19.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class SettingsSelectProtectMode {
    static func showActionSheet(hostName: String, accessToken: String, fromView: NSView, callback: @escaping ((SettingsData.ProtectMode)->Void)) {
        for subVC in MainViewController.instance?.subVCList ?? [] {
            if accessToken == subVC.tootVC.accessToken {
                let vc = ProtectModeViewController()
                vc.view = ProtectModeView(vc: vc, callback: callback)
                if #available(OSX 10.14, *) {
                    subVC.present(vc, asPopoverRelativeTo: fromView.bounds, of: fromView, preferredEdge: NSRectEdge.minY, behavior: NSPopover.Behavior.transient)
                } else {
                    subVC.addChild(vc)
                    subVC.view.addSubview(vc.view)
                    vc.view.frame.origin = NSPoint(
                        x: fromView.frame.midX - vc.view.frame.width / 2,
                        y: subVC.view.frame.maxY - 60 - vc.view.frame.height)
                }
                break
            }
        }
    }
}

final class ProtectModeViewController: NSViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ProtectModeView: NSView {
    weak var vc: ProtectModeViewController?
    private let publicButton = NSButton()
    private let unlistedButton = NSButton()
    private let privateButton = NSButton()
    private let directButton = NSButton()
    private let callback: ((SettingsData.ProtectMode)->Void)
    
    init(vc: ProtectModeViewController, callback: @escaping ((SettingsData.ProtectMode)->Void)) {
        self.vc = vc
        self.callback = callback
        
        super.init(frame: NSRect(x: 0, y: 0, width: 150, height: 160))
        
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
        if #available(OSX 10.14, *) {
            vc?.dismiss(nil)
        } else  {
            vc?.removeFromParent()
            vc?.view.removeFromSuperview()
        }
    }
    
    @objc func unlistedAction() {
        callback(SettingsData.ProtectMode.unlisted)
        if #available(OSX 10.14, *) {
            vc?.dismiss(nil)
        } else  {
            vc?.removeFromParent()
            vc?.view.removeFromSuperview()
        }
    }
    
    @objc func privateAction() {
        callback(SettingsData.ProtectMode.privateMode)
        if #available(OSX 10.14, *) {
            vc?.dismiss(nil)
        } else  {
            vc?.removeFromParent()
            vc?.view.removeFromSuperview()
        }
    }
    
    @objc func directAction() {
        callback(SettingsData.ProtectMode.direct)
        if #available(OSX 10.14, *) {
            vc?.dismiss(nil)
        } else  {
            vc?.removeFromParent()
            vc?.view.removeFromSuperview()
        }
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
