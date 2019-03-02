//
//  NotificationViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/02.
//  Copyright © 2019 pgostation. All rights reserved.
//

// 通知画面のビュー

import Cocoa

final class NotificationViewController: TimeLineViewController {
    init(hostName: String, accessToken: String, type: TimeLineViewController.TimeLineType) {
        super.init(hostName: hostName, accessToken: accessToken, type: type)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = NotificationTableView(viewController: self)
        self.view = view
        
        // 各ボタンのターゲット登録
        view.segmentControl.target = self
        view.segmentControl.action = #selector(segmentChanged)
        
        // 最新のデータを取得
        addOld()
    }
    
    /*
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let view = self.view as? NotificationView else { return }
        
        // 通知の既読設定
        if let created_at = view.tableView.model.getNewestCreatedAt() {
            let date = DecodeToot.decodeTime(text: created_at)
            let lastDate = SettingsData.newestNotifyDate(accessToken: SettingsData.accessToken)
            if lastDate == nil || date > lastDate! {
                SettingsData.newestNotifyDate(accessToken: SettingsData.accessToken, date: date)
            }
        }
    }*/
    
    private var count = 0
    func addOld() {
        if count > 1 { return } //####
        count += 1
        
        var lastId: String? = nil
        if let view = self.view as? NotificationTableView {
            lastId = (view.model as? NotificationTableModel)?.getLastId()
        }
        
        /*let waitIndicator = WaitIndicator()
        if lastId == nil {
            self.view.addSubview(waitIndicator)
        }*/
        
        var idStr = ""
        if let lastId = lastId {
            idStr = "&max_id=\(lastId)"
        }
        var excludeTypes = ""
        if self.type == .notificationMentions {
            excludeTypes = "&exclude_types=[\"follow\",\"favourite\",\"reblog\"]"
        }
        
        guard let url = URL(string: "https://\(hostName)/api/v1/notifications?limit=15\(idStr)\(excludeTypes)") else { return }
        try? MastodonRequest.get(url: url, accessToken: accessToken, completionHandler: { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            /*DispatchQueue.main.async {
                waitIndicator.removeFromSuperview()
            }*/
            
            if let data = data {
                do {
                    let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Array<AnyObject>
                    
                    if let responseJson = responseJson {
                        if responseJson.count == 0 {
                            if let view = self?.view as? NotificationTableView {
                                (view.model as? NotificationTableModel)?.useAutopagerize = false
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
                            (view.model as? NotificationTableModel)?.change(addList: list)
                            view.reloadData()
                            
                            // 新着マークを表示
                            if let created_at = (view.model as? NotificationTableModel)?.getNewestCreatedAt() {
                                let date = DecodeToot.decodeTime(text: created_at)
                                let lastDate = SettingsData.newestNotifyDate(accessToken: strongSelf.accessToken)
                                if lastDate == nil || date > lastDate! {
                                    if view.window == nil {
                                        //MainViewController.instance?.markNotificationButton(accessToken: strongSelf.accessToken, to: true)
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
        })
    }
    
    private var lastSelectedSegmentIndex = 0
    @objc func segmentChanged() {
        guard let view = self.view as? NotificationTableView else { return }
        
        self.lastSelectedSegmentIndex = view.segmentControl.selectedSegment
        
        view.reloadData()
    }
}

final class NotificationTableView: TimeLineView {
    let segmentControl = NSSegmentedControl()
    
    init(viewController: NotificationViewController) {
        super.init(hostName: viewController.hostName,
                   accessToken: viewController.accessToken,
                   type: TimeLineViewController.TimeLineType.notifications,
                   option: nil,
                   mentions: nil)
        
        if viewController.type == .notifications {
            self.addSubview(segmentControl)
        }
        
        (model as? NotificationTableModel)?.notificationViewController = viewController
        
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
        
        // セグメントコントロール
        segmentControl.setLabel(I18n.get("NOTIFY_SEG_ALL"), forSegment: 0)
        segmentControl.setLabel(I18n.get("NOTIFY_SEG_MENTION"), forSegment: 1)
        segmentControl.setLabel(I18n.get("NOTIFY_SEG_FOLLOW"), forSegment: 2)
        segmentControl.setLabel(I18n.get("NOTIFY_SEG_FAV"), forSegment: 3)
        segmentControl.setLabel(I18n.get("NOTIFY_SEG_BOOST"), forSegment: 4)
        segmentControl.selectedSegment = 0
    }
    
    override func layout() {
        let screenBounds = self.superview?.bounds ?? self.bounds
        
        let segAllWidth = min(360, screenBounds.width)
        let segWidth = segAllWidth / CGFloat(segmentControl.segmentCount)
        for i in 0..<segmentControl.segmentCount {
            segmentControl.setWidth(segWidth - 0.5, forSegment: i)
        }
        
        if segmentControl.superview != nil {
            segmentControl.frame = CGRect(x: screenBounds.width / 2 - segAllWidth / 2,
                                          y: screenBounds.height - 36,
                                          width: segAllWidth,
                                          height: 30)
            
            self.frame = CGRect(x: 0,
                                     y: 0,
                                     width: screenBounds.width,
                                     height: screenBounds.height - 42)
        } else {
            self.frame = CGRect(x: 0,
                                     y: 0,
                                     width: screenBounds.width,
                                     height: screenBounds.height)
        }
    }
}
