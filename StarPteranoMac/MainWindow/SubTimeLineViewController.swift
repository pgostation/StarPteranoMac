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
    
    // アニメーションで閉じる
    @objc func closeAction() {
        let animation = NSViewAnimation(duration: 0.15, animationCurve: NSAnimation.Curve.easeOut)
        let animationsDict: [NSViewAnimation.Key: Any] = [
            NSViewAnimation.Key.target: self.view,
            NSViewAnimation.Key.startFrame: self.view.frame,
            NSViewAnimation.Key.endFrame: NSRect(x: self.view.frame.origin.x + self.view.frame.width,
                                                 y: self.view.frame.origin.y,
                                                 width: self.view.frame.width,
                                                 height: self.view.frame.height),
            ]
        animation.viewAnimations = [animationsDict]
        animation.start()
        
        DispatchQueue.main.async {
            self.removeFromParent()
            self.view.removeFromSuperview()
        }
    }
    
    // アニメーションで表示
    func showAnimation(parentVC: NSViewController?) {
        parentVC?.addChild(self)
        parentVC?.view.addSubview(self.view)
        
        self.view.alphaValue = 1
        self.view.layout()
        
        let endFrame = self.view.frame
        self.view.frame = NSRect(x: self.view.frame.origin.x + self.view.frame.width,
                                 y: self.view.frame.origin.y,
                                 width: self.view.frame.width,
                                 height: self.view.frame.height)
        
        self.view.alphaValue = 0.25
        let animation = NSViewAnimation(duration: 0.15, animationCurve: NSAnimation.Curve.easeIn)
        let animationsDict: [NSViewAnimation.Key: Any] = [
            NSViewAnimation.Key.target: self.view,
            NSViewAnimation.Key.startFrame: self.view.frame,
            NSViewAnimation.Key.endFrame: endFrame,
            ]
        animation.viewAnimations = [animationsDict]
        animation.start()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.view.alphaValue = 0.5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            self.view.alphaValue = 0.75
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.view.alphaValue = 1
        }
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
        self.layer?.borderColor = ThemeColor.viewBgColor.cgColor
        self.layer?.borderWidth = 1
        
        self.closeButton.title = "✖️"
        self.closeButton.isBordered = false
    }
    
    override func layout() {
        if let superFrame = self.superview?.frame, self.alphaValue == 1 {
            let tootView = self.superview?.subviews.first as? TootView
            let width = min(400, superFrame.width)
            self.frame = NSRect(x: superFrame.width - width,
                                y: 0,
                                width: width,
                                height: superFrame.height - 22 - (tootView?.frame.height ?? 0) - 20)
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
