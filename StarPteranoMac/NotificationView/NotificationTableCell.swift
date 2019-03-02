//
//  NotificationTableCell.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/02.
//  Copyright © 2019 pgostation. All rights reserved.
//

// 通知の内容を表示するセル

import Cocoa

final class NotificationTableCell: NSView {
    var id = ""
    
    // 基本ビュー
    let lineLayer = CALayer()
    let iconView = NSImageView()
    let nameLabel = MyTextField()
    let idLabel = MyTextField()
    let dateLabel = MyTextField()
    let notificationLabel = MyTextField()
    var statusLabel = NSTextView()
    let imageViews = [NSImageView(), NSImageView(), NSImageView(), NSImageView()]
    
    //var followButton: UIButton?
    let replyButton = NSButton()
    let favoriteButton = NSButton()
    
    var accountId: String?
    var date: Date = Date()
    var timer: Timer?
    var accountData: AnalyzeJson.AccountData?
    
    var statusId: String?
    var visibility: String?
    var isFaved = false
    
    weak var tableView: NotificationTableView?
    
    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        
        self.addSubview(iconView)
        self.addSubview(nameLabel)
        self.addSubview(idLabel)
        self.addSubview(dateLabel)
        self.addSubview(notificationLabel)
        self.addSubview(statusLabel)
        for imageView in imageViews {
            self.addSubview(imageView)
        }
        self.addSubview(replyButton)
        self.addSubview(favoriteButton)
        self.wantsLayer = true
        self.layer?.addSublayer(self.lineLayer)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        // 固定プロパティは初期化時に設定
        if SettingsData.isTransparentWindow {
            self.layer?.backgroundColor = NSColor.clear.cgColor
        } else {
            self.layer?.backgroundColor = ThemeColor.cellBgColor.cgColor
        }
        
        self.iconView.wantsLayer = true
        self.iconView.layer?.cornerRadius = 5
        
        self.nameLabel.textColor = ThemeColor.nameColor
        self.nameLabel.font = NSFont.boldSystemFont(ofSize: SettingsData.fontSize)
        self.nameLabel.backgroundColor = ThemeColor.cellBgColor
        
        self.idLabel.textColor = ThemeColor.idColor
        self.idLabel.font = NSFont.systemFont(ofSize: SettingsData.fontSize - 2)
        self.idLabel.backgroundColor = ThemeColor.cellBgColor
        
        self.dateLabel.textColor = ThemeColor.dateColor
        self.dateLabel.font = NSFont.systemFont(ofSize: SettingsData.fontSize - 2)
        self.dateLabel.alignment = .right
        self.dateLabel.backgroundColor = ThemeColor.cellBgColor
        
        self.notificationLabel.textColor = ThemeColor.idColor
        self.notificationLabel.font = NSFont.systemFont(ofSize: SettingsData.fontSize)
        self.notificationLabel.backgroundColor = ThemeColor.cellBgColor
        
        self.statusLabel.textColor = ThemeColor.idColor
        self.statusLabel.linkTextAttributes = [NSAttributedString.Key.foregroundColor: ThemeColor.linkTextColor]
        self.statusLabel.font = NSFont.systemFont(ofSize: SettingsData.fontSize - 2)
        self.statusLabel.backgroundColor = ThemeColor.toMentionBgColor
        self.statusLabel.isEditable = false
        
        self.lineLayer.backgroundColor = ThemeColor.separatorColor.cgColor
        
        self.replyButton.title = "↩︎"
        self.replyButton.target = self
        self.replyButton.action = #selector(self.replyAction)
        
        self.favoriteButton.title = "★"
        self.favoriteButton.target = self
        self.favoriteButton.action = #selector(self.favoriteAction)
        
