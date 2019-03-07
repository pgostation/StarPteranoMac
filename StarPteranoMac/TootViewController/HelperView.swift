//
//  HelperView.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/07.
//  Copyright © 2019 pgostation. All rights reserved.
//

// アカウントID、カスタム絵文字、ハッシュタグの補完表示

import Cocoa
import APNGKit

final class HelperViewManager {
    private static weak var instance: HelperView?
    
    enum HelperMode: String {
        case none = ""
        case emoji = ":"
        case account = "@"
        case hashtag = "#"
    }
    
    static func show(hostName: String, accessToken: String, mode: HelperMode, textView: NSTextView, location: Int) {
        let view = HelperView(hostName: hostName, accessToken: accessToken, mode: mode, textView: textView, location: location)
        instance?.closeAction()
        instance = view
        
        if let tootView = textView.superview as? TootView {
            tootView.inputBar.addSubview(view)
            view.needsLayout = true
        }
    }
    
    static func change() {
        instance?.setLabels()
    }
    
    static func close() {
        instance?.removeFromSuperview()
    }
}

private class HelperView: NSView {
    let hostName: String
    let accessToken: String
    
    private let closeButton = NSButton()
    private let scrollView = NSScrollView()
    private let tapParentView = NSView()
    private var tapViews: [TapView] = []
    private let mode: HelperViewManager.HelperMode
    private weak var textView: NSTextView?
    private let location: Int
    
    init(hostName: String, accessToken: String, mode: HelperViewManager.HelperMode, textView: NSTextView, location: Int) {
        self.hostName = hostName
        self.accessToken = accessToken
        self.mode = mode
        self.textView = textView
        self.location = location
        
        super.init(frame: CGRect(x: 0,
                                 y: 0,
                                 width: 0,
                                 height: 40))
        
        self.addSubview(scrollView)
        self.tapParentView.addSubview(closeButton)
        
        scrollView.documentView = tapParentView
        
        closeButton.target = self
        closeButton.action = #selector(closeAction)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.wantsLayer = true
        self.layer?.backgroundColor = ThemeColor.viewBgColor.cgColor
        
        closeButton.layer?.backgroundColor = ThemeColor.viewBgColor.cgColor
        closeButton.title = "×"
        
        setLabels()
    }
    
    func setLabels() {
        guard let textView = self.textView else { return }
        let selectedTextRange = textView.selectedRange()
        let caretPosition = selectedTextRange.location

        let viewText = textView.string
        let tmpText = String(viewText.prefix(caretPosition))
        let text = String(tmpText.suffix(max(0, tmpText.count - self.location - 1))).lowercased()
        
        switch self.mode {
        case .none:
            break
        case .account:
            setAccountLabels(text: text)
        case .emoji:
            setEmojiLabels(text: text)
        case .hashtag:
            setHashtagLabels(text: text)
        }
    }
    
    // アカウントIDのラベルを追加
    private func setAccountLabels(text: String) {
        removeLabels()
        self.tapViews = []
        
        var tmpList: [String] = []
        var list: [String] = []
        
        // 最近使った宛先アカウント
        tmpList += SettingsData.recentMentionList(accessToken: accessToken)
        
        // フォローしているアカウント
        tmpList += SettingsData.followingList(accessToken: accessToken)
        
        // まずは前方一致するアカウントをリストアップ
        for data in tmpList {
            if list.count >= 20 { break }
            
            if text == "" || data.hasPrefix(text) {
                if list.contains(data) { continue }
                list.append(data)
            }
        }
        
        // 一部でも一致するアカウントをリストアップ
        for data in tmpList {
            if list.count >= 20 { break }
            
            if data.contains(text) {
                if list.contains(data) { continue }
                list.append(data)
            }
        }
        
        // リストアップしたアカウントから、タップラベルを追加する
        for data in list {
            let tapView = TapView(accessToken: accessToken, text: "@" + data + " ", trueText: data, textView: textView, location: location)
            
            tapView.label.stringValue = "@" + data
            tapView.label.font = NSFont.systemFont(ofSize: 16)
            tapView.label.textColor = ThemeColor.messageColor
            
            self.tapViews.append(tapView)
        }
        
        addLabels()
    }
    
    // カスタム絵文字のラベルを追加
    private func setEmojiLabels(text: String) {
        removeLabels()
        self.tapViews = []
        
        var emojiList = EmojiData.getEmojiCache(host: hostName, accessToken: accessToken, showHiddenEmoji: true)
        var list: [EmojiData.EmojiStruct] = []
        
        // 最近使った絵文字を前に持ってくる
        for key in SettingsData.recentEmojiList(accessToken: accessToken).reversed() {
            for (index, emoji) in emojiList.enumerated() {
                if emoji.short_code == key {
                    emojiList.remove(at: index)
                    emojiList.insert(emoji, at: 0)
                    break
                }
            }
        }
        
        // 一致する絵文字20件をリストアップ
        for emoji in emojiList {
            if list.count >= 20 { break }
            
            if text == "" || (emoji.short_code?.lowercased() ?? "").contains(text) {
                list.append(emoji)
            }
        }
        
        // リストアップした絵文字から、タップラベルを追加する
        for emoji in list {
            let tapView = TapView(accessToken: accessToken, text: "\u{200b}:" + (emoji.short_code ?? "") + ":\u{200b}", trueText: (emoji.short_code ?? ""),  textView: textView, location: location)
            ImageCache.image(urlStr: emoji.url, isTemp: true, isSmall: true) { image, localUrl  in
                tapView.iconView.image = image
            }
            
            if SettingsData.useAnimation {
                let urlStr = emoji.url
                if !NormalPNGFileList.isNormal(urlStr: urlStr) {
                    APNGImageCache.image(urlStr: urlStr) { image, localUrl  in
                        if image.frameCount <= 1 {
                            NormalPNGFileList.add(urlStr: urlStr)
                            return
                        }
                        // APNGのビューを貼り付ける
                        let imageView = APNGImageView(image: image)
                        if image.frameCount > 1 {
                            imageView.autoStartAnimation = true
                        }
                        let buttonSize: CGFloat = 24
                        imageView.frame = CGRect(x: 0,
                                                 y: 0,
                                                 width: buttonSize,
                                                 height: buttonSize)
                        tapView.iconView.addSubview(imageView)
                        tapView.iconView.image = nil
                    }
                }
            }
            
            tapView.label.stringValue = emoji.short_code ?? ""
            tapView.label.font = NSFont.systemFont(ofSize: 16)
            tapView.label.textColor = ThemeColor.messageColor
            
            self.tapViews.append(tapView)
        }
        
        addLabels()
    }
    
