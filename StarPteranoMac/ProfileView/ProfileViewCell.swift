//
//  ProfileViewCell.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class ProfileViewCell: NSView, NSTextViewDelegate {
    weak var timelineView: TimeLineView? = nil
    private let hostName: String
    private let accessToken: String
    private var id = ""
    private var uri = ""
    private var relationshipData: AnalyzeJson.RelationshipData? = nil
    private var urlStr = ""
    private let accountData: AnalyzeJson.AccountData?
    
    // ヘッダ画像
    var headerImageView = NSImageView()
    
    // メインの表示
    let iconView = NSImageView()
    let iconCoverButton = NSButton()
    let nameLabel = MyTextField()
    let idLabel = MyTextField()
    let noteLabel = NSTextView()
    let dateLabel = MyTextField()
    
    // 追加分の表示
    var serviceLabels: [NSTextField] = []
    var urlLabels: [NSTextView] = []
    
    // 数の表示
    let followingCountTitle = MyTextField()
    let followingCountLabel = MyTextField()
    let followingButton = NSButton()
    let followerCountTitle = MyTextField()
    let followerCountLabel = MyTextField()
    let followerButton = NSButton()
    let statusCountTitle = MyTextField()
    let statusCountLabel = MyTextField()
    
    // メディアのみ表示
    let mediaOnlyButton = NSButton()
    
    // フォローしているか、フォローされているか、ミュート、ブロック状態の表示
    let relationshipLabel = MyTextField()
    
    // アクションボタン
    //  フォローしたり、アンフォローしたり、ブロックしたり、ミュートしたり、リストに入れたり、ブラウザで開いたりする
    let actionButton = NSButton()
    
    init(accountData: AnalyzeJson.AccountData?, isTemp: Bool, hostName: String, accessToken: String) {
        self.accountData = accountData
        self.hostName = hostName
        self.accessToken = accessToken
        
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        
        self.id = accountData?.id ?? ""
        self.uri = accountData?.acct ?? ""
        self.urlStr = accountData?.url ?? ""
        
        // ヘッダ画像
        self.addSubview(headerImageView)
        
        // メインの表示
        self.addSubview(nameLabel)
        self.addSubview(idLabel)
        self.addSubview(noteLabel)
        self.addSubview(dateLabel)
        
        // 数の表示
        self.addSubview(followingCountTitle)
        self.addSubview(followingCountLabel)
        self.addSubview(followingButton)
        self.addSubview(followerCountTitle)
        self.addSubview(followerCountLabel)
        self.addSubview(followerButton)
        self.addSubview(statusCountTitle)
        self.addSubview(statusCountLabel)
        
        self.addSubview(mediaOnlyButton)
        
        // フォローしているか、フォローされているかの表示
        self.addSubview(relationshipLabel)
        self.addSubview(actionButton)
        
        setProperties(data: accountData)
        
        // タップジェスチャー
        followingButton.target = self
        followingButton.action = #selector(followingTapAction)
        
        followerButton.target = self
        followerButton.action = #selector(followersTapAction)
        
        // クリックでアイコンをウィンドウ表示
        iconCoverButton.target = self
        iconCoverButton.action = #selector(tapIconAction)
        
        actionButton.target = self
        actionButton.action = #selector(tapActionButton(_:))
        mediaOnlyButton.target = self
        mediaOnlyButton.action = #selector(mediaOnlyAction)
        
        // フォロー関係かどうかを取得
        if ProfileViewCell.cacheRelationships["\( self.hostName),\(self.id)"] == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                if self?.actionButton.alphaValue == 0 {
                    self?.getRelationship()
                }
            }
        } else {
            getRelationship()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties(data: AnalyzeJson.AccountData?) {
        self.wantsLayer = true
        self.layer?.backgroundColor = ThemeColor.viewBgColor.cgColor
        
        guard let data = data else { return }
        
        // ヘッダ画像
        headerImageView.wantsLayer = true
        headerImageView.layer?.backgroundColor = NSColor.gray.cgColor
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            ImageCache.image(urlStr: data.header ?? data.header_static, isTemp: true, isSmall: false) { [weak self] (image, localUrl) in
                guard let strongSelf = self else { return }
                if image.size.width <= 1 && image.size.height <= 1 { return }
                
                let headerImageView = strongSelf.headerImageView
                headerImageView.image = image
                headerImageView.imageScaling = .scaleProportionallyUpOrDown
                strongSelf.needsLayout = true
            }
        }
        
        // メインの表示
        DispatchQueue.main.async {
            ImageCache.image(urlStr: data.avatar ?? data.avatar_static, isTemp: false, isSmall: true) { [weak self] (image, localUrl) in
                if self == nil { return }
                self?.iconView.image = image
                self?.iconView.wantsLayer = true
                self?.iconView.layer?.cornerRadius = 8
                self?.addSubview(self!.iconView)
                self?.addSubview(self!.iconCoverButton)
                
                self?.iconView.frame = CGRect(x: 10,
                                              y: self!.frame.height - 5 - 60,
                                              width: 60,
                                              height: 60)
                self?.iconCoverButton.frame = CGRect(x: 10,
                                                     y: self!.frame.height - 5 - 60,
                                                     width: 60,
                                                     height: 60)
            }
        }
        
        nameLabel.textColor = ThemeColor.nameColor
        nameLabel.attributedStringValue = DecodeToot.decodeName(name: data.display_name ?? "", emojis: data.emojis, textField: nameLabel) { }
        nameLabel.wantsLayer = true
        nameLabel.layer?.shadowColor = NSColor.black.cgColor
        nameLabel.layer?.shadowOffset = CGSize(width: 0.5, height: 0.5)
        nameLabel.layer?.shadowOpacity = 1.0
        nameLabel.layer?.shadowRadius = 1.0
        nameLabel.font = NSFont.boldSystemFont(ofSize: SettingsData.fontSize + 2)
        nameLabel.cell?.lineBreakMode = .byCharWrapping
        nameLabel.isBordered = false
        nameLabel.isSelectable = false
        nameLabel.isEditable = false
        nameLabel.drawsBackground = false
        
        idLabel.stringValue = "@" + (data.acct ?? "")
        idLabel.textColor = ThemeColor.contrastColor
        idLabel.wantsLayer = true
        idLabel.layer?.shadowColor = ThemeColor.viewBgColor.cgColor
        idLabel.layer?.shadowOffset = CGSize(width: 0.5, height: 0.5)
        idLabel.layer?.shadowOpacity = 1.0
        idLabel.layer?.shadowRadius = 1.0
        idLabel.font = NSFont.boldSystemFont(ofSize: SettingsData.fontSize)
        //idLabel.adjustsFontSizeToFitWidth = true
        idLabel.isBordered = false
        idLabel.isSelectable = false
        idLabel.isEditable = false
        idLabel.drawsBackground = false
        
        //noteLabel.delegate = self
        let (attributedText) = DecodeToot.decodeContent(content: data.note, emojis: data.emojis, callback: nil).0
        noteLabel.textStorage?.append(attributedText)
        noteLabel.textColor = ThemeColor.contrastColor
        noteLabel.linkTextAttributes = [NSAttributedString.Key.foregroundColor: ThemeColor.linkTextColor]
        noteLabel.wantsLayer = true
        noteLabel.layer?.shadowColor = ThemeColor.viewBgColor.cgColor
        noteLabel.layer?.shadowOffset = CGSize(width: 0.5, height: 0.5)
        noteLabel.layer?.shadowOpacity = 1.0
        noteLabel.layer?.shadowRadius = 1.0
        noteLabel.layer?.backgroundColor = ThemeColor.viewBgColor.withAlphaComponent(0.1).cgColor
        noteLabel.backgroundColor = NSColor.clear
        noteLabel.isSelectable = true
        noteLabel.isEditable = false
        noteLabel.font = NSFont.systemFont(ofSize: SettingsData.fontSize)
        
        if let created_at = data.created_at {
            let date = DecodeToot.decodeTime(text: created_at)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            dateLabel.stringValue = "since " + dateFormatter.string(from: date)
        }
        dateLabel.textColor = ThemeColor.idColor
        dateLabel.wantsLayer = true
        dateLabel.layer?.shadowColor = ThemeColor.viewBgColor.cgColor
        dateLabel.layer?.shadowOffset = CGSize(width: 0.5, height: 0.5)
        dateLabel.layer?.shadowOpacity = 1.0
        dateLabel.layer?.shadowRadius = 1.0
        dateLabel.font = NSFont.systemFont(ofSize: SettingsData.fontSize)
        dateLabel.isBordered = false
        dateLabel.isSelectable = false
        dateLabel.isEditable = false
        dateLabel.drawsBackground = false
        
        // 追加分の表示
        for field in data.fields ?? [] {
            let nameLabel = MyTextField()
            nameLabel.stringValue = field["name"] as? String ?? ""
            nameLabel.textColor = ThemeColor.idColor
            nameLabel.font = NSFont.systemFont(ofSize: SettingsData.fontSize)
            nameLabel.cell?.lineBreakMode = .byCharWrapping
            nameLabel.isBordered = false
            nameLabel.isSelectable = false
            nameLabel.isEditable = false
            nameLabel.drawsBackground = false
            serviceLabels.append(nameLabel)
            self.addSubview(nameLabel)
            
            let valueLabel = NSTextView()
            valueLabel.delegate = self
            let attributedText = DecodeToot.decodeContentFast(content: field["value"] as? String, emojis: data.emojis, callback: {
                let attributedText = DecodeToot.decodeContentFast(content: field["value"] as? String, emojis: data.emojis, callback: nil).0
                valueLabel.textStorage?.setAttributedString(attributedText)
            }).0
            valueLabel.textStorage?.setAttributedString(attributedText)
            valueLabel.textColor = ThemeColor.idColor
            valueLabel.linkTextAttributes = [NSAttributedString.Key.foregroundColor: ThemeColor.linkTextColor]
            valueLabel.font = NSFont.systemFont(ofSize: SettingsData.fontSize)
            valueLabel.isSelectable = true
            valueLabel.isEditable = false
            valueLabel.drawsBackground = false
            urlLabels.append(valueLabel)
            self.addSubview(valueLabel)
        }
        
        // 数の表示
        followingCountTitle.stringValue = "following"
        followingCountTitle.textColor = ThemeColor.dateColor
        followingCountTitle.font = NSFont.systemFont(ofSize: SettingsData.fontSize - 2)
        followingCountTitle.alignment = .center
        followingCountTitle.isBordered = false
        followingCountTitle.isSelectable = false
        followingCountTitle.isEditable = false
        followingCountTitle.drawsBackground = false
        
        followingCountLabel.stringValue = "\(data.following_count ?? 0)" + (data.locked == 1 ?  " 🔒" : "")
        followingCountLabel.textColor = ThemeColor.nameColor
        followingCountLabel.font = NSFont.boldSystemFont(ofSize: SettingsData.fontSize)
        followingCountLabel.alignment = .center
        followingCountLabel.isBordered = false
        followingCountLabel.isSelectable = false
        followingCountLabel.isEditable = false
        followingCountLabel.drawsBackground = false
        
        followerCountTitle.stringValue = "followers"
        followerCountTitle.textColor = ThemeColor.dateColor
        followerCountTitle.font = NSFont.systemFont(ofSize: SettingsData.fontSize - 2)
        followerCountTitle.alignment = .center
        followerCountTitle.isBordered = false
        followerCountTitle.isSelectable = false
        followerCountTitle.isEditable = false
        followerCountTitle.drawsBackground = false
        
        followerCountLabel.stringValue = "\(data.followers_count ?? 0)" + (data.locked == 1 ?  " 🔒" : "")
        followerCountLabel.textColor = ThemeColor.nameColor
        followerCountLabel.font = NSFont.boldSystemFont(ofSize: SettingsData.fontSize)
        followerCountLabel.alignment = .center
        followerCountLabel.isBordered = false
        followerCountLabel.isSelectable = false
        followerCountLabel.isEditable = false
        followerCountLabel.drawsBackground = false
        
        statusCountTitle.stringValue = "toots"
        statusCountTitle.textColor = ThemeColor.dateColor
        statusCountTitle.font = NSFont.systemFont(ofSize: SettingsData.fontSize - 2)
        statusCountTitle.alignment = .center
        statusCountTitle.isBordered = false
        statusCountTitle.isSelectable = false
        statusCountTitle.isEditable = false
        statusCountTitle.drawsBackground = false
        
        statusCountLabel.stringValue = "\(data.statuses_count ?? 0)"
        statusCountLabel.textColor = ThemeColor.idColor
        statusCountLabel.font = NSFont.boldSystemFont(ofSize: SettingsData.fontSize)
        statusCountLabel.alignment = .center
        statusCountLabel.isBordered = false
        statusCountLabel.isSelectable = false
        statusCountLabel.isEditable = false
        statusCountLabel.drawsBackground = false
        
        mediaOnlyButton.title = "🖼"
        DispatchQueue.main.async {
            if self.timelineView?.mediaOnly == true {
                self.mediaOnlyButton.layer?.backgroundColor = NSColor.blue.cgColor
            } else {
                self.mediaOnlyButton.layer?.backgroundColor = NSColor.gray.cgColor
            }
        }
        mediaOnlyButton.layer?.cornerRadius = 8
        
        // フォロー関連
        actionButton.title = "…"
        //actionButton.titleLabel?.font = NSFont.boldSystemFont(ofSize: 32)
        actionButton.layer?.backgroundColor = ThemeColor.detailButtonsColor.cgColor
        //actionButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        actionButton.layer?.cornerRadius = 10
        actionButton.layer?.borderColor = ThemeColor.detailButtonsColor.cgColor
        actionButton.layer?.borderWidth = 1
        actionButton.alphaValue = 0
        
        relationshipLabel.textColor = ThemeColor.contrastColor
        relationshipLabel.wantsLayer = true
        relationshipLabel.font = NSFont.systemFont(ofSize: SettingsData.fontSize - 2)
        relationshipLabel.layer?.shadowColor = ThemeColor.viewBgColor.cgColor
        relationshipLabel.layer?.shadowOffset = CGSize(width: 0.5, height: 0.5)
        relationshipLabel.layer?.shadowOpacity = 1.0
        relationshipLabel.layer?.shadowRadius = 1.0
        relationshipLabel.cell?.lineBreakMode = .byCharWrapping
        relationshipLabel.lineBreakMode = .byCharWrapping
        relationshipLabel.isBordered = false
        relationshipLabel.isSelectable = false
        relationshipLabel.isEditable = false
        relationshipLabel.drawsBackground = false
        
        followingButton.isTransparent = true
        followerButton.isTransparent = true
        iconCoverButton.isTransparent = true
    }
    
    static func clearCache() {
        cacheRelationships = [:]
    }
    
    // フォロー関係かどうかを取得
    private static var cacheRelationships: [String: AnalyzeJson.RelationshipData] = [:]
    private func getRelationship(force: Bool = false) {
        if !force, let cachedData = ProfileViewCell.cacheRelationships["\(self.hostName),\(self.id)"] {
            self.relationshipData = cachedData
            setRelationshipStr()
            return
        }
        
        let url = URL(string: "https://\(self.hostName)/api/v1/accounts/relationships?id=\(self.id)")!
        
        try? MastodonRequest.get(url: url, accessToken: self.accessToken) { [weak self] (data, response, error) in
            if let data = data {
                do {
                    let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]]
                    
                    if let responseJson = responseJson?.first {
                        let relationshipData = AnalyzeJson.analyzeRelationshipJson(json: responseJson)
                        self?.relationshipData = relationshipData
                        
                        self?.setRelationshipStr()
                        
                        if let strongSelf = self {
                            ProfileViewCell.cacheRelationships["\(strongSelf.hostName),\(strongSelf.id)"] = relationshipData
                        }
                    }
                } catch {
                }
            }
        }
    }
    
    private func setRelationshipStr() {
        if let relationshipData = self.relationshipData {
            DispatchQueue.main.async {
                var text = ""
                
                // フォロー関連
                if relationshipData.following == 1 && relationshipData.followed_by == 1 {
                    text += I18n.get("RELATIONSHIP_FOLLOWING_AND_FOLLOWED")
                }
                else if relationshipData.following == 1 {
                    text += I18n.get("RELATIONSHIP_FOLLOWING")
                }
                else if relationshipData.followed_by == 1 {
                    text += I18n.get("RELATIONSHIP_FOLLOWED")
                }
                if relationshipData.requested == 1 {
                    text += I18n.get("RELATIONSHIP_REQUESTED")
                }
                /*if relationshipData.endorsed == 1 {
                 text += I18n.get("RELATIONSHIP_ENDORSED")
                 }*/
                
                // ミュート
                if relationshipData.muting == 1 {
                    text += I18n.get("RELATIONSHIP_MUTING")
                }
                if relationshipData.muting_notifications == 1 {
                    text += I18n.get("RELATIONSHIP_MUTING_NOTIFICATION")
                }
                if relationshipData.following == 1 && relationshipData.showing_reblogs == 0 {
                    text += I18n.get("RELATIONSHIP_HIDE_BOOST")
                }
                
                // ブロック
                if relationshipData.domain_blocking == 1 {
                    text += I18n.get("RELATIONSHIP_DOMAIN_BLOCKING")
                }
                if relationshipData.blocking == 1 {
                    text += I18n.get("RELATIONSHIP_BLOCKING")
                }
                
                // 最後の改行を取り除く
                if text.count > 0 {
                    text = String(text.prefix(text.count - 1))
                }
                
                self.relationshipLabel.stringValue = text
                
                self.actionButton.alphaValue = 1
                
                self.needsLayout = true
            }
        }
    }
    
    // 「...」ボタンを押した時の処理
    @objc func tapActionButton(_ sender: NSButton) {
        guard let relationshipData = self.relationshipData else { return }
        
        let hostName = self.hostName
        let accessToken = self.accessToken
        
        ProfileAction.timelineView = self.timelineView
        
        let id = self.id
        let uri = self.uri
        
        let myUserName = SettingsData.accountUsername(accessToken: self.accessToken) ?? ""
        
        let alertController = MyAlertController(title: nil, message: myUserName + "@" + (self.hostName))
        
        if relationshipData.following == 1 {
            // アンフォローする
            alertController.addAction(MyAlertAction(
                title: I18n.get("ACTION_UNFOLLOW"),
                style: MyAlertAction.Style.destructive,
                handler: { _ in
                    ProfileAction.unfollow(id: id, hostName: hostName, accessToken: accessToken)
                    ProfileViewCell.clearCache()
            }))
            
            if relationshipData.showing_reblogs == 1 {
                // ブーストを表示しない
                alertController.addAction(MyAlertAction(
                    title: I18n.get("ACTION_HIDE_BOOST"),
                    style: MyAlertAction.Style.defaultValue,
                    handler: { _ in
                        ProfileAction.hideBoost(id: id, hostName: hostName, accessToken: accessToken)
                        ProfileViewCell.clearCache()
                }))
            } else {
                // ブーストを表示する
                alertController.addAction(MyAlertAction(
                    title: I18n.get("ACTION_SHOW_BOOST"),
                    style: MyAlertAction.Style.defaultValue,
                    handler: { _ in
                        ProfileAction.showBoost(id: id, hostName: hostName, accessToken: accessToken)
                        ProfileViewCell.clearCache()
                }))
            }
        } else {
            if id.suffix(id.count - 1).contains("@") {
                // リモートフォローする
                alertController.addAction(MyAlertAction(
                    title: I18n.get("ACTION_REMOTE_FOLLOW"),
                    style: MyAlertAction.Style.defaultValue,
                    handler: { _ in
                        ProfileAction.remoteFollow(uri: uri, hostName: hostName, accessToken: accessToken)
                        ProfileViewCell.clearCache()
                }))
            } else {
                // フォローする
                alertController.addAction(MyAlertAction(
                    title: I18n.get("ACTION_FOLLOW"),
                    style: MyAlertAction.Style.defaultValue,
                    handler: { _ in
                        ProfileAction.follow(id: id, hostName: hostName, accessToken: accessToken)
                        ProfileViewCell.clearCache()
                }))
            }
        }
        
        if relationshipData.blocking == 1 {
            // アンブロックする
            alertController.addAction(MyAlertAction(
                title: I18n.get("ACTION_UNBLOCK"),
                style: MyAlertAction.Style.destructive,
                handler: { _ in
                    ProfileAction.unblock(id: id, hostName: hostName, accessToken: accessToken)
                    ProfileViewCell.clearCache()
            }))
        } else {
            // ブロックする
            alertController.addAction(MyAlertAction(
                title: I18n.get("ACTION_BLOCK"),
                style: MyAlertAction.Style.destructive,
                handler: { _ in
                    ProfileAction.block(id: id, hostName: hostName, accessToken: accessToken)
                    ProfileViewCell.clearCache()
            }))
        }
        
        if relationshipData.muting == 1 {
            // アンミュートする
            alertController.addAction(MyAlertAction(
                title: I18n.get("ACTION_UNMUTE"),
                style: MyAlertAction.Style.destructive,
                handler: { _ in
                    ProfileAction.unmute(id: id, hostName: hostName, accessToken: accessToken)
                    ProfileViewCell.clearCache()
            }))
        } else {
            // ミュートする
            alertController.addAction(MyAlertAction(
                title: I18n.get("ACTION_MUTE"),
                style: MyAlertAction.Style.destructive,
                handler: { _ in
                    ProfileAction.mute(id: id, hostName: hostName, accessToken: accessToken)
                    ProfileViewCell.clearCache()
            }))
        }
        
        // リストに追加
        alertController.addAction(MyAlertAction(
            title: I18n.get("ACTION_ADD_TO_LIST"),
            style: MyAlertAction.Style.defaultValue,
            handler: { _ in
                let vc = AllListsViewController(accountId: id, hostName: hostName, accessToken: accessToken)
                TimeLineViewManager.getLastSelectedSubTLView()?.present(
                    vc,
                    asPopoverRelativeTo: sender.bounds,
                    of: sender,
                    preferredEdge: NSRectEdge.minY,
                    behavior: NSPopover.Behavior.transient)
        }))
        
        // Safariで表示
        alertController.addAction(MyAlertAction(
            title: I18n.get("ACTION_OPEN_WITH_BROWSER"),
            style: MyAlertAction.Style.defaultValue,
            handler: { _ in
                guard let url = URL(string: self.urlStr) else { return }
                NSWorkspace.shared.open(url)
        }))
        
        alertController.view.layout()
        
        TimeLineViewManager.getLastSelectedSubTLView()?.present(
            alertController,
            asPopoverRelativeTo: sender.bounds,
            of: sender,
            preferredEdge: NSRectEdge.minY,
            behavior: NSPopover.Behavior.transient)
    }
    
    @objc func followingTapAction() {
        let vc = FollowingViewController(type: "accounts/\(self.id)/following", hostName: self.hostName, accessToken: self.accessToken)
        if let subVC = TimeLineViewManager.getLastSelectedSubTLView() {
            subVC.addChild(vc)
            subVC.view.addSubview(vc.view)
            vc.view.needsLayout = true
        }
    }
    
    @objc func followersTapAction() {
        let vc = FollowingViewController(type: "accounts/\(self.id)/followers", hostName: self.hostName, accessToken: self.accessToken)
        if let subVC = TimeLineViewManager.getLastSelectedSubTLView() {
            subVC.addChild(vc)
            subVC.view.addSubview(vc.view)
            vc.view.needsLayout = true
        }
    }
    
    // メディアオンリーのタイムラインにするかどうか
    @objc func mediaOnlyAction() {
        self.timelineView?.mediaOnly = !(self.timelineView?.mediaOnly == true)
        
        if self.timelineView?.mediaOnly == true {
            mediaOnlyButton.layer?.backgroundColor = NSColor.blue.cgColor
        } else {
            mediaOnlyButton.layer?.backgroundColor = NSColor.gray.cgColor
        }
        
        self.timelineView?.clear()
        self.timelineView?.refresh()
    }
    
    // アイコンタップで全画面表示
    @objc func tapIconAction() {
        guard let data = self.accountData else { return }
        
        // アイコンを静止画として表示
        let vc = ImageViewController(imagesUrls: [data.avatar ?? data.avatar_static ?? ""], previewUrls: [data.avatar_static ?? ""], index: 0, smallImage: self.iconView.image)
        ImageWindow(contentViewController: vc).show()
    }
    
    // NSTextViewのリンククリック時の処理
    func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        return true
    }
    
    override func layout() {
        let screenBounds = self.superview?.frame ?? timelineView?.frame ?? NSRect(x: 0, y: 0, width: 0, height: 0)
        
        var top: CGFloat = 0
        
        // 数の表示
        let countsWidth = min(150, screenBounds.width / 3.5)
        statusCountTitle.frame = CGRect(x: 5,
                                        y: top + SettingsData.fontSize,
                                        width: countsWidth - 5,
                                        height: SettingsData.fontSize * 2)
        statusCountLabel.frame = CGRect(x: 5,
                                        y: top,
                                        width: countsWidth - 5,
                                        height: SettingsData.fontSize * 2)
        
        mediaOnlyButton.frame = CGRect(x: countsWidth - 5,
                                       y: top + 4,
                                       width: countsWidth / 2,
                                       height: (SettingsData.fontSize * 2) - 2)
        
        followingCountTitle.frame = CGRect(x: countsWidth * 1.5,
                                           y: top + SettingsData.fontSize,
                                           width: countsWidth,
                                           height: SettingsData.fontSize * 2)
        followingCountLabel.frame = CGRect(x: countsWidth * 1.5,
                                           y: top,
                                           width: countsWidth,
                                           height: SettingsData.fontSize * 2)
        followingButton.frame = followingCountLabel.frame
        
        followerCountTitle.frame = CGRect(x: countsWidth * 2.5,
                                          y: top + SettingsData.fontSize,
                                          width: countsWidth,
                                          height: SettingsData.fontSize * 2)
        followerCountLabel.frame = CGRect(x: countsWidth * 2.5,
                                          y: top,
                                          width: countsWidth,
                                          height: SettingsData.fontSize * 2)
        followerButton.frame = followerCountLabel.frame
        
        top = SettingsData.fontSize * 3
        
        // 追加分の表示
        for index in (0..<serviceLabels.count).reversed() {
            let label = serviceLabels[index]
            let textView = urlLabels[index]
            let width = min(600, screenBounds.width)
            
            label.frame.size.width = screenBounds.width * 0.4
            label.sizeToFit()
            label.frame = CGRect(x: 2,
                                 y: top,
                                 width: width * 0.4 - 2,
                                 height: label.frame.height)
            
            textView.frame.size.width = width * 0.6
            textView.sizeToFit()
            textView.frame = CGRect(x: width * 0.4,
                                    y: top,
                                    width: width * 0.6,
                                    height: textView.frame.height)
            
            let height = max(label.frame.height, textView.frame.height)
            label.frame.size.height = height
            textView.frame.size.height = height
            
            top = max(label.frame.maxY, textView.frame.maxY) + 4
        }
        
        // メインの表示
        dateLabel.frame = CGRect(x: 80,
                                 y: top + 5,
                                 width: screenBounds.width - 80,
                                 height: 24)
        
        noteLabel.frame.size.width = min(595, screenBounds.width) - 80
        noteLabel.sizeToFit()
        noteLabel.frame = CGRect(x: 80,
                                 y: dateLabel.frame.maxY + 5,
                                 width: noteLabel.frame.width,
                                 height: max(80, noteLabel.frame.height))
        
        idLabel.frame = CGRect(x: 80,
                               y: noteLabel.frame.maxY + 5,
                               width: screenBounds.width - 80,
                               height: 24)
        
        nameLabel.frame.size.width = screenBounds.width - 80
        nameLabel.sizeToFit()
        nameLabel.frame = CGRect(x: 80,
                                 y: idLabel.frame.maxY + 5,
                                 width: nameLabel.frame.width,
                                 height: nameLabel.frame.height)
        
        iconView.frame = CGRect(x: 10,
                                y: nameLabel.frame.maxY - 65,
                                width: 60,
                                height: 60)
        
        // フォロー関係表示
        actionButton.frame = CGRect(x: 20,
                                    y: nameLabel.frame.maxY - 115,
                                    width: 40,
                                    height: 40)
        
        relationshipLabel.frame.size.width = 75
        relationshipLabel.sizeToFit()
        relationshipLabel.frame = CGRect(x: 5,
                                         y: actionButton.frame.minY - relationshipLabel.frame.height - 5,
                                         width: relationshipLabel.frame.width,
                                         height: relationshipLabel.frame.height)
        
        self.frame.size.height = iconView.frame.maxY + 5
        
        // ヘッダ画像
        let imageHeight = max(100, self.frame.height - dateLabel.frame.minY + 5)
        headerImageView.frame = CGRect(x: 0,
                                       y: self.frame.height - imageHeight,
                                       width: min(600, screenBounds.width),
                                       height: imageHeight)
    }
}
