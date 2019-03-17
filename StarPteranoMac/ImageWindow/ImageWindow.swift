//
//  ImageWindow.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/28.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class ImageWindow: NSPanel {
    var myWindowController = NSWindowController()
    
    init(contentViewController: NSViewController) {
        super.init(contentRect: contentViewController.view.frame,
                   styleMask: NSWindow.StyleMask.closable,
                   backing: NSWindow.BackingStoreType.buffered,
                   defer: false)
        
        self.contentViewController = contentViewController
        self.contentView = contentViewController.view
        
        self.styleMask.insert(NSWindow.StyleMask.titled)
        self.styleMask.insert(NSWindow.StyleMask.resizable)
        
        if #available(OSX 10.12, *) {
            self.tabbingMode = .disallowed
        }
        self.level = .floating
        self.backgroundColor = NSColor.black.withAlphaComponent(0.5)
        self.titlebarAppearsTransparent = true
        self.isOpaque = false
        
        self.center()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.moved),
                                               name: NSWindow.didResizeNotification, object: nil)
    }
    
    func show() {
        myWindowController.window = self
        
        self.makeKeyAndOrderFront(self)
    }
    
    override func close() {
        if myWindowController.window != nil {
            myWindowController.window = nil
            
            myWindowController.close()
            
            super.close()
        }
    }
    
    @objc func moved() {
        if self.frame.width > 0 {
            self.contentViewController?.view.frame = NSRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height - 20)
            (self.contentViewController as? ImageViewController)?.layout()
            (self.contentViewController as? MyPlayerViewController)?.view.layout()
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 123 || event.keyCode == 4 || event.keyCode == 38 {
            (self.contentViewController as? ImageViewController)?.leftAction()
        } else if event.keyCode == 124 || event.keyCode == 40 || event.keyCode == 37 {
            (self.contentViewController as? ImageViewController)?.rightAction()
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        if event.locationInWindow.y > self.frame.height - 22 { return }
        
        if #available(OSX 10.13, *) {
            if let imageView = (self.contentView?.subviews.first as? ImageViewController.LocalImageView), let image = imageView.image, let url = imageView.fileUrl {
                let smallImage = ImageUtils.small(image: image, pixels: 400 * 400)
                
                let pasteboard = NSPasteboard(name: NSPasteboard.Name.dragPboard)
                pasteboard.declareTypes([NSPasteboard.PasteboardType.fileURL], owner: nil)
                (url as NSURL).write(to: pasteboard)
                
                self.drag(smallImage,
                          at: NSPoint.init(x: event.locationInWindow.x - smallImage.size.width / 2,
                                           y: event.locationInWindow.y - smallImage.size.height / 2),
                          offset: NSSize(width: 0, height: 0),
                          event: event,
                          pasteboard: pasteboard,
                          source: self,
                          slideBack: true)
            }
        }
    }
}
