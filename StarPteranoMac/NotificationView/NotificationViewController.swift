//
//  NotificationViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/02.
//  Copyright © 2019 pgostation. All rights reserved.
//

// 通知画面のビュー

import Cocoa

final class NotificationViewController: NSViewController {
    let hostName: String
    let accessToken: String
    let type: TimeLineViewController.TimeLineType
    var refreshFlag = false
    
    init(hostName: String, accessToken: String, type: TimeLineViewController.TimeLineType) {
        self.hostName = hostName
        self.accessToken = accessToken
        self.type = type
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = NotificationTableView(hostName: hostName, accessToken: accessToken, type: type)
        self.view = view
        
        view.notificationModel.viewController = self
        
        // 最新のデータを取得
        add(isRefresh: true)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        guard let view = self.view as? NotificationTableView else { return }
        
        // 通知の既読設定
        if let created_at = view.notificationModel.getNewestCreatedAt() {
            let date = DecodeToot.decodeTime(text: created_at)
            let lastDate = SettingsData.newestNotifyDate(accessToken: accessToken)
            if lastDate == nil || date > lastDate! {
                SettingsData.newestNotifyDate(accessToken: accessToken, date: date)
            }
        }
        
        // 30秒以上経過していたら
        if lastRefreshDate.timeIntervalSinceNow < -30 || refreshFlag == true {
            // 最新のデータを取得
            add(isRefresh: true)
        }
    }
    
    var lastRefreshDate = Date(timeInterval: -2, since: Date())
    func add(isRefresh: Bool = false) {
        guard let view = self.view as? NotificationTableView else { return }
        if lastRefreshDate.timeIntervalSinceNow >= -1.5 {
            return // 無限ループ防止
        }
        lastRefreshDate = Date()
        
        refreshFlag = false
        
        let lastId: String? = isRefresh ? nil : view.notificationModel.getLastId()
        
        var idStr = ""
        if let lastId = lastId {
            idStr = "&max_id=\(lastId)"
        }
        var excludeTypes = ""
        if self.type == .notificationMentions {
            excludeTypes = "&exclude_types[]=follow&exclude_types[]=favourite&exclude_types[]=reblog"
        }
        
        guard let url = URL(string: "https://\(hostName)/api/v1/notifications?limit=15\(idStr)\(excludeTypes)") else { return }
        try? MastodonRequest.get(url: url, accessToken: accessToken, completionHandler: { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            if let data = data {
                do {
                    let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Array<AnyObject>
                    
                    if let responseJson = responseJson {
                        if responseJson.count == 0 {
                            if let view = self?.view as? NotificationTableView {
                                view.notificationModel.useAutopagerize = false
                            }
                            return
                        }
                        
                        var list: [AnalyzeJson.NotificationData] = []
                        
                        for json in responseJson {
                            let id = json["id"] as? String
                            let type = json["type"] as? String
                            let created_at = json["created_at"] as? String
                            
                            var account: AnalyzeJson.AccountData? = nil
                            if let accountJson = json["account"] as? [String: Any] {
                                account = AnalyzeJson.analyzeAccountJson(account: accountJson)
                                
                                if let acct = account?.acct, acct != "" {
                                    SettingsData.addRecentMention(key: acct, accessToken: strongSelf.accessToken)
                                }
                            }
                            
                            var status: AnalyzeJson.ContentData? = nil
                            if let statusJson = json["status"] as? [String: Any] {
                                var acct = ""
                                status = AnalyzeJson.analyzeJson(view: nil,
                                                                 model: nil,
                                                                 json: statusJson,
                                                                 acct: &acct)
                            }
                            
                            let data = AnalyzeJson.NotificationData(id: id,
                                                                    type: type,
                                                                    created_at: created_at,
                                                                    account: account,
                                                                    status: status)
                            list.append(data)
                        }
                        
                        DispatchQueue.main.async {
                            guard let view = self?.view as? NotificationTableView else { return }
                            // 表示を更新
                            view.notificationModel.change(addList: list)
                            view.reloadData()
                        }
                    }
                } catch {
                }
            } else if let error = error {
                print(error)
            }
        })
    }
}

final class NotificationTableView: TimeLineView {
    let notificationModel = NotificationTableModel()
    
    init(hostName: String, accessToken: String, type: TimeLineViewController.TimeLineType) {
        super.init(hostName: hostName,
                   accessToken: accessToken,
                   type: TimeLineViewController.TimeLineType.notifications,
                   option: nil,
                   mentions: nil)
        
        self.delegate = notificationModel
        self.dataSource = notificationModel
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.layer?.backgroundColor = ThemeColor.viewBgColor.cgColor
        
        if SettingsData.isTransparentWindow {
            self.backgroundColor = NSColor.clear
        } else {
            self.backgroundColor = ThemeColor.viewBgColor
        }
    }
    
    override func layout() {
        let screenBounds = self.superview?.bounds ?? self.bounds
        
        var sumHeight: CGFloat = 0
        for i in 0..<self.numberOfRows {
            if i > 10 {
                sumHeight += 200
            } else {
                sumHeight += self.model.tableView(self, heightOfRow: i)
            }
        }
        
        self.frame = NSRect(x: 0, y: 0, width: screenBounds.width, height: sumHeight)
    }
}
