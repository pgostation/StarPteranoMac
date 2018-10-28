//
//  TimeLineView.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa
import AVFoundation

final class TimeLineView: NSTableView {
    weak var vc: NSViewController?
    let hostName: String
    let accessToken: String
    let type: TimeLineViewController.TimeLineType
    let option: String?
    let model = TimeLineViewModel()
    private static let tableDispatchQueue = DispatchQueue(label: "TimeLineView")
    var mediaOnly: Bool = false
    private static var audioPlayer: AVAudioPlayer? = nil
    
    var accountList: [String: AnalyzeJson.AccountData] = [:]
    
    init(hostName: String, accessToken: String, type: TimeLineViewController.TimeLineType, option: String?, mentions: ([AnalyzeJson.ContentData], [String: AnalyzeJson.AccountData])?) {
        self.hostName = hostName
        self.accessToken = accessToken
        self.type = type
        self.option = option
        
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        
        self.delegate = model
        self.dataSource = model
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: ""))
        column.width = 400;
        self.addTableColumn(column)
        
        self.backgroundColor = ThemeColor.cellBgColor
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
        case .local:
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
            guard let listId = SettingsData.selectedListId(accessToken: self.accessToken) else {
                return
            }
            url = URL(string: "https://\(hostName)/api/v1/timelines/list/\(listId)?limit=50\(sinceIdStr)")
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
                        if SettingsData.mergeLocalTL && self?.type == .home {
                            let localKey = "\(strongSelf.hostName)_\(strongSelf.accessToken)_\(SettingsData.TLMode.local.rawValue)"
                            if let localTlVc = MainViewController.instance?.timelineList[localKey] {
                                if let localTlView = localTlVc.view as? TimeLineView {
                                    AnalyzeJson.analyzeJsonArray(view: localTlView, model: localTlView.model, jsonList: responseJson, isNew: true, isNewRefresh: isNewRefresh, isMerge: true)
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
                            
                            DispatchQueue.main.sync {
                                // テーブルビューを更新
                                strongSelf.reloadData()
                            }
                            
                            // ローカルにホームを統合する場合
                            if SettingsData.mergeLocalTL && self?.type == .home {
                                let localKey = "\(strongSelf.hostName)_\(strongSelf.accessToken)_\(SettingsData.TLMode.local.rawValue)"
                                if let localTlVc = MainViewController.instance?.timelineList[localKey] {
                                    if let localTlView = localTlVc.view as? TimeLineView {
                                        let contentData = AnalyzeJson.analyzeJson(view: strongSelf, model: strongSelf.model, json: responseJson, acct: &acct, isMerge: true)
                                        let contentList = [contentData]
                                        localTlView.model.change(tableView: localTlView, addList: contentList, accountList: strongSelf.accountList)
                                        
                                        DispatchQueue.main.sync {
                                            // テーブルビューを更新
                                            localTlView.reloadData()
                                        }
                                    }
                                }
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
        if SettingsData.mergeLocalTL && self.type == .local {
            let homeKey = "\(hostName)_\(accessToken)_\(SettingsData.TLMode.home.rawValue)"
            if let homeTlVc = MainViewController.instance?.timelineList[homeKey] {
                if let homeTlView = homeTlVc.view as? TimeLineView {
                    homeTlView.refresh()
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
            else if self.type == .local {
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
        
        guard let timelineList = MainViewController.instance?.timelineList else { return }
        
        let key = "\(self.hostName)_\(self.accessToken)_Home"
        if let homeTimelineViewController = timelineList[key] {
            (homeTimelineViewController.view as? TimeLineView)?.startStreaming()
        } else {
            let homeTimelineViewController = TimeLineViewController(hostName: hostName, accessToken: accessToken, type: .home)
            MainViewController.instance?.timelineList.updateValue(homeTimelineViewController, forKey: key)
            (homeTimelineViewController.view as? TimeLineView)?.startStreaming()
        }
        
        TimeLineView.inChecking = false
    }
    
    // ストリーミングを受信
    //   ホーム(通知含む)、ローカル、連合のみ
    private var streamingObject: MastodonStreaming?
    private var waitingStatusList: [AnalyzeJson.ContentData] = []
    private var waitingIdDict: [String: Bool] = [:]
    @objc func streaming(streamingType: String) {
        guard let url = URL(string: "wss://\(hostName)/api/v1/streaming/?access_token=\(accessToken)&stream=\(streamingType)") else { return }
        
        self.streamingObject = MastodonStreaming(url: url, accessToken: accessToken, callback: { [weak self] string in
            guard let strongSelf = self else { return }
            
            strongSelf.analyzeStreamingData(string: string)
            
            // ローカルにホームを統合する場合
            if SettingsData.mergeLocalTL && self?.type == .home {
                let localKey = "\(strongSelf.hostName)_\(strongSelf.accessToken)_\(SettingsData.TLMode.local.rawValue)"
                if let localTlVc = MainViewController.instance?.timelineList[localKey] {
                    if let localTlView = localTlVc.view as? TimeLineView {
                        localTlView.analyzeStreamingData(string: string, isMerge: true)
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
                            DispatchQueue.main.sync {
                                //offsetY = self.contentOffset.y
                                
                                returnFlag = offsetY > 60 || (self.isManualLoading && self.model.getFirstTootId() != nil)
                            }
                            
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
                    // 通知ボタンにマークをつける
                    //MainViewController.instance?.markNotificationButton(accessToken: accessToken ?? "", to: true)
                    
                    // 効果音を出す
                    if TimeLineView.audioPlayer == nil {
                        let soundFilePath = Bundle.main.path(forResource: "decision21", ofType: "mp3")!
                        let sound = URL(fileURLWithPath: soundFilePath)
                        TimeLineView.audioPlayer = try? AVAudioPlayer(contentsOf: sound, fileTypeHint:nil)
                        TimeLineView.audioPlayer?.prepareToPlay()
                    }
                    TimeLineView.audioPlayer?.currentTime = 0
                    TimeLineView.audioPlayer?.play()
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
        case .local:
            url = URL(string: "https://\(hostName)/api/v1/timelines/public?local=1&limit=50\(maxIdStr)")
        case .federation:
            url = URL(string: "https://\(hostName)/api/v1/timelines/public?limit=50\(maxIdStr)")
        case .user:
            guard let option = option else { return }
            let mediaOnlyStr = mediaOnly ? "&only_media=1" : ""
            url = URL(string: "https://\(hostName)/api/v1/accounts/\(option)/statuses?limit=50\(maxIdStr)\(mediaOnlyStr)")
        case .favorites:
            url = URL(string: "https://\(hostName)/api/v1/favourites?limit=50\(maxIdStr)")
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
            guard let listId = SettingsData.selectedListId(accessToken: accessToken) else {
                return
            }
            url = URL(string: "https://\(hostName)/api/v1/timelines/list/\(listId)?limit=50\(maxIdStr)")
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
                            if SettingsData.mergeLocalTL && self?.type == .home {
                                let localKey = "\(strongSelf.hostName)_\(strongSelf.accessToken)_\(SettingsData.TLMode.local.rawValue)"
                                if let localTlVc = MainViewController.instance?.timelineList[localKey] {
                                    if let localTlView = localTlVc.view as? TimeLineView {
                                        AnalyzeJson.analyzeJsonArray(view: localTlView, model: localTlView.model, jsonList: responseJson, isNew: false, isMerge: true)
                                    }
                                }
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
        if SettingsData.mergeLocalTL && self.type == .local {
            let homeKey = "\(hostName)_\(accessToken)_\(SettingsData.TLMode.home.rawValue)"
            if let homeTlVc = MainViewController.instance?.timelineList[homeKey] {
                if let homeTlView = homeTlVc.view as? TimeLineView {
                    guard let homeId = homeTlView.model.getLastTootId() else { return }
                    if homeId > id {
                        homeTlView.refreshOld(id: homeId)
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
}