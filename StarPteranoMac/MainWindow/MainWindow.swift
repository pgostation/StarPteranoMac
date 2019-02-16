//
//  MainWindow.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class MainWindow: NSWindow {
    static weak var window: MainWindow?
    
    private override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        AccountSettingsViewController.getAccountData(view: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.moved),
                                               name: NSWindow.didMoveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.moved),
                                               name: NSWindow.didResizeNotification, object: nil)
    }
    
    static func show() {
        if self.window != nil {
            self.window?.setIsVisible(true)
            setFrame()
            return
        }
        
        ThemeColor.change()
        
        let window = MainWindow(contentRect: NSRect(x: 0, y: 0, width: 0, height: 0),
                                    styleMask: NSWindow.StyleMask.closable,
                                    backing: NSWindow.BackingStoreType.buffered,
                                    defer: true)
        window.styleMask.insert(NSWindow.StyleMask.titled)
        window.styleMask.insert(NSWindow.StyleMask.miniaturizable)
        window.styleMask.insert(NSWindow.StyleMask.resizable)
        
        window.title = I18n.get("APPLICATION_NAME")
        
        self.window = window
        setFrame()
        window.makeKeyAndOrderFront(window)
        
        let vc = MainViewController()
        window.contentViewController = vc
        window.contentView = vc.view
    }
    
    private static func setFrame() {
        if let frame = SettingsData.mainWindowFrame {
            self.window?.setFrame(frame, display: true)
        } else {
            let frame = NSRect(x: 0, y: 0, width: min(800, (NSScreen.main?.visibleFrame.width ?? 1600) / 2), height: (NSScreen.main?.visibleFrame.height ?? 400))
            self.window?.setFrame(frame, display: true)
        }
    }
    
    override func close() {
        self.orderOut(self)
    }
    
    @objc func moved() {
        if self.frame.width > 0 {
            SettingsData.mainWindowFrame = self.frame
        }
    }
}
