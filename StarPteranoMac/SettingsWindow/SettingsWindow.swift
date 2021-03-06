//
//  SettingsWindow.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/23.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class SettingsWindow: NSWindow {
    static var windowController = NSWindowController()
    static weak var window: SettingsWindow?
    static let contentRect = NSRect(x: 0, y: 0, width: 640, height: 480)
    
    private override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.moved),
                                               name: NSWindow.didMoveNotification, object: nil)
    }
    
    static func show() {
        if let window = self.window {
            window.setIsVisible(true)
            window.center()
            window.makeKeyAndOrderFront(nil)
            return
        }
        
        let window = SettingsWindow(contentRect: contentRect,
                                    styleMask: NSWindow.StyleMask.closable,
                                    backing: NSWindow.BackingStoreType.buffered,
                                    defer: false)
        window.styleMask.insert(NSWindow.StyleMask.titled)
        if #available(OSX 10.12, *) {
            window.tabbingMode = .disallowed
        }
        window.title = I18n.get("TITLE_PREFERENCES")
        self.window = window
        setFrame()
        window.makeKeyAndOrderFront(window)
        
        SettingsWindow.windowController.window = window
        
        let vc = SettingsViewController()
        window.contentViewController = vc
        window.contentView = vc.view
        
        // 最初はアカウントページ
        vc.accountAction()
    }
    
    private static func setFrame() {
        if let origin = SettingsData.settingsWindowOrigin {
            self.window?.setFrameOrigin(origin)
        } else {
            self.window?.setFrameOrigin(CGPoint(x: 50, y: (NSScreen.main?.visibleFrame.height ?? 800) - 50 - 480))
        }
    }
    
    override func close() {
        if SettingsWindow.windowController.window != nil {
            SettingsWindow.windowController.window = nil
            SettingsWindow.windowController.close()
            super.close()
        }
        SettingsWindow.windowController = NSWindowController()
    }
    
    @objc func moved() {
        SettingsData.settingsWindowOrigin = self.frame.origin
    }
}
