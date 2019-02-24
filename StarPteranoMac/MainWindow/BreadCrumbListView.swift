//
//  BreadCrumbListView.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/24.
//  Copyright © 2019 pgostation. All rights reserved.
//

// パンくずリスト

import Cocoa

final class BreadCrumbListView: NSView {
    let name: NSAttributedString
    let icon: NSImage?
    let nameLabel = NSTextField()
    let iconView = NSImageView()
    
    init(name: NSAttributedString, icon: NSImage?) {
        self.name = name
        self.icon = icon
        
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        
        self.addSubview(iconView)
        self.addSubview(nameLabel)
        
        setProperties()
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.wantsLayer = true
        self.layer?.backgroundColor = ThemeColor.viewBgColor.cgColor
        
        self.nameLabel.attributedStringValue = self.name
        self.nameLabel.textColor = ThemeColor.nameColor
        self.nameLabel.isEditable = false
        self.nameLabel.isBezeled = false
        self.nameLabel.drawsBackground = false
        
        self.iconView.image = self.icon
    }
    
    override func layout() {
        self.iconView.frame = NSRect(x: 5,
                                     y: 2,
                                     width: 20,
                                     height: 20)
        
        self.nameLabel.frame = NSRect(x: 28,
                                      y: 2,
                                      width: self.frame.width - 28,
                                      height: 20)
    }
}
