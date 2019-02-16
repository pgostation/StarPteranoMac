//
//  CardView.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/13.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class CardView: NSView {
    private let hostName: String
    private let accessToken: String
    private let imageView = NSImageView()
    private let titleLabel = NSTextField()
    private let bodyLabel = NSTextField()
    private let domainLabel = NSTextField()
    private let coverButton = NSButton()
    private var url: URL?
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        formatter.locale = enUSPosixLocale
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return formatter
    }()
    private static var lastRequestDate: Date?
    
    init(id: String?, dateStr: String?, hostName: String, accessToken: String) {
        self.hostName = hostName
        self.accessToken = accessToken
        
        let rect = CGRect(x: -200, y: 0, width: 200, height: 195)
        super.init(frame: rect)
        
        self.addSubview(imageView)
        self.addSubview(titleLabel)
        self.addSubview(bodyLabel)
        self.addSubview(domainLabel)
        self.addSubview(coverButton)
        
        setProperties()
        
        if let id = id {
            let date = CardView.dateFormatter.date(from: dateStr ?? "")
            if let date = date, date.timeIntervalSinceNow >= -3 {
                // 少し待ってからカード情報を取得
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.request(id: id)
                }
            } else if CardView.lastRequestDate == nil || CardView.lastRequestDate!.timeIntervalSinceNow >= -60 {
                // 今すぐカード情報を取得
                request(id: id)
            }
        }
        
        self.layout()
    }
    
    init(card: AnalyzeJson.CardData, hostName: String, accessToken: String) {
        self.hostName = hostName
        self.accessToken = accessToken
        
        let rect = CGRect(x: -200, y: 0, width: 200, height: 195)
        super.init(frame: rect)
        
        self.addSubview(imageView)
        self.addSubview(titleLabel)
        self.addSubview(bodyLabel)
        self.addSubview(domainLabel)
        self.addSubview(coverButton)
        
        setProperties()
        
        draw(card: card)
        
        self.layout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.isHidden = true
        //self.clipsToBounds = true
        self.wantsLayer = true
        self.layer?.backgroundColor = ThemeColor.viewBgColor.cgColor
        self.layer?.cornerRadius = 8
        self.layer?.borderWidth = 1 / (NSScreen.main?.backingScaleFactor ?? 1)
        self.layer?.borderColor = ThemeColor.nameColor.cgColor
        
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        imageView.layer?.opacity = 0.6
        
        //titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byCharWrapping
        titleLabel.textColor = ThemeColor.nameColor
        titleLabel.font = NSFont.boldSystemFont(ofSize: SettingsData.fontSize)
        titleLabel.wantsLayer = true
        titleLabel.layer?.shadowColor = ThemeColor.viewBgColor.cgColor
        titleLabel.layer?.shadowOffset = CGSize(width: 0.5, height: 0.5)
        titleLabel.layer?.shadowOpacity = 1.0
        titleLabel.layer?.shadowRadius = 0.5
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        
        //bodyLabel.numberOfLines = 0
        bodyLabel.lineBreakMode = .byCharWrapping
        bodyLabel.textColor = ThemeColor.contrastColor
        bodyLabel.font = NSFont.systemFont(ofSize: SettingsData.fontSize)
        bodyLabel.wantsLayer = true
        bodyLabel.layer?.shadowColor = ThemeColor.viewBgColor.cgColor
        bodyLabel.layer?.shadowOffset = CGSize(width: 0.5, height: 0.5)
        bodyLabel.layer?.shadowOpacity = 1.0
        bodyLabel.layer?.shadowRadius = 0.5
        bodyLabel.isEditable = false
        bodyLabel.isSelectable = false
        bodyLabel.isBezeled = false
        bodyLabel.drawsBackground = false
        
        //domainLabel.textAlignment = .center
        domainLabel.textColor = ThemeColor.messageColor
        domainLabel.font = NSFont.systemFont(ofSize: SettingsData.fontSize - 2)
        domainLabel.wantsLayer = true
        domainLabel.layer?.shadowColor = ThemeColor.viewBgColor.cgColor
        domainLabel.layer?.shadowOffset = CGSize(width: 0.5, height: 0.5)
        domainLabel.layer?.shadowOpacity = 1.0
        domainLabel.layer?.shadowRadius = 0.5
        domainLabel.alignment = .center
        domainLabel.isEditable = false
        domainLabel.isSelectable = false
        domainLabel.isBezeled = false
        domainLabel.drawsBackground = false
        
        coverButton.isTransparent = true
        coverButton.target = self
        coverButton.action = #selector(tapAction)
    }
    
    private func request(id: String) {
        // キャッシュにあるものを利用する
        if let card = CardView.cache[id] {
            draw(card: card)
            return
        }
        
        CardView.lastRequestDate = Date()
        
        // リクエスト
        guard let url = URL(string: "https://\(self.hostName)/api/v1/statuses/\(id)/card") else { return }
        try? MastodonRequest.get(url: url, accessToken: accessToken) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            if let data = data {
                let responseJson = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                if responseJson != nil {
                    let card = AnalyzeJson.analyzeCard(json: responseJson!!)
                    
                    CardView.addCache(id: id, card: card)
                    
                    DispatchQueue.main.async {
                        strongSelf.draw(card: card)
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    if let card = CardView.cache[id] {
                        self?.draw(card: card)
                    }
                }
            }
        }
    }
    
    private func draw(card: AnalyzeJson.CardData) {
        if card.url == nil { return }
        
        self.isHidden = false
        
        // テキスト
        self.titleLabel.stringValue = card.title ?? ""
        
        self.bodyLabel.stringValue = card.description ?? ""
        
        if SettingsData.isLoadPreviewImage {
            // 画像を取得して設定
            ImageCache.image(urlStr: card.image, isTemp: true, isSmall: false, shortcode: nil, isPreview: true) { (image) in
                self.imageView.image = image
                self.layout()
            }
        }
        
        // タップ時のリンク先
        let url = URL(string: card.url ?? "")
        self.url = url
        
        self.domainLabel.stringValue = url?.host ?? ""
        
        self.layout()
        self.superview?.layout()
    }
    
    @objc func tapAction() {
        if let url = self.url {
            NSWorkspace.shared.open(url)
        }
    }
    
    private static var cache: [String: AnalyzeJson.CardData] = [:]
    private static var oldCache: [String: AnalyzeJson.CardData] = [:]
    
    // キャッシュに追加
    static func addCache(id: String, card: AnalyzeJson.CardData) {
        if cache.count >= 20 {
            oldCache = cache
            cache = [:]
        }
        
        cache[id] = card
    }
    
    // カードがあるかどうかをキャッシュから判断
    static func hasCard(id: String) -> Bool? {
        if let data = cache[id] {
            return data.url != nil
        }
        if let data = oldCache[id] {
            return data.url != nil
        }
        return nil
    }
    
    override func layout() {
        let bottom = self.frame.height
        
        imageView.frame = CGRect(x: 0,
                                 y: 0,
                                 width: self.frame.width,
                                 height: self.frame.height)
        
        titleLabel.frame = CGRect(x: 10,
                                  y: bottom - 70,
                                  width: self.frame.width - 20,
                                  height: 60)
        titleLabel.sizeToFit()
        titleLabel.frame = CGRect(x: 10,
                                  y: bottom - titleLabel.frame.height - 10,
                                  width: self.frame.width - 20,
                                  height: titleLabel.frame.height)
        
        bodyLabel.frame = CGRect(x: 10,
                                 y: 20,
                                 width: self.frame.width - 20,
                                 height: self.frame.height - (titleLabel.frame.height + 30))
        
        domainLabel.frame = CGRect(x: 10,
                                   y: 0,
                                   width: self.frame.width - 20,
                                   height: 20)
        
        coverButton.frame = CGRect(x: 0,
                                   y: 0,
                                   width: self.frame.width,
                                   height: self.frame.height)
    }
}
