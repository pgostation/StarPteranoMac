//
//  EmojiView.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/22.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa
import SDWebImage
import APNGKit

final class EmojiView: NSView, NSTextFieldDelegate {
    private let hostName: String
    private let accessToken: String
    private let spaceButton = NSButton()
    private let searchField = NSTextField()
    private var emojiScrollView: EmojiInputScrollView! = nil
    private let emojiScrollClipView = NSClipView()
    private let emojiScrollContentView = NSView()
    
    override var tag: Int {
        return 3948
    }
    
    init(hostName: String, accessToken: String) {
        self.hostName = hostName
        self.accessToken = accessToken
        
        super.init(frame: CGRect(x: 0, y: 0, width: 320, height: SettingsData.emojiKeyboardHeight))
        
        self.emojiScrollView = EmojiInputScrollView(hostName: hostName, accessToken: accessToken, emojiScrollContentView: emojiScrollContentView)
        
        self.addSubview(spaceButton)
        self.addSubview(searchField)
        self.addSubview(emojiScrollView)
        emojiScrollView.contentView = emojiScrollClipView
        emojiScrollClipView.documentView = emojiScrollContentView
        
        spaceButton.target = self
        spaceButton.action = #selector(spaceAction)
        searchField.delegate = self
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.wantsLayer = true
        self.layer?.backgroundColor = ThemeColor.viewBgColor.cgColor
        
        spaceButton.title = I18n.get("BUTTON_SPACEKEY")
        //spaceButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        //spaceButton.titleLabel?.adjustsFontSizeToFitWidth = true
        //spaceButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        //spaceButton.clipsToBounds = true
        spaceButton.layer?.cornerRadius = 10
        
        searchField.placeholderString = I18n.get("SEARCH_PLACEHOLDER")
    }
    
    @objc func spaceAction() {
        guard let textView = NSApplication.shared.keyWindow?.firstResponder as? NSTextView else { return }
        if !textView.isEditable { return }
        
        var spaceStr = " "
        let list = EmojiData.getEmojiCache(host: hostName, accessToken: accessToken, showHiddenEmoji: false)
        for emoji in list {
            if emoji.short_code == "space" {
                spaceStr = "\u{200b}:space:\u{200b}"
                break
            } else if emoji.short_code == "blank" {
                spaceStr = "\u{200b}:blank:\u{200b}"
                break
            }
        }
        
        let range = textView.selectedRange()
        textView.insertText(spaceStr, replacementRange: range)
    }
    
    @objc func returnAction() {
        guard let textView = NSApplication.shared.keyWindow?.firstResponder as? NSTextView else { return }
        if !textView.isEditable { return }
        
        let range = textView.selectedRange()
        textView.insertText("\n", replacementRange: range)
    }
    
    @objc func deleteAction() {
        guard let textView = NSApplication.shared.keyWindow?.firstResponder as? NSTextView else { return }
        if !textView.isEditable { return }
        
        if EmojiView.getCarretBeforeChar(textView: textView) == "\u{200b}" {
            textView.deleteBackward(nil)
        }
        textView.deleteBackward(nil)
    }
    
    // キャレット直前の文字を返す
    static func getCarretBeforeChar(textView: NSTextView) -> Character? {
        let currentRange = textView.selectedRange()
        
        let leftText = textView.attributedString().attributedSubstring(from: NSRange(location: 0, length: currentRange.location))
        
        return leftText.string.last
    }
    
    override func mouseDown(with event: NSEvent) {
        //
    }
    
    func controlTextDidChange(_ obj: Notification) {
        self.emojiScrollView.searchText = self.searchField.stringValue
        self.emojiScrollView.needsLayout = true
    }
    
    override func layout() {
        self.spaceButton.frame = NSRect(x: 10,
                                        y: self.frame.height - 27,
                                        width: 50,
                                        height: 25)
        
        self.searchField.frame = NSRect(x: 70,
                                        y: self.frame.height - 27,
                                        width: 150,
                                        height: 25)
        
        self.emojiScrollView.frame = NSRect(x: 0,
                                            y: 0,
                                            width: self.frame.width,
                                            height: self.frame.height - 30)
    }
}

private final class EmojiInputScrollView: NSScrollView {
    private let hostName: String
    private let accessToken: String
    private var emojiList: [EmojiData.EmojiStruct]
    private var recentEmojiButtons: [EmojiButton] = []
    private var emojiButtons: [EmojiButton] = []
    private var hiddenEmojiButtons: [EmojiButton] = []
    var searchText: String?
    private let separatorView = NSView()
    private let emojiScrollContentView: NSView
    
