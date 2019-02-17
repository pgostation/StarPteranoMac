//
//  ImageWindow.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/28.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class ImageWindow: NSPanel {
    init(contentViewController: NSViewController) {
        super.init(contentRect: contentViewController.view.frame,
                   styleMask: NSWindow.StyleMask.closable,
                   backing: NSWindow.BackingStoreType.retained,
                   defer: false)
        
        self.contentViewController = contentViewController
        self.contentView = contentViewController.view
        
        self.styleMask.insert(NSWindow.StyleMask.titled)
        self.styleMask.insert(NSWindow.StyleMask.resizable)
        
        self.level = .floating
        self.backgroundColor = NSColor.black.withAlphaComponent(0.5)
        self.titlebarAppearsTransparent = true
        self.isOpaque = false
        
        self.center()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.moved),
                                               name: NSWindow.didResizeNotification, object: nil)
    }
    
    func show() {
        self.makeKeyAndOrderFront(self)
    }
    
    override func close() {
        self.orderOut(self)
    }
    
    @objc func moved() {
        if self.frame.width > 0 {
            self.contentViewController?.view.frame = NSRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height - 20)
            (self.contentViewController as? ImageViewController)?.layout()
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 123 {
            (self.contentViewController as? ImageViewController)?.leftAction()
        } else if event.keyCode == 124 {
            (self.contentViewController as? ImageViewController)?.rightAction()
        }
    }
}
