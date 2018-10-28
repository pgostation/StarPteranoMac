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
    let spoilerTextField = NSTextView()
    let textField = NSTextView()
    let tootButton = NSButton()
    let textCountLabel = NSTextField()
    
    // 入力バー
    let inputBar = NSView()
    let imagesButton = NSButton()
    let imagesCountButton = NSButton()
    let protectButton = NSButton()
    let cwButton = NSButton()
    //let saveButton = NSButton()
    let emojiButton = NSButton()
    
    // 画像チェック画面
    let imageCheckView = ImageCheckView()
    
    func refresh() {
        tootButton.title =  I18n.get("BUTTON_TOOT")
        //tootButton.titleLabel?.font = NSFont.boldSystemFont(ofSize: 20)
        tootButton.layer?.backgroundColor = ThemeColor.mainButtonsBgColor.cgColor
        //tootButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        //tootButton.clipsToBounds = true
        tootButton.layer?.cornerRadius = 10
        tootButton.layer?.borderColor = ThemeColor.mainButtonsTitleColor.cgColor
        tootButton.layer?.borderWidth = 1 / (NSScreen.main?.backingScaleFactor ?? 1)
        
        textCountLabel.textColor = ThemeColor.contrastColor
        textCountLabel.font = NSFont.systemFont(ofSize: 18)
        textCountLabel.backgroundColor = ThemeColor.viewBgColor.withAlphaComponent(0.3)
        //textCountLabel.textAlignment = .center
        //textCountLabel.adjustsFontSizeToFitWidth = true
        //textCountLabel.clipsToBounds = true
        textCountLabel.layer?.cornerRadius = 10
        
        spoilerTextField.backgroundColor = ThemeColor.cellBgColor.withAlphaComponent(0.9)
        spoilerTextField.textColor = ThemeColor.messageColor
        spoilerTextField.font = NSFont.systemFont(ofSize: SettingsData.fontSize + 5)
        spoilerTextField.isEditable = true
        spoilerTextField.layer?.borderColor = ThemeColor.messageColor.cgColor
        spoilerTextField.layer?.borderWidth = 1 / (NSScreen.main?.backingScaleFactor ?? 1)
        //spoilerTextField.tag = UIUtils.responderTag2
        
        if imageCheckView.isHidden {
            DispatchQueue.main.async {
                self.textField.becomeFirstResponder()
            }
        }
        textField.backgroundColor = ThemeColor.cellBgColor.withAlphaComponent(0.9)
        textField.textColor = ThemeColor.messageColor
        textField.font = NSFont.systemFont(ofSize: SettingsData.fontSize + 5)
        textField.isEditable = true
        textField.layer?.borderColor = ThemeColor.messageColor.cgColor
        textField.layer?.borderWidth = 1 / (NSScreen.main?.backingScaleFactor ?? 1)
        //textField.tag = UIUtils.responderTag
        
        inputBar.layer?.backgroundColor = ThemeColor.cellBgColor.withAlphaComponent(0.9).cgColor
        
        imagesButton.title = "🏞"
        
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
        
        cwButton.title = "CW"
        //cwButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        
        //saveButton.title = "📄"
        
        emojiButton.title = "😀"
    }
}