    // ハッシュタグのラベルを追加
    private func setHashtagLabels(text: String) {
        removeLabels()
        self.tapViews = []
        
        var tmpList: [String] = []
        var list: [String] = []
        
        // 最近使ったハッシュタグ
        tmpList += SettingsData.recentHashtagList(accessToken: accessToken)
        
        // 最近TLで見たハッシュタグ
        tmpList += HashtagCache.recentHashtagList
        
        // まずは前方一致するハッシュタグをリストアップ
        for data in tmpList {
            if list.count >= 20 { break }
            
            if text == "" || data.hasPrefix(text) {
                if list.contains(data) { continue }
                list.append(data)
            }
        }
        
        // 一部でも一致するハッシュタグをリストアップ
        for data in tmpList {
            if list.count >= 20 { break }
            
            if data.contains(text) {
                if list.contains(data) { continue }
                list.append(data)
            }
        }
        
        // リストアップしたハッシュタグから、タップラベルを追加する
        for data in list {
            let tapView = TapView(accessToken: accessToken, text: "#" + data + " ", trueText: data, textView: textView, location: location)
            
            tapView.label.stringValue = "#" + data
            tapView.label.font = NSFont.systemFont(ofSize: 16)
            tapView.label.textColor = ThemeColor.messageColor
            
            self.tapViews.append(tapView)
        }
        
        addLabels()
    }
    
    private func removeLabels() {
        for tapView in self.tapViews {
            tapView.removeFromSuperview()
        }
    }
    
    private func addLabels() {
        for tapView in self.tapViews {
            self.tapParentView.addSubview(tapView)
        }
        
        self.needsLayout = true
    }
    
    override func layout() {
        let screenBounds = self.superview?.bounds ?? self.bounds
        
        self.frame = screenBounds
        
        self.scrollView.frame = CGRect(x: 0,
                                       y: 0,
                                       width: screenBounds.width,
                                       height: 24)
        
        self.closeButton.frame = CGRect(x: 0,
                                        y: 0,
                                        width: 24,
                                        height: 24)
        
        var left = self.closeButton.frame.maxX + 5
        
        for tapView in self.tapViews {
            if tapView.label.stringValue.hasPrefix("@") == true || tapView.label.stringValue.hasPrefix("#") == true {
                tapView.label.sizeToFit()
                tapView.label.frame = CGRect(x: 0, y: 0, width: tapView.label.frame.width, height: 24)
            } else {
                tapView.iconView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
                
                tapView.label.sizeToFit()
                tapView.label.frame = CGRect(x: 24, y: 0, width: tapView.label.frame.width, height: 24)
            }
            
            tapView.frame = CGRect(x: left, y: 0, width: tapView.label.frame.maxX, height: 24)
            
            left = tapView.frame.maxX + 5
        }
        
        tapParentView.frame = CGRect(x: 0, y: 0, width: left, height: 24)
    }
    
    @objc func closeAction() {
        self.removeFromSuperview()
    }
}

private class TapView: NSButton {
    let accessToken: String
    let iconView = NSImageView()
    let label = NSTextField()
    private let text: String
    private let trueText: String
    private weak var textView: NSTextView?
    private let location: Int
    
    init(accessToken: String, text: String, trueText: String, textView: NSTextView?, location: Int) {
        self.accessToken = accessToken
        self.text = text
        self.trueText = trueText
        self.textView = textView
        self.location = location
        
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        
        self.addSubview(iconView)
        self.addSubview(label)
        
        self.target = self
        self.action = #selector(tapAction)
        
        label.isBordered = false
        label.isSelectable = false
        label.isEditable = false
        label.drawsBackground = false
        label.font = NSFont.systemFont(ofSize: SettingsData.fontSize)
        
        self.isTransparent = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tapAction() {
        guard let textView = self.textView else { return }
        let selectedTextRange = textView.selectedRange()
        let caretPosition = selectedTextRange.location
        
        // この方法では入力済みの絵文字が消えてしまう
        //guard let viewText = textView.text else { return }
        // textView.text = viewText.prefix(location) + self.text + viewText.suffix(viewText.count - caretPosition)
        
        for _ in 0..<max(0, caretPosition - location) {
            textView.deleteBackward(nil)
        }
        textView.insertText(self.text, replacementRange: selectedTextRange)
        
        if self.text.prefix(1) == "\u{200b}" {
            SettingsData.addRecentEmoji(key: trueText, accessToken: accessToken)
        }
        else if self.text.prefix(1) == "#" {
            SettingsData.addRecentHashtag(key: trueText, accessToken: accessToken)
        }
        else if self.text.prefix(1) == "@" {
            SettingsData.addRecentMention(key: trueText, accessToken: accessToken)
        }
        
        (self.superview?.superview as? HelperView)?.closeAction()
    }
}
