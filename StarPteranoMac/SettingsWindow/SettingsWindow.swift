//
//  SettingsWindow.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/23.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class SettingsWindow: NSWindow {
    static weak var window: SettingsWindow?
    static let contentRect = NSRect(x: 0, y: 0, width: 640, height: 480)
    
    static func show() {
        if let window = self.window {
            window.center()
            return
        }
        
        let window = SettingsWindow(contentRect: contentRect,
                                    styleMask: NSWindow.StyleMask.closable,
                                    backing: NSWindow.BackingStoreType.buffered,
                                    defer: true)
        window.styleMask.insert(NSWindow.StyleMask.titled)
        window.title = I18n.get("TITLE_PREFERENCES")
        window.center()
        self.window = window
        window.makeKeyAndOrderFront(window)
        
        let vc = SettingsViewController()
        window.contentViewController = vc
        window.contentView = vc.view
        
        // 最初はアカウントページ
        vc.accountAction()
    }
    
    override func close() {
        self.orderOut(self)
    }
}
