//
//  TimeLineView.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa
import AVFoundation

class TimeLineView: NSTableView {
    weak var vc: NSViewController?
    let hostName: String
    let accessToken: String
    let type: TimeLineViewController.TimeLineType
    let option: String?
    let model: TimeLineViewModel
    private static let tableDispatchQueue = DispatchQueue(label: "TimeLineView")
    var mediaOnly: Bool = false
    private static var audioPlayer: AVAudioPlayer? = nil
    var mergeLocalTL = true
    var selectedDate = Date()
    var prevLinkStr: String?
    
    var accountList: [String: AnalyzeJson.AccountData] = [:]
    
    init(hostName: String, accessToken: String, type: TimeLineViewController.TimeLineType, option: String?, mentions: ([AnalyzeJson.ContentData], [String: AnalyzeJson.AccountData])?) {
        self.hostName = hostName
        self.accessToken = accessToken
        self.type = type
        self.option = option
        self.model = TimeLineViewModel()
        
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        
        self.delegate = model
        self.dataSource = model
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: option ?? ""))
        column.width = 200
        self.addTableColumn(column)
        
        self.headerView = nil
        
        //self.separatorStyle = .none
        
        if type != .mentions {
        } else {
            // 会話表示
            self.model.showAutoPagerizeCell = false
            self.model.isDetailTimeline = true
            self.model.change(tableView: self, addList: mentions!.0, accountList: mentions!.1)
            self.model.selectedRow = 0
            DispatchQueue.main.async {
                // 古い物を取りに行く
                self.refresh()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // ダークモード切り替えで更新
    override func updateLayer() {
        if SettingsData.isTransparentWindow {
            self.backgroundColor = NSColor.clear
        } else {
            self.backgroundColor = ThemeColor.cellBgColor
        }
    }
    
    // タイムラインを消去
    func clear() {
        self.model.clear()
    }
    
    // タイムラインを初回取得/手動更新
    private var isManualLoading = false
    @objc func refresh() {
        if self.waitingStatusList.count > 0 {
            DispatchQueue.main.async {
                self.analyzeStreamingData(string: nil)
            }
            
            // ストリーミングが停止していれば再開
            self.startStreaming(inRefresh: true)
            
            return
        }
        
        var isNewRefresh = false
        var sinceIdStr = ""
        if let id = model.getFirstTootId() {
            sinceIdStr = "&since_id=\(id)"
            isNewRefresh = true
        }
        
        let url: URL?
        switch self.type {
        case .home:
            url = URL(string: "https://\(hostName)/api/v1/timelines/home?limit=100\(sinceIdStr)")
        case .local, .homeLocal:
            url = URL(string: "https://\(hostName)/api/v1/timelines/public?local=1&limit=100\(sinceIdStr)")
        case .federation:
            url = URL(string: "https://\(hostName)/api/v1/timelines/public?limit=100\(sinceIdStr)")
        case .user:
            guard let option = option else { return }
            let mediaOnlyStr = mediaOnly ? "&only_media=1" : ""
            url = URL(string: "https://\(hostName)/api/v1/accounts/\(option)/statuses?limit=100\(sinceIdStr)\(mediaOnlyStr)")
        case .favorites:
            url = URL(string: "https://\(hostName)/api/v1/favourites?limit=50\(sinceIdStr)")
        case .localTag:
            guard let option = option else { return }
            guard let encodedOption = option.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else { return }
            url = URL(string: "https://\(hostName)/api/v1/timelines/tag/\(encodedOption)?local=1&limit=100\(sinceIdStr)")
        case .federationTag:
            guard let option = option else { return }
            guard let encodedOption = option.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else { return }
            url = URL(string: "https://\(hostName)/api/v1/timelines/tag/\(encodedOption)?&limit=100\(sinceIdStr)")
        case .mentions:
            if let id = model.getFirstTootId(), id != "" {
                self.refreshContext(id: id)
            }
            return
        case .direct:
            url = URL(string: "https://\(hostName)/api/v1/timelines/direct?limit=50\(sinceIdStr)")
        case .list:
            if option == nil { return }
            url = URL(string: "https://\(hostName)/api/v1/timelines/list/\(option!)?limit=50\(sinceIdStr)")
        case .scheduled:
            return
        case .notifications:
            return
        case .notificationMentions:
            return
        case .search:
            return
        }
        
        guard let requestUrl = url else { return }
        
        self.isManualLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.isManualLoading = false
        }
        
        try? MastodonRequest.get(url: requestUrl, accessToken: accessToken) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            if let data = data {
                do {
                    if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [AnyObject] {
                        AnalyzeJson.analyzeJsonArray(view: strongSelf, model: strongSelf.model, jsonList: responseJson, isNew: true, isNewRefresh: isNewRefresh)
                        
                        // ローカルにホームを統合する場合
                        if strongSelf.mergeLocalTL && (strongSelf.type == .home || strongSelf.type == .local) {
                            let homeLocalKey = TimeLineViewManager.makeKey(hostName: strongSelf.hostName, accessToken: strongSelf.accessToken, type: .homeLocal, option: nil)
                            if let homeLocalTlVc = TimeLineViewManager.get(key: homeLocalKey) {
                                if let homeLocalTlView = homeLocalTlVc.view as? TimeLineView {
                                    AnalyzeJson.analyzeJsonArray(view: homeLocalTlView, model: homeLocalTlView.model, jsonList: responseJson, isNew: true, isNewRefresh: isNewRefresh, isMerge: true)
                                }
                            }
                        }
                    } else if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] {
                        TimeLineView.tableDispatchQueue.async {
                            var acct = ""
                            let contentData = AnalyzeJson.analyzeJson(view: strongSelf, model: strongSelf.model, json: responseJson, acct: &acct)
                            let contentList = [contentData]
                            
                            strongSelf.isManualLoading = false
                            
                            strongSelf.model.change(tableView: strongSelf, addList: contentList, accountList: strongSelf.accountList)
                            
                            //DispatchQueue.main.sync {
                                // テーブルビューを更新
                                strongSelf.reloadData()
                            //}
                            
                            // ローカルにホームを統合する場合
                            if strongSelf.mergeLocalTL && (strongSelf.type == .home || strongSelf.type == .local) {
                                let homeLocalKey = TimeLineViewManager.makeKey(hostName: strongSelf.hostName, accessToken: strongSelf.accessToken, type: .homeLocal, option: nil)
                                if let homeLocalTlVc = TimeLineViewManager.get(key: homeLocalKey) {
                                    if let homeLocalTlView = homeLocalTlVc.view as? TimeLineView {
                                        let contentData = AnalyzeJson.analyzeJson(view: strongSelf, model: strongSelf.model, json: responseJson, acct: &acct, isMerge: true)
                                        let contentList = [contentData]
                                        homeLocalTlView.model.change(tableView: homeLocalTlView, addList: contentList, accountList: strongSelf.accountList)
                                        
                                        //DispatchQueue.main.sync {
                                            // テーブルビューを更新
                                            homeLocalTlView.reloadData()
                                        //}
                                    }
                                }
                            }
                        }
                    }
                } catch {
                }
                
                if self?.type == .favorites {
                    if let response = response as? HTTPURLResponse {
                        if let linkStr = response.allHeaderFields["Link"] as? String {
                            if linkStr.contains("rel=\"prev\"") {
                                if let prefix = linkStr.split(separator: ">").first {
                                    self?.prevLinkStr = String(prefix.suffix(prefix.count - 1))
                                }
                            } else {
                                self?.model.showAutoPagerizeCell = false
                            }
                        } else {
                            self?.model.showAutoPagerizeCell = false
                        }
                    }
                }
            } else if let error = error {
                print(error)
            }
        }
        
        // ホーム/ローカル統合時は、ローカル側を手動更新した時にホームも手動更新しないと
        if self.mergeLocalTL && (self.type == .home || self.type == .local) {
            let homeLocalKey = TimeLineViewManager.makeKey(hostName: self.hostName, accessToken: self.accessToken, type: .homeLocal, option: nil)
            if let homeLocalTlVc = TimeLineViewManager.get(key: homeLocalKey) {
                if let homeLocalTlView = homeLocalTlVc.view as? TimeLineView {
                    homeLocalTlView.refresh()
                }
            }
        }
        
        // ストリーミングが停止していれば再開
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startStreaming()
        }
    }
    
    private func refreshContext(id : String?) {
        guard let id = id else { return }
        guard let url = URL(string: "https://\(hostName)/api/v1/statuses/\(id)/context") else { return }
        
        try? MastodonRequest.get(url: url, accessToken: accessToken) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            if let data = data {
                do {
                    if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: [AnyObject]] {
                        if let ancestors = responseJson["ancestors"] {
                            var acct = ""
                            for ancestor in ancestors {
                                guard let ancestor = ancestor as? [String: Any] else { return }
                                let contentData = AnalyzeJson.analyzeJson(view: strongSelf, model: strongSelf.model, json: ancestor, acct: &acct)
                                strongSelf.model.change(tableView: strongSelf, addList: [contentData], accountList: strongSelf.accountList)
                            }
                        }
                        if let descendants = responseJson["descendants"] {
                            var acct = ""
                            for descendant in descendants {
                                guard let descendant = descendant as? [String: Any] else { return }
                                let contentData = AnalyzeJson.analyzeJson(view: strongSelf, model: strongSelf.model, json: descendant, acct: &acct)
                                strongSelf.model.change(tableView: strongSelf, addList: [contentData], accountList: strongSelf.accountList)
                            }
                        }
                        DispatchQueue.main.sync {
                            strongSelf.reloadData()
                        }
                    }
                } catch {
                }
            } else if let error = error {
                print(error)
            }
        }
    }
    
    // ストリーミングを開始
    func startStreaming(inRefresh: Bool = false) {
        if !SettingsData.isStreamingMode { return }
        
        // 通知用にhomeのストリーミングを確認
        if self.type != .home {
            checkHomeStreaming()
        }
        
        if self.streamingObject?.isConnecting != true && self.streamingObject?.isConnected != true {
            if self.type == .home {
                self.streaming(streamingType: "user")
                
                /*// 新着通知のチェック
                let notificationViewController = NotificationViewController()
                if notificationViewController.view != nil {
                    // viewを参照することで、loadViewさせる
                }*/
            }
            else if (self.type == .local || self.type == .homeLocal) {
                self.streaming(streamingType: "public:local")
            }
            else if self.type == .federation {
                self.streaming(streamingType: "public")
            }
            else {
                return
            }
            
            if !inRefresh {
                // 手動取得する
                refresh()
            }
        }
    }
    
    // 通知用にhomeのストリーミングを確認、接続
    private static var inChecking = false
    private func checkHomeStreaming() {
        if TimeLineView.inChecking { return }
        TimeLineView.inChecking = true
        
        let homeKey = TimeLineViewManager.makeKey(hostName: self.hostName, accessToken: self.accessToken, type: .home, option: nil)
        if let homeTimelineViewController = TimeLineViewManager.get(key: homeKey) {
            (homeTimelineViewController.view as? TimeLineView)?.startStreaming()
        } else {
            let homeTimelineViewController = TimeLineViewController(hostName: hostName, accessToken: accessToken, type: .home)
            TimeLineViewManager.set(key: homeKey, vc: homeTimelineViewController)
            (homeTimelineViewController.view as? TimeLineView)?.startStreaming()
        }
        
        TimeLineView.inChecking = false
    }
    
    // ストリーミングを受信
    //   ホーム(通知含む)、ローカル、連合のみ
    private var streamingObject: MastodonStreaming?
    private var waitingStatusList: [AnalyzeJson.ContentData] = []
    private var waitingIdDict: [String: Bool] = [:]
    private var streamingTimer: Timer?
    @objc func streaming(streamingType: String) {
        guard let url = URL(string: "wss://\(hostName)/api/v1/streaming/?access_token=\(accessToken)&stream=\(streamingType)") else { return }
        
        self.streamingObject = MastodonStreaming(url: url, accessToken: accessToken, callback: { [weak self] string in
            guard let strongSelf = self else { return }
            
            strongSelf.analyzeStreamingData(string: string)
            
            // ローカルにホームを統合する場合
            if strongSelf.mergeLocalTL && (strongSelf.type == .home || strongSelf.type == .local) {
                let homeLocalKey = TimeLineViewManager.makeKey(hostName: strongSelf.hostName, accessToken: strongSelf.accessToken, type: .homeLocal, option: nil)
                if let homeLocalTlVc = TimeLineViewManager.get(key: homeLocalKey) {
                    if let homeLocalTlView = homeLocalTlVc.view as? TimeLineView {
                        homeLocalTlView.analyzeStreamingData(string: string, isMerge: true)
                    }
                }
            }
            
            // 再接続タイマー
            if #available(OSX 10.12, *) {
                if self?.streamingTimer == nil {
                    DispatchQueue.main.async {
                        self?.streamingTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { [weak self] (timer) in
                            if self == nil { return }
                            if self?.streamingObject == nil {
                                self?.streaming(streamingType: streamingType)
                            } else if self?.streamingObject?.isConnected == false {
                                self?.startStreaming()
                            }
                        })
                    }
                }
            }
        })
    }
    
    //
    private func analyzeStreamingData(string: String?, isMerge: Bool = false) {
        func update() {
            self.model.change(tableView: self, addList: self.waitingStatusList, accountList: self.accountList, isStreaming: true)
            self.waitingStatusList = []
            self.waitingIdDict = [:]
        }
        
        if let data = string?.data(using: String.Encoding.utf8) {
            do {
                let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                
                guard let event = responseJson?["event"] as? String else { return }
                let payload = responseJson?["payload"]
                
                switch event {
                case "update":
                    if let string = payload as? String {
                        guard let json = try JSONSerialization.jsonObject(with: string.data(using: String.Encoding.utf8)!, options: .allowFragments) as? [String: Any] else { return }
                        TimeLineView.tableDispatchQueue.async {
                            var acct = ""
                            let statusData = AnalyzeJson.analyzeJson(view: self, model: self.model, json: json, acct: &acct, isMerge: isMerge)
                            
                            if self.waitingIdDict[statusData.id ?? ""] == nil {
                                self.waitingStatusList.insert(statusData, at: 0)
                                self.waitingIdDict[statusData.id ?? ""] = true
                            } else {
                                return
                            }
                            
                            var offsetY: CGFloat = 0
                            var returnFlag = false
                            //DispatchQueue.main.sync {
                                //offsetY = self.contentOffset.y
                                
                                returnFlag = offsetY > 60 || (self.isManualLoading && self.model.getFirstTootId() != nil)
                            //}
                            
                            if returnFlag {
                                // スクロール位置が一番上でない場合、テーブルビューには反映せず裏に持っておく
                                return
                            }
                            
                            if self.model.inAnimating {
                                // アニメーション中なので少し待ってから表示
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    if self.waitingStatusList.count > 0 {
                                        self.analyzeStreamingData(string: nil)
                                    }
                                }
                                return
                            }
                            
                            update()
                        }
                    }
                case "notification":
                    // デスクトップ通知する
                    if let string = payload as? String {
                        guard let json = try JSONSerialization.jsonObject(with: string.data(using: String.Encoding.utf8)!, options: .allowFragments) as? [String: Any] else { return }
                        
                        guard let typeStr = json["type"] as? String else { return }
                        
                        var titleStr = "%@"
                        switch typeStr {
                        case "mention":
                            if !SettingsData.notifyMentions { return }
                            titleStr = I18n.get("NOTIFY_MENTION")
                        case "favourite":
                            if !SettingsData.notifyFavorites { return }
                            titleStr = I18n.get("NOTIFY_FAV")
                        case "reblog":
                            if !SettingsData.notifyBoosts { return }
                            titleStr = I18n.get("NOTIFY_BOOST")
                        case "follow":
                            if !SettingsData.notifyFollows { return }
                            titleStr = I18n.get("NOTIFY_FOLLOW")
                        default:
                            return
                        }
                        
                        let acctStr = (json["account"] as? [String: Any])?["acct"] as? String
                        
                        let contentHtmlStr = (json["status"] as? [String: Any])?["content"] as? String
                        let contentStr = DecodeToot.decodeContent(content: contentHtmlStr, emojis: nil, callback: nil)
                        
                        let notification = NSUserNotification()
                        notification.title = titleStr
                        notification.subtitle = acctStr
                        notification.informativeText = String(contentStr.0.string.prefix(50))
                        notification.userInfo = ["accessToken" : self.accessToken,
                                                 "created_at": (json["created_at"] as? String) ?? ""]
                        DispatchQueue.main.async {
                            NSUserNotificationCenter.default.deliver(notification)
                        }
                        
                        // 通知TL画面を更新する/更新フラグを立てる
                        let key = TimeLineViewManager.makeKey(hostName: hostName, accessToken: accessToken, type: SettingsData.TLMode.notifications)
                        if let vc = TimeLineViewManager.get(key: key) as? NotificationViewController {
                            vc.refreshFlag = true
                            if vc.parent != nil && vc.lastRefreshDate.timeIntervalSinceNow <= -30 {
                                vc.add(isRefresh: true)
                            }
                        }
                        if typeStr == "mention" {
                            let key = TimeLineViewManager.makeKey(hostName: hostName, accessToken: accessToken, type: SettingsData.TLMode.mentions)
                            if let vc = TimeLineViewManager.get(key: key) as? NotificationViewController {
                                vc.refreshFlag = true
                                if vc.parent != nil && vc.lastRefreshDate.timeIntervalSinceNow <= -30 {
                                    vc.add(isRefresh: true)
                                }
                            }
                        }
                    }
                case "delete":
                    if let deleteId = payload as? String {
                        // waitingStatusListからの削除
                        for (index, data) in waitingStatusList.enumerated() {
                            if deleteId == data.id {
                                waitingStatusList.remove(at: index)
                                return
                            }
                        }
                        
                        // 表示中のリストからの削除
                        self.model.delete(tableView: self, deleteId: deleteId)
                    }
                case "filters_changed":
                    break
                default:
                    break
                }
            } catch { }
        } else {
            if self.model.inAnimating {
                // アニメーション中なので少し待ってから表示
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if self.waitingStatusList.count > 0 {
                        self.analyzeStreamingData(string: nil)
                    }
                }
            }
            update()
        }
    }
    
    // タイムラインに古いトゥートを追加
    func refreshOld(id: String?) {
        guard let id = id else { return }
        
        let maxIdStr = "&max_id=\(id)"
        
        let url: URL?
        switch self.type {
        case .home:
            url = URL(string: "https://\(hostName)/api/v1/timelines/home?limit=50\(maxIdStr)")
        case .local, .homeLocal:
            url = URL(string: "https://\(hostName)/api/v1/timelines/public?local=1&limit=50\(maxIdStr)")
        case .federation:
            url = URL(string: "https://\(hostName)/api/v1/timelines/public?limit=50\(maxIdStr)")
        case .user:
            guard let option = option else { return }
            let mediaOnlyStr = mediaOnly ? "&only_media=1" : ""
            url = URL(string: "https://\(hostName)/api/v1/accounts/\(option)/statuses?limit=50\(maxIdStr)\(mediaOnlyStr)")
        case .favorites:
            if let prevLinkStr = self.prevLinkStr {
                url = URL(string: prevLinkStr)
            } else {
                return
            }
        case .localTag:
            guard let option = option else { return }
            guard let encodedOption = option.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else { return }
            url = URL(string: "https://\(hostName)/api/v1/timelines/tag/\(encodedOption)?local=1&limit=50\(maxIdStr)")
        case .federationTag:
            guard let option = option else { return }
            guard let encodedOption = option.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else { return }
            url = URL(string: "https://\(hostName)/api/v1/timelines/tag/\(encodedOption)?&limit=50\(maxIdStr)")
        case .mentions:
            return
        case .direct:
            url = URL(string: "https://\(hostName)/api/v1/timelines/direct?limit=50\(maxIdStr)")
        case .list:
            url = URL(string: "https://\(hostName)/api/v1/timelines/list/\(option!)?limit=50\(maxIdStr)")
        case .scheduled:
            return
        case .notifications:
            return
        case .notificationMentions:
            return
        case .search:
            return
        }
        
        guard let requestUrl = url else { return }
        
        try? MastodonRequest.get(url: requestUrl, accessToken: accessToken) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            if let data = data {
                do {
                    let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Array<AnyObject>
                    
                    if let responseJson = responseJson {
                        TimeLineView.tableDispatchQueue.async {
                            // ループ防止
                            if responseJson.count == 0 {
                                strongSelf.model.showAutoPagerizeCell = false
                            }
                            
                            AnalyzeJson.analyzeJsonArray(view: strongSelf, model: strongSelf.model, jsonList: responseJson, isNew: false)
                            
                            // ローカルにホームを統合する場合
                            if strongSelf.mergeLocalTL && strongSelf.type == .home {
                                let homeLocalKey = TimeLineViewManager.makeKey(hostName: strongSelf.hostName, accessToken: strongSelf.accessToken, type: .homeLocal, option: nil)
                                if let homeLocalTlVc = TimeLineViewManager.get(key: homeLocalKey) {
                                    if let homeLocalTlView = homeLocalTlVc.view as? TimeLineView {
                                        AnalyzeJson.analyzeJsonArray(view: homeLocalTlView, model: homeLocalTlView.model, jsonList: responseJson, isNew: false, isMerge: true)
                                    }
                                }
                            }
                        }
                    }
                    
                    if self?.type == .favorites {
                        if let response = response as? HTTPURLResponse {
                            if let linkStr = response.allHeaderFields["Link"] as? String {
                                if linkStr.contains("rel=\"prev\"") {
                                    if let prefix = linkStr.split(separator: ">").first {
                                        self?.prevLinkStr = String(prefix.suffix(prefix.count - 1))
                                    }
                                } else {
                                    self?.model.showAutoPagerizeCell = false
                                }
                            } else {
                                self?.model.showAutoPagerizeCell = false
                            }
                        }
                    }
                } catch {
                }
            } else if let error = error {
                print(error)
            }
        }
        
        // ホーム/ローカル統合時は、ローカル側を手動更新した時にホームも手動更新しないと
        if self.mergeLocalTL && (self.type == .home || self.type == .local) {
            let homeLocalKey = TimeLineViewManager.makeKey(hostName: self.hostName, accessToken: self.accessToken, type: .homeLocal, option: nil)
            if let homeLocalTlVc = TimeLineViewManager.get(key: homeLocalKey) {
                if let homeLocalTlView = homeLocalTlVc.view as? TimeLineView {
                    guard let homeLocalId = homeLocalTlView.model.getLastTootId() else { return }
                    if homeLocalId > id {
                        homeLocalTlView.refreshOld(id: homeLocalId)
                    }
                }
            }
        }
    }
    
    // お気に入りにする/解除する
    func favoriteAction(id: String, isFaved: Bool) {
        let url: URL
        if isFaved {
            url = URL(string: "https://\(hostName)/api/v1/statuses/\(id)/unfavourite")!
        } else {
            url = URL(string: "https://\(hostName)/api/v1/statuses/\(id)/favourite")!
        }
        
        try? MastodonRequest.post(url: url, accessToken: accessToken, body: [:]) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            if let data = data {
                do {
                    if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] {
                        var acct = ""
                        let contentData = AnalyzeJson.analyzeJson(view: strongSelf, model: strongSelf.model, json: responseJson, acct: &acct)
                        let contentList = [contentData]
                        
                        DispatchQueue.main.async {
                            strongSelf.model.change(tableView: strongSelf, addList: contentList, accountList: [:])
                        }
                    }
                } catch {
                    
                }
            }
        }
    }
    
    // ブーストする/解除する
    func boostAction(id: String, isBoosted: Bool) {
        let url: URL
        if isBoosted {
            url = URL(string: "https://\(hostName)/api/v1/statuses/\(id)/unreblog")!
        } else {
            url = URL(string: "https://\(hostName)/api/v1/statuses/\(id)/reblog")!
        }
        
        try? MastodonRequest.post(url: url, accessToken: accessToken, body: [:]) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            if let data = data {
                do {
                    if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] {
                        var acct = ""
                        let contentData = AnalyzeJson.analyzeJson(view: strongSelf, model: strongSelf.model, json: responseJson, acct: &acct)
                        let contentList = [contentData]
                        
                        DispatchQueue.main.async {
                            strongSelf.model.change(tableView: strongSelf, addList: contentList, accountList: [:], isBoosted: true)
                        }
                    }
                } catch {
                    
                }
            }
        }
    }
    
    func myKeyDown(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags) {
        func getCell() -> TimeLineViewCell? {
            if let selectedRow = model.selectedRow {
                if let tlVC = TimeLineViewManager.getLastSelectedTLView() {
                    if let tlView = tlVC.view as? TimeLineView {
                        if let cell = model.tableView(tlView, viewFor: nil, row: selectedRow) as? TimeLineViewCell {
                            return cell
                        }
                    }
                }
            }
            return nil
        }
        
        switch keyCode {
        case 126, 40: // up arrow, k
            // ひとつ上を選択
            if let selectedRow = model.selectedRow {
                model.selectRow(timelineView: self, row: max(0, selectedRow - 1), notSelect: selectedRow == 0)
            } else {
                model.selectRow(timelineView: self, row: 0, notSelect: selectedRow == 0)
            }
        case 125, 38: // down arrow, l
            // ひとつ下を選択
            if let selectedRow = model.selectedRow {
                model.selectRow(timelineView: self, row: selectedRow + 1, notSelect: false)
            } else {
                model.selectRow(timelineView: self, row: 0, notSelect: false)
            }
        case 48: //tab
            // 入力フィールドにフォーカスを移す
            if let tlVC = TimeLineViewManager.getLastSelectedTLView() {
                let textField = ((tlVC.parent as? SubViewController)?.tootVC.view as? TootView)?.textField
                MainWindow.window?.makeFirstResponder(textField)
            }
        case 53: //esc
            // 選択解除
            if let tlVC = TimeLineViewManager.getLastSelectedTLView() {
                if let tlView = tlVC.view as? TimeLineView {
                    tlView.model.selectedRow = nil
                    tlView.reloadData()
                }
            }
        case 36, 52: // return
            // リプライ
            if modifierFlags.contains(NSEvent.ModifierFlags.shift) {
                getCell()?.replyAction(isAll: true)
            } else {
                getCell()?.replyAction()
            }
        case 3: // f
            // お気に入り
            getCell()?.favoriteAction()
        case 11: // b
            // ブースト
            getCell()?.boostAction()
        case 4: // h
            // ユーザータイムラインを表示
            getCell()?.tapAccountAction()
        case 37: // l
            // リンクを開く
            let string = getCell()?.messageView?.string ?? ""
            let regex = try? NSRegularExpression(pattern: "http(s)?://([\\w-]+\\.)+[\\w-]+(/[\\w- ./?%&=]*)?",
                                                 options: NSRegularExpression.Options())
            if let result = regex?.firstMatch(in: string,
                                              options: NSRegularExpression.MatchingOptions(),
                                              range: NSMakeRange(0, string.count)) {
                let linkStr = (string as NSString).substring(with: result.range(at: 0))
                if let url = URL(string: linkStr) {
                    NSWorkspace.shared.open(url)
                }
            }
        case 15: //r
            // 会話ビューを開く
            if let tlVC = TimeLineViewManager.getLastSelectedTLView() {
                if let tlView = tlVC.view as? TimeLineView {
                    if let selectedRow = model.selectedRow {
                        model.gotoDetailView(timelineView: tlView, row: selectedRow)
                    }
                }
            }
        case 17: // t
            // ブラウザでトゥートを開く
            getCell()?.browserAction()
        case 14: // e
            // イメージプレビュー
            let cell = getCell()
            if let imageView = cell?.imageViews.first {
                cell?.imageTapAction(imageView)
            }
        case 1: // s
            // もっと見る/やっぱり隠す
            let tmpCell = getCell()
            if let tlVC = TimeLineViewManager.getLastSelectedTLView() {
                if let tlView = tlVC.view as? TimeLineView {
                    for subview in tlView.subviews {
                        if let subview = subview as? NSTableRowView {
                            for cell in subview.subviews {
                                if let cell = cell as? TimeLineViewCell {
                                    if cell.id == tmpCell?.id {
                                        if cell.showMoreButton != nil {
                                            cell.showMoreAction()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        default:
            break
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        self.selectedDate = Date()
        
        self.resignFirstResponder()
        return false
    }
}