    init(hostName: String, accessToken: String, emojiScrollContentView: NSView) {
        self.hostName = hostName
        self.accessToken = accessToken
        self.emojiScrollContentView = emojiScrollContentView
        self.emojiList = EmojiData.getEmojiCache(host: hostName, accessToken: accessToken, showHiddenEmoji: true).sorted(by: EmojiInputScrollView.sortFunc)
        
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        
        if self.emojiList.count > 0 {
            addEmojis()
        } else {
            // 絵文字データが取れるまでリトライする
            func retry(count: Int) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.emojiList = EmojiData.getEmojiCache(host: hostName, accessToken: accessToken, showHiddenEmoji: true).sorted(by: EmojiInputScrollView.sortFunc)
                    if self.emojiList.count > 0 {
                        self.addEmojis()
                        self.needsLayout = true
                    } else if count <= 5 {
                        retry(count: count + 1)
                    }
                }
            }
            
            retry(count: 0)
        }
        
        emojiScrollContentView.addSubview(self.separatorView)
        self.separatorView.wantsLayer = true
        self.separatorView.layer?.backgroundColor = NSColor.gray.withAlphaComponent(0.4).cgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private static func sortFunc(e1: EmojiData.EmojiStruct, e2: EmojiData.EmojiStruct) -> Bool {
        return (e1.short_code?.lowercased() ?? "") < (e2.short_code?.lowercased() ?? "")
    }
    
    private func addEmojis() {
        var recentList: [EmojiData.EmojiStruct] = []
        for key in SettingsData.recentEmojiList(accessToken: accessToken) {
            for emojiData in self.emojiList {
                if key == emojiData.short_code {
                    recentList.append(emojiData)
                    break
                }
            }
        }
        
        let list = recentList + self.emojiList
        
        // 絵文字ボタンの追加
        for (index, emoji) in list.enumerated() {
            let button = EmojiButton(key: emoji.short_code ?? "")
            
            // 静的イメージ
            ImageCache.image(urlStr: emoji.url, isTemp: false, isSmall: true, shortcode: emoji.short_code) { image, url in
                button.image = image
                button.isHidden = false
            }
            
            if SettingsData.useAnimation {
                if let urlStr = emoji.url {
                    if !NormalPNGFileList.isNormal(urlStr: urlStr) {
                        APNGImageCache.image(urlStr: urlStr) { (image, localUrl) in
                            if image.frameCount <= 1 {
                                NormalPNGFileList.add(urlStr: urlStr)
                                return
                            }
                            let imageView = NSImageView()
                            imageView.wantsLayer = true
                            imageView.layer?.backgroundColor = ThemeColor.viewBgColor.cgColor
                            imageView.frame = button.bounds
                            imageView.sd_setImage(with: localUrl, completed: { (_, _, _, _) in
                                button.addSubview(imageView)
                            })
                        }
                    }
                }
            }
            button.target = self
            button.action = #selector(tapButton(_:))
            
            emojiScrollContentView.addSubview(button)
            
            if index < recentList.count {
                recentEmojiButtons.append(button)
            } else if emoji.visible_in_picker == 1 {
                emojiButtons.append(button)
            } else {
                hiddenEmojiButtons.append(button)
            }
        }
    }
    
    // テキスト入力欄にテキストを追加
    @objc func tapButton(_ button: NSButton) {
        guard let button = button as? EmojiButton else { return }
        
        guard let textView = NSApplication.shared.keyWindow?.firstResponder as? NSTextView else { return }
        if !textView.isEditable { return }
        
        var emojis: [[String: Any]] = []
        
        for emoji in EmojiData.getEmojiCache(host: hostName, accessToken: accessToken, showHiddenEmoji: true) {
            let dict: [String: Any] = ["shortcode": emoji.short_code ?? "",
                                       "url": emoji.url ?? ""]
            emojis.append(dict)
        }
        
        let prefixStr: String
        if EmojiView.getCarretBeforeChar(textView: textView) == "\u{200b}" {
            prefixStr = ""
        } else {
            prefixStr = "\u{200b}"
        }
        let range = textView.selectedRange()
        textView.insertText("\(prefixStr):" + button.key + ":\u{200b}", replacementRange: range)// U+200bはゼロ幅のスペース
        
        // ダークモードでテキストが黒に戻ってしまう問題対策として、もう一度フォントを設定
        //textView.textColor = ThemeColor.messageColor
        //textView.font = NSFont.systemFont(ofSize: SettingsData.fontSize + 5)
        
        addRecent(key: button.key)
    }
    
    private final class EmojiButton: NSButton {
        let key: String
        
        init(key: String) {
            self.key = key
            
            let buttonSize: CGFloat = 22 + SettingsData.fontSize
            super.init(frame: NSRect(x: 0, y: 0, width: buttonSize, height: buttonSize))
            
            self.isBordered = false
            self.title = ""
            self.isHidden = true
            self.imageScaling = NSImageScaling.scaleProportionallyUpOrDown
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    override func layout() {
        if let searchText = self.searchText, searchText != "" {
            let filteredEmojiButtons = getFilteredEmojiButtons(key: searchText)
            
            layoutEmojiButtons(recentEmojiButtons: nil, emojiButtons: filteredEmojiButtons)
            return
        }
        
        layoutEmojiButtons(recentEmojiButtons: self.recentEmojiButtons, emojiButtons: self.emojiButtons)
        
        for button in self.hiddenEmojiButtons {
            button.frame.origin.x = -100
        }
    }
    
    private func layoutEmojiButtons(recentEmojiButtons: [NSButton]?, emojiButtons: [NSButton]) {
        let buttonSize: CGFloat = 22 + SettingsData.fontSize
        let margin: CGFloat = 2
        let screenBounds = self.bounds
        let xCount = floor(screenBounds.width / (buttonSize + margin)) // ボタンの横に並ぶ数
        let yCount = ceil(CGFloat(recentEmojiButtons?.count ?? 0) / xCount) + ceil(CGFloat(emojiButtons.count) / xCount) // ボタンの縦に並ぶ数
        let recentYCount = ceil(CGFloat(recentEmojiButtons?.count ?? 0) / xCount)
        let offset: CGFloat = (recentEmojiButtons != nil) ? 12 : 0
        var viewHeight = (buttonSize + margin) * yCount + offset
        if viewHeight < self.frame.height {
            viewHeight = self.frame.height
        }
        
        self.hasVerticalScroller = true
        emojiScrollContentView.frame = NSRect(x: 0, y: 0, width: screenBounds.width, height: viewHeight)
        
        // 一番上にスクロール
        self.verticalScroller?.floatValue = 0
        let point = NSPoint(x: 0, y: viewHeight)
        emojiScrollContentView.scroll(point)
        
        if let recentEmojiButtons = recentEmojiButtons, recentYCount > 0 {
            for y in 0..<Int(recentYCount) {
                for x in 0..<Int(xCount) {
                    let index = y * Int(xCount) + x
                    if index >= recentEmojiButtons.count { break }
                    let button = recentEmojiButtons[index]
                    button.frame = CGRect(x: CGFloat(x) * (buttonSize + margin),
                                          y: viewHeight - (CGFloat(y + 1) * (buttonSize + margin)),
                                          width: buttonSize,
                                          height: buttonSize)
                }
            }
            
            self.separatorView.frame = CGRect(x: 0,
                                              y: viewHeight - (recentYCount * (buttonSize + margin) + 2) - offset,
                                              width: screenBounds.width,
                                              height: 8)
        } else {
            self.separatorView.frame = CGRect(x: 0,
                                              y: -100,
                                              width: 0,
                                              height: 0)
        }
        
        for y in 0..<Int(yCount) {
            for x in 0..<Int(xCount) {
                let index = y * Int(xCount) + x
                if index >= emojiButtons.count { break }
                let button = emojiButtons[index]
                button.frame = CGRect(x: CGFloat(x) * (buttonSize + margin),
                                      y: viewHeight - ((CGFloat(y) + recentYCount + 1) * (buttonSize + margin)) - offset,
                                      width: buttonSize,
                                      height: buttonSize)
            }
        }
    }
    
    private func getFilteredEmojiButtons(key: String) -> [NSButton] {
        var buttons: [NSButton] = []
        
        if key == "隠し" {
            for button in self.hiddenEmojiButtons {
                buttons.append(button)
            }
            for button in self.recentEmojiButtons {
                button.frame.origin.x = -100
            }
            for button in self.emojiButtons {
                button.frame.origin.x = -100
            }
            return buttons
        }
        
        for button in self.emojiButtons {
            if button.key.lowercased().contains(key.lowercased()) {
                buttons.append(button)
            } else {
                button.frame.origin.x = -100
            }
        }
        for button in self.recentEmojiButtons {
            button.frame.origin.x = -100
        }
        for button in self.hiddenEmojiButtons {
            button.frame.origin.x = -100
        }
        
        return buttons
    }
    
    // 最近使った絵文字に追加
    private func addRecent(key: String) {
        SettingsData.addRecentEmoji(key: key, accessToken: accessToken)
    }
}

