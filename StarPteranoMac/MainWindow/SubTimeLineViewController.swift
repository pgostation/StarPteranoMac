//
//  SubTimeLineViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/24.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class SubTimeLineViewController: NSViewController {
    init(name: NSAttributedString, icon: NSImage?, timelineVC: TimeLineViewController) {
        super.init(nibName: nil, bundle: nil)
        
        let view = SubTimeLineView(name: name, icon: icon, timelineView: timelineVC.view)
        self.view = view
        
        self.addChild(timelineVC)
        
        view.closeButton.target = self
        view.closeButton.action = #selector(closeAction)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func closeAction() {
        self.removeFromParent()
        self.view.removeFromSuperview()
    }
}

final class SubTimeLineView: NSView {
    let closeButton = NSButton()
    var breadcrumbView: BreadCrumbListView!
    let scrollView = NSScrollView()
    
    init(name: NSAttributedString, icon: NSImage?, timelineView: NSView) {
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        
        self.breadcrumbView = BreadCrumbListView(name: name, icon: icon)
        
        self.addSubview(closeButton)
        self.addSubview(breadcrumbView)
        self.addSubview(scrollView)
        
        scrollView.documentView = timelineView
        
        setProperties()
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.wantsLayer = true
        self.layer?.backgroundColor = ThemeColor.cellBgColor.cgColor
        
        self.closeButton.title = "✖️"
        self.closeButton.isBordered = false
    }
    
    override func layout() {
        if let superFrame = self.superview?.frame {
            let tootView = self.superview?.subviews.first as? TootView
            self.frame = CGRect(x: 0,
                                y: 0,
                                width: superFrame.width,
                                height: superFrame.height - 22 - (tootView?.frame.height ?? 0) - 24)
        }
        
        self.closeButton.frame = NSRect(x: 0,
                                        y: self.frame.height - 24,
                                        width: 24,
                                        height: 24)
        
        self.breadcrumbView.frame = NSRect(x: 26,
                                           y: self.frame.height - 24,
                                           width: self.frame.width - 26,
                                           height: 24)
        
        self.scrollView.frame = NSRect(x: 0,
                                       y: 0,
                                       width: self.frame.width,
                                       height: self.frame.height - 24)
    }
    
    override func mouseDown(with event: NSEvent) {
        //
    }
    
    override func mouseUp(with event: NSEvent) {
        //
    }
}
