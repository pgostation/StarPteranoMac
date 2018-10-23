//
//  SettingsWindow.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/23.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

class SettingsWindow: NSWindow {
    static weak var window: SettingsWindow?
    
    static func show() {
        if let window = self.window {
            window.center()
            return
        }
        
        let window = SettingsWindow(contentRect: NSRect.init(x: 0, y: 0, width: 640, height: 480),
                                    styleMask: NSWindow.StyleMask.closable,
                                    backing: NSWindow.BackingStoreType.buffered,
                                    defer: true)
        window.styleMask.insert(NSWindow.StyleMask.titled)
        window.title = "Settings"
        window.center()
        self.window = window
        window.makeKeyAndOrderFront(window)
    }
    
    override func close() {
        self.orderOut(self)
    }
}
