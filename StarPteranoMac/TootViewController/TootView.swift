//
//  TootView.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/28.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class TootView: NSView {
    // 下書き保存
    static var savedText: String?
    static var savedSpoilerText: String?
    static var savedImages: [URL] = []
    static var inReplyToId: String? = nil
    
    //----
    
    var protectMode = SettingsData.protectMode
    
    // トゥート
    let spoilerTextField = MyTextView()
    let textField = MyTextView()
    let textCountLabel = MyTextField()
    
    // 入力バー
    let inputBar = NSView()
    let imagesButton = NSButton()
    let imagesCountButton = NSButton()
    let protectButton = NSButton()
    let cwButton = NSButton()
    let emojiButton = NSButton()
    
    // 画像チェック画面
    let imageCheckView = ImageCheckView()
    
    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        
        self.addSubview(spoilerTextField)
        self.addSubview(textField)
        
        self.addSubview(inputBar)
        inputBar.addSubview(textCountLabel)
        inputBar.addSubview(imagesButton)
        inputBar.addSubview(imagesCountButton)
        inputBar.addSubview(protectButton)
        inputBar.addSubview(cwButton)
        inputBar.addSubview(emojiButton)
        
        refresh()
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func refresh() {
        self.wantsLayer = true
        self.layer?.backgroundColor = ThemeColor.viewBgColor.cgColor
        
        textCountLabel.textColor = ThemeColor.contrastColor
        textCountLabel.font = NSFont.systemFont(ofSize: 18)
        textCountLabel.backgroundColor = ThemeColor.viewBgColor.withAlphaComponent(0.3)
        //textCountLabel.textAlignment = .center
        //textCountLabel.adjustsFontSizeToFitWidth = true
        //textCountLabel.clipsToBounds = true
        textCountLabel.layer?.cornerRadius = 10
        textCountLabel.isBezeled = false
        
        spoilerTextField.wantsLayer = true
        spoilerTextField.layer?.backgroundColor = ThemeColor.viewBgColor.cgColor
        spoilerTextField.textColor = ThemeColor.messageColor
        spoilerTextField.font = NSFont.systemFont(ofSize: SettingsData.fontSize + 5)
        spoilerTextField.isEditable = true
        spoilerTextField.layer?.borderColor = ThemeColor.messageColor.cgColor
        spoilerTextField.layer?.borderWidth = 1 / (NSScreen.main?.backingScaleFactor ?? 1)
        //spoilerTextField.tag = UIUtils.responderTag2
        spoilerTextField.isHidden = true
        spoilerTextField.font = NSFont.systemFont(ofSize: SettingsData.fontSize)
        spoilerTextField.textContainerInset = NSSize.init(width: 1, height: 5)
        
        if imageCheckView.isHidden {
            DispatchQueue.main.async {
                self.textField.becomeFirstResponder()
            }
        }
        textField.wantsLayer = true
        textField.layer?.backgroundColor = ThemeColor.viewBgColor.cgColor
        textField.textColor = ThemeColor.messageColor
        textField.font = NSFont.systemFont(ofSize: SettingsData.fontSize + 5)
        textField.isEditable = true
        textField.layer?.borderColor = ThemeColor.messageColor.cgColor
        textField.layer?.borderWidth = 1 / (NSScreen.main?.backingScaleFactor ?? 1)
        //textField.tag = UIUtils.responderTag
        textField.font = NSFont.systemFont(ofSize: SettingsData.fontSize)
        textField.textContainerInset = NSSize.init(width: 1, height: 5)
        
        inputBar.layer?.backgroundColor = ThemeColor.cellBgColor.withAlphaComponent(0.9).cgColor
        
        imagesButton.title = "🏞"
        imagesButton.isBordered = false
        
        if imageCheckView.urls.count == 0 {
            imagesCountButton.isHidden = true
        } else {
            imagesCountButton.isHidden = false
            imagesCountButton.title = "[\(imageCheckView.urls.count)]"
        }
        //imagesCountButton.setTitleColor(ThemeColor.messageColor, for: .normal)
        
        switch self.protectMode {
        case .publicMode:
            protectButton.title = "🌐"
        case .unlisted:
            protectButton.title = "🔓"
        case .privateMode:
            protectButton.title = "🔐"
        case .direct:
            protectButton.title = "✉️"
        }
        protectButton.isBordered = false
        
        cwButton.title = "CW"
        //cwButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        cwButton.isBordered = false
        
        emojiButton.title = "😀"
        emojiButton.isBordered = false
        
        textCountLabel.isEditable = false
    }
    
    override func layout() {
        let spoilerTextFieldHeight = spoilerTextField.isHidden ? 0 : max(25, spoilerTextField.frame.height)
        
        let oldHeight = self.frame.size.height
        
        self.frame.size.height = spoilerTextFieldHeight + textField.frame.height + 25
        
        if oldHeight != self.frame.size.height {
            self.superview?.needsLayout = true
        }
        
        spoilerTextField.frame = CGRect(x: 0,
                                        y: self.frame.height,
                                        width: self.frame.width,
                                        height: spoilerTextFieldHeight)
        
        textField.frame = CGRect(x: 0,
                                 y: 25,
                                 width: self.frame.width,
                                 height: textField.frame.height)
        
        inputBar.frame = CGRect(x: 0,
                                y: 0,
                                width: self.frame.width,
                                height: 25)
        
        imagesButton.frame = CGRect(x: 0,
                                    y: 0,
                                    width: 30,
                                    height: 25)
        
        imagesCountButton.frame = CGRect(x: 30,
                                         y: 0,
                                         width: 30,
                                         height: 25)
        
        protectButton.frame = CGRect(x: 60,
                                     y: 0,
                                     width: 30,
                                     height: 25)
        
        cwButton.frame = CGRect(x: 90,
                                y: 0,
                                width: 30,
                                height: 25)
        
        emojiButton.frame = CGRect(x: 120,
                                   y: 0,
                                   width: 30,
                                   height: 25)
        
        textCountLabel.frame = CGRect(x: 150,
                                      y: 0,
                                      width: 60,
                                      height: 25)
    }
    
    final class MyTextView: NSTextView {
        override func layout() {
            super.layout()
            
            superview?.needsLayout = true
        }
    }
}