        // タイマーで5秒ごとに時刻を更新
        if #available(OSX 10.12, *) {
            self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] timer in
                if self?.superview == nil {
                    return
                }
                
                self?.refreshDate()
            })
        }
        
        /*
        // トゥートのタップジェスチャー
        //let tapStatusGesture = UITapGestureRecognizer(target: self, action: #selector(tapStatusAction))
        //self.statusLabel.addGestureRecognizer(tapStatusGesture)
        
        // 画像のタップジェスチャー
        for imageView in self.imageViews {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapStatusAction))
            imageView.addGestureRecognizer(tapGesture)
            imageView.isUserInteractionEnabled = true
        }
        
        // アイコンのタップジェスチャー
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAccountAction))
        self.iconView.addGestureRecognizer(tapGesture)
        self.iconView.isUserInteractionEnabled = true
        
        if SettingsData.isNameTappable {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAccountAction))
            self.nameLabel.addGestureRecognizer(tapGesture)
            self.nameLabel.isUserInteractionEnabled = true
        }*/
    }
    
    // リプライボタンをクリックした時の処理
    @objc func replyAction() {
        self.tableView?.selectedDate = Date()
        
        if let vc = TootViewController.get(accessToken: tableView?.accessToken), let view = vc.view as? TootView, view.textField.string.count > 0 {
            Dialog.show(message: I18n.get("ALERT_TEXT_EXISTS"))
        } else {
            // 返信先を設定
            TootView.inReplyToId = self.id
            
            // 公開範囲を低い方に合わせる
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // 公開範囲設定を変更
                if let visibility = self.visibility {
                    guard let view = TootViewController.get(accessToken: self.tableView?.accessToken)?.view as? TootView else { return }
                    
                    var mode = TimeLineViewCell.lowerVisibility(m1: SettingsData.ProtectMode(rawValue: visibility),
                                                                m2: SettingsData.protectMode)
                    if mode == SettingsData.ProtectMode.publicMode {
                        mode = SettingsData.ProtectMode.unlisted // inreplytoではLTLに流さない
                    }
                    view.protectMode = mode
                    view.refresh()
                }
            }
            
            // @IDを入力する
            DispatchQueue.main.async {
                if let vc = TootViewController.get(accessToken: self.tableView?.accessToken), let view = vc.view as? TootView {
                    view.textField.string = "@\(self.idLabel.stringValue) "
                }
            }
        }
    }
    
    // お気に入りボタンをタップした時の処理
    @objc func favoriteAction() {
        self.tableView?.selectedDate = Date()
        
        self.favoriteButton.isHidden = true
        
        tableView?.favoriteAction(id: self.id, isFaved: self.isFaved)
    }
    
    // トゥート部分をタップした時の処理
    @objc func tapStatusAction() {
        guard let url = URL(string: "https://\(self.tableView?.hostName ?? "")/api/v1/statuses/\(self.statusId!)") else { return }
        try? MastodonRequest.get(url: url, accessToken: self.tableView?.accessToken ?? "") { (data, response, error) in
            if let data = data {
                guard let responseJson = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)else { return }
                guard let json = responseJson as? [String: Any] else { return }
                var acct = ""
                let data = AnalyzeJson.analyzeJson(view: nil, model: nil, json: json, acct: &acct)
                
                DispatchQueue.main.async {
                    // トゥート詳細画面に移動
                    guard let mentionsData = self.tableView?.model.getMentionsData(data: data) else { return }
                    let viewController = TimeLineViewController(hostName: self.tableView?.hostName ?? "",
                                                                accessToken: self.tableView?.accessToken ?? "",
                                                                type: TimeLineViewController.TimeLineType.mentions,
                                                                option: nil,
                                                                mentions: (mentionsData, self.tableView?.accountList ?? [:]))
                    
                    let title = NSAttributedString(string: I18n.get("SUBTIMELINE_RELATIONS"))
                    let subTimeLineViewController = SubTimeLineViewController(name: title, icon: nil, timelineVC: viewController)
                    
                    var targetSubVC: SubViewController? = nil
                    for subVC in MainViewController.instance?.subVCList ?? [] {
                        if self.tableView?.hostName == subVC.tootVC.hostName && self.tableView?.accessToken == subVC.tootVC.accessToken {
                            targetSubVC = subVC
                            break
                        }
                    }
                    
                    // 複数のサブTLを開かないようにする
                    for subVC in targetSubVC?.children ?? [] {
                        if subVC is SubTimeLineViewController || subVC is FollowingViewController {
                            subVC.removeFromParent()
                            subVC.view.removeFromSuperview()
                        }
                    }
                    
                    subTimeLineViewController.view.frame = CGRect(x: self.tableView!.frame.width,
                                                                  y: 0,
                                                                  width: self.tableView!.frame.width,
                                                                  height: (targetSubVC?.view.frame.height ?? 100) - 22)
                    
                    subTimeLineViewController.showAnimation(parentVC: targetSubVC)
                }
            }
        }
    }
    
    // 日時表示を更新
    func refreshDate() {
        if SettingsData.useAbsoluteTime {
            refreshDateAbsolute()
        } else {
            refreshDateRelated()
        }
    }
    
    // 絶対時間で表示
    private static var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()
    private static var monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy-MM"
        return formatter
    }()
    private func refreshDateAbsolute() {
        let diffTime = Int(Date().timeIntervalSince(self.date))
        let dateStr = NotificationTableCell.dateFormatter.string(from: self.date)
        let nowDateStr = NotificationTableCell.dateFormatter.string(from: Date())
        if diffTime / 3600 < 18 || (dateStr == nowDateStr && diffTime / 3600 <= 24) {
            self.dateLabel.stringValue = NotificationTableCell.timeFormatter.string(from: self.date)
        }
        else if diffTime / 86400 < 365 {
            self.dateLabel.stringValue = dateStr
        }
        else {
            self.dateLabel.stringValue = NotificationTableCell.monthFormatter.string(from: self.date)
        }
    }
    
    // 相対時間で表示
    private func refreshDateRelated() {
        let diffTime = Int(Date().timeIntervalSince(self.date))
        if diffTime <= 0 {
            self.dateLabel.stringValue = I18n.get("DATETIME_NOW")
        }
        else if diffTime < 60 {
            self.dateLabel.stringValue = String(format: I18n.get("DATETIME_%D_SECS_AGO"), diffTime)
        }
        else if diffTime / 60 < 60 {
            self.dateLabel.stringValue = String(format: I18n.get("DATETIME_%D_MINS_AGO"), diffTime / 60)
        }
        else if diffTime / 3600 < 24 {
            if diffTime / 3600 < 10 && diffTime % 3600 >= 1800 {
                self.dateLabel.stringValue = String(format: I18n.get("DATETIME_%D_HOURS_HALF_AGO"), diffTime / 3600)
            } else {
                self.dateLabel.stringValue = String(format: I18n.get("DATETIME_%D_HOURS_AGO"), diffTime / 3600)
            }
        }
        else if diffTime / 86400 < 365 {
            self.dateLabel.stringValue = String(format: I18n.get("DATETIME_%D_DAYS_AGO"), diffTime / 86400)
        }
        else {
            self.dateLabel.stringValue = String(format: I18n.get("DATETIME_%D_YEARS_AGO"), diffTime / 86400 / 365)
        }
    }
    
    override func layout() {
        let screenBounds = tableView?.bounds ?? self.bounds
        
        self.lineLayer.frame = CGRect(x: 0,
                                      y: 0,
                                      width: screenBounds.width,
                                      height: 1 / (NSScreen.main?.backingScaleFactor ?? 1))
        
        self.iconView.frame = CGRect(x: 8,
                                     y: 10,
                                     width: SettingsData.iconSize,
                                     height: SettingsData.iconSize)
        
        let left = SettingsData.iconSize + 16
        self.nameLabel.frame = CGRect(x: left,
                                      y: 7,
                                      width: self.nameLabel.frame.width,
                                      height: SettingsData.fontSize + 1)
        
        let idWidth = screenBounds.width - (self.nameLabel.frame.width + left + 45 + 5)
        self.idLabel.frame = CGRect(x: left + self.nameLabel.frame.width + 5,
                                    y: 7,
                                    width: idWidth,
                                    height: SettingsData.fontSize)
        
        self.dateLabel.frame = CGRect(x: screenBounds.width - 50,
                                      y: 7,
                                      width: 45,
                                      height: SettingsData.fontSize)
        
        self.notificationLabel.frame = CGRect(x: left,
                                              y: 10 + SettingsData.fontSize,
                                              width: screenBounds.width - left,
                                              height: SettingsData.fontSize + 2)
        
        self.statusLabel.frame.size.width = screenBounds.width - left - 5
        self.statusLabel.sizeToFit()
        self.statusLabel.frame = CGRect(x: left,
                                        y: self.notificationLabel.frame.maxY + 6,
                                        width: self.statusLabel.frame.width,
                                        height: self.statusLabel.frame.height)
        
        var top = self.statusLabel.frame.maxY + 5
        for imageView in self.imageViews {
            if imageView.image != nil {
                imageView.frame = CGRect(x: left + 5,
                                         y: top,
                                         width: screenBounds.width - left - 10,
                                         height: 60)
                top = imageView.frame.maxY + 5
            }
        }
        
        self.replyButton.frame = CGRect(x: left + 10,
                                        y: top + 3,
                                        width: 32,
                                        height: 32)
        
        self.favoriteButton.frame = CGRect(x: left + 100,
                                           y: top + 3,
                                           width: 32,
                                           height: 32)
    }
}
