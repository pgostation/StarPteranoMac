//
//  FollowingViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/26.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class FollowingViewController: NSViewController {
    private let hostName: String
    private let accessToken: String
    private let type: String
    private var prevLinkStr: String?
    
    init(type: String, hostName: String, accessToken: String) {
        self.hostName = hostName
        self.accessToken = accessToken
        self.type = type
        
        super.init(nibName: nil, bundle: nil)
        
        getNextData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = FollowingView(hostName: hostName, accessToken: accessToken, type: type)
        self.view = view
        
        view.tableView.model.viewController = self
        
        view.closeButton.target = self
        view.closeButton.action = #selector(self.closeAction)
    }
    
    func getNextData() {
        let urlStr: String
        if let prevLinkStr = self.prevLinkStr {
            urlStr = prevLinkStr
        } else {
            urlStr = "https://\(hostName)/api/v1/\(type)"
        }
        
        guard let url = URL(string: urlStr) else { return }
        try? MastodonRequest.get(url: url, accessToken: accessToken) { (data, response, error) in
            if let data = data {
                do {
                    guard let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Array<AnyObject> else { return }
                    
                    var list: [AnalyzeJson.AccountData] = []
                    for json in responseJson {
                        if let accountJson = json as? [String: Any] {
                            let accountData = AnalyzeJson.analyzeAccountJson(account: accountJson)
                            list.append(accountData)
                        }
                    }
                    
                    if let view = self.view as? FollowingView {
                        DispatchQueue.main.async {
                            if !view.tableView.model.change(addList: list) {
                                // 重複したデータを受信したら、終了
                                if let view = self.view as? FollowingView {
                                    view.tableView.model.showAutoPegerizeCell = false
                                }
                            }
                            view.tableView.reloadData()
                        }
                    }
                    
                    // フォロー関係を取得
                    var idStr = ""
                    for accountData in list {
                        if let id = accountData.id {
                            if idStr != "" {
                                idStr += "&"
                            }
                            idStr += "id[]=" + id
                        }
                    }
                    if let url = URL(string: "https://\(self.hostName)/api/v1/accounts/relationships/?\(idStr)") {
                        try? MastodonRequest.get(url: url, accessToken: self.accessToken) { (data, response, error) in
                            guard let view = self.view as? FollowingView else { return }
                            
                            if let data = data {
                                do {
                                    guard let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]] else { return }
                                    
                                    for json in responseJson {
                                        if let id = json["id"] as? String {
                                            view.tableView.model.relationshipList.updateValue(json, forKey: id)
                                        }
                                    }
                                    
                                    DispatchQueue.main.async {
                                        view.tableView.reloadData()
                                    }
                                } catch { }
                            }
                        }
                    }
                } catch { }
            }
            
            if let response = response as? HTTPURLResponse {
                if let linkStr = response.allHeaderFields["Link"] as? String {
                    if linkStr.contains("rel=\"prev\"") {
                        if let prefix = linkStr.split(separator: ">").first {
                            self.prevLinkStr = String(prefix.suffix(prefix.count - 1))
                        }
                    } else {
                        if let view = self.view as? FollowingView {
                            view.tableView.model.showAutoPegerizeCell = false
                        }
                    }
                } else {
                    if let view = self.view as? FollowingView {
                        view.tableView.model.showAutoPegerizeCell = false
                    }
                }
            }
        }
    }
    
    @objc func closeAction() {
        self.removeFromParent()
        self.view.removeFromSuperview()
    }
}

private final class FollowingView: NSView {
    let scrollView = NSScrollView()
    let tableView: FollowingTableView
    let closeButton = NSButton()
    
    init(hostName: String, accessToken: String, type: String) {
        self.tableView = FollowingTableView(hostName: hostName, accessToken: accessToken, type: type)
        
        super.init(frame: NSRect(x: 0, y: 0, width: 10, height: 10))
        
        self.addSubview(scrollView)
        self.addSubview(closeButton)
        
        scrollView.documentView = tableView
        
        self.wantsLayer = true
        self.layer?.backgroundColor = ThemeColor.cellBgColor.cgColor
        
        // 閉じるボタン
        closeButton.title = "×"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layout() {
        if let superview = self.superview {
            let width = min(400, superview.frame.width)
            self.frame = NSRect(x: superview.frame.width - width,
                                y: 0,
                                width: width,
                                height: superview.frame.height)
            
            self.scrollView.frame.size = NSSize(width: self.frame.size.width,
                                                height: self.frame.size.height - 20)
            tableView.frame.size.width = self.frame.size.width
        }
        
        closeButton.frame = CGRect(x: 0,
                                   y: self.frame.height - 25,
                                   width: 25,
                                   height: 25)
    }
}

final class FollowingTableView: NSTableView {
    let model: FollowingTableModel
    
    init(hostName: String, accessToken: String, type: String) {
        self.model = FollowingTableModel(hostName: hostName, accessToken: accessToken)
        
        super.init(frame: NSRect(x: 0, y: 0, width: 10, height: 10))
        
        self.delegate = model
        self.dataSource = model
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: ""))
        column.title = String(type.split(separator: "/").last ?? "")
        column.width = 200
        self.addTableColumn(column)
        
        self.rowHeight = 56
        
        self.backgroundColor = ThemeColor.cellBgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class FollowingTableModel: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    let hostName: String
    let accessToken: String
    var showAutoPegerizeCell = true
    private var list: [AnalyzeJson.AccountData] = []
    var relationshipList: [String: [String: Any]] = [:]
    weak var viewController: FollowingViewController?
    
    init(hostName: String, accessToken: String) {
        self.hostName = hostName
        self.accessToken = accessToken
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func change(addList: [AnalyzeJson.AccountData]) -> Bool {
        if let first = addList.first {
            for data in self.list {
                if data.id == first.id {
                    return false
                }
            }
        }
        self.list += addList
        
        return true
    }
    
    func clear() {
        self.list = []
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return list.count + (showAutoPegerizeCell ? 1 : 0)
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if row >= list.count {
            let cell = NSView(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
            cell.layer?.backgroundColor = ThemeColor.cellBgColor.cgColor
            
            if let vc = self.viewController {
                vc.getNextData()
            }
            
            return cell
        }
        
        let cell = FollowingTableCell(hostName: hostName, accessToken: accessToken)
        
        let data = list[row]
        
        cell.accountId = data.acct ?? ""
        cell.accountData = data
        
        cell.iconView.image = nil
        ImageCache.image(urlStr: data.avatar_static, isTemp: false, isSmall: true) { image, localUrl  in
            if cell.accountId == data.acct {
                cell.iconView.image = image
            }
        }
        
        cell.nameLabel.attributedStringValue = DecodeToot.decodeName(name: data.display_name, emojis: data.emojis, textField: cell.nameLabel, callback: {
            if cell.accountId == data.acct {
                cell.nameLabel.attributedStringValue = DecodeToot.decodeName(name: data.display_name, emojis: data.emojis, textField: cell.nameLabel, callback: nil)
                cell.nameLabel.sizeToFit()
                cell.needsLayout = true
            }
        })
        cell.nameLabel.sizeToFit()
        
        cell.idLabel.stringValue = list[row].acct ?? ""
        
        cell.followButton.alphaValue = 0
        cell.followButton.target = nil
        
        if let relationShipJson = relationshipList[data.id ?? ""] {
            cell.followButton.alphaValue = 1
            if relationShipJson["following"] as? Int == 1 {
                cell.followButton.title  = "☑️"
                cell.followButton.font = NSFont.boldSystemFont(ofSize: 24)
                cell.followButton.layer?.backgroundColor = NSColor.blue.withAlphaComponent(0.5).cgColor
                cell.followButton.target = cell
                cell.followButton.action = #selector(cell.unfollowAction)
            } else if relationShipJson["requested"] as? Int == 1 {
                cell.followButton.title = "⌛️"
                cell.followButton.font = NSFont.boldSystemFont(ofSize: 24)
                cell.followButton.layer?.backgroundColor = NSColor.gray.cgColor
            } else {
                cell.followButton.title = "+"
                cell.followButton.font = NSFont.boldSystemFont(ofSize: 32)
                cell.followButton.layer?.backgroundColor = NSColor.gray.cgColor
                cell.followButton.target = cell
                cell.followButton.action = #selector(cell.followAction)
            }
        }
        
        return cell
    }
}

private final class FollowingTableCell: NSView {
    let hostName: String
    let accessToken: String
    var accountId = ""
    
    // 基本ビュー
    let lineLayer = CALayer()
    let iconView = NSImageView()
    let iconCoverView = NSButton()
    let nameLabel = MyTextField()
    let idLabel = MyTextField()
    
    var followButton = NSButton()
    
    var accountData: AnalyzeJson.AccountData?
    
    init(hostName: String, accessToken: String) {
        self.hostName = hostName
        self.accessToken = accessToken
        
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        
        self.addSubview(iconView)
        self.addSubview(iconCoverView)
        self.addSubview(nameLabel)
        self.addSubview(idLabel)
        self.addSubview(followButton)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        // 固定プロパティは初期化時に設定
        self.layer?.backgroundColor = ThemeColor.cellBgColor.cgColor
        
        self.iconView.layer?.cornerRadius = 5
        
        self.iconCoverView.isTransparent = true
        
        self.nameLabel.textColor = ThemeColor.nameColor
        self.nameLabel.font = NSFont.boldSystemFont(ofSize: SettingsData.fontSize)
        self.nameLabel.layer?.backgroundColor = ThemeColor.cellBgColor.cgColor
        self.nameLabel.isEditable = false
        self.nameLabel.isSelectable = false
        self.nameLabel.drawsBackground = false
        self.nameLabel.isBordered = false
        
        self.idLabel.textColor = ThemeColor.idColor
        self.idLabel.font = NSFont.systemFont(ofSize: SettingsData.fontSize - 2)
        self.idLabel.layer?.backgroundColor = ThemeColor.cellBgColor.cgColor
        self.idLabel.isEditable = false
        self.idLabel.isSelectable = false
        self.idLabel.drawsBackground = false
        self.idLabel.isBordered = false
        
        self.lineLayer.backgroundColor = ThemeColor.separatorColor.cgColor
        self.lineLayer.isOpaque = true
        
        // アイコンのタップジェスチャー
        iconCoverView.target = self
        iconCoverView.action = #selector(tapAccountAction)
        
        self.followButton.layer?.backgroundColor = ThemeColor.detailButtonsColor.cgColor
        self.followButton.layer?.cornerRadius = 8
        self.followButton.alphaValue = 0
    }
    
    // アイコンをタップした時の処理
    private static var doubleTapFlag = false
    @objc func tapAccountAction() {
        if FollowingTableCell.doubleTapFlag { return }
        FollowingTableCell.doubleTapFlag = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            FollowingTableCell.doubleTapFlag = false
        }
        
        let accountTimeLineViewController = TimeLineViewController(hostName: hostName, accessToken: accessToken, type: TimeLineViewController.TimeLineType.user, option: accountData?.id ?? "")
        if let timelineView = accountTimeLineViewController.view as? TimeLineView, let accountData = self.accountData {
            timelineView.accountList.updateValue(accountData, forKey: accountData.id ?? "")
        }
        
        let subTimeLineViewController = SubTimeLineViewController(name: self.nameLabel.attributedStringValue, icon: self.iconView.image, timelineVC: accountTimeLineViewController)
        
        var targetSubVC: SubViewController? = nil
        for subVC in MainViewController.instance?.subVCList ?? [] {
            if self.hostName == subVC.tootVC.hostName && self.accessToken == subVC.tootVC.accessToken {
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
        
        targetSubVC?.addChild(subTimeLineViewController)
        targetSubVC?.view.addSubview(subTimeLineViewController.view)
        
        subTimeLineViewController.view.frame = CGRect(x: self.frame.width,
                                                      y: 0,
                                                      width: self.frame.width,
                                                      height: (targetSubVC?.view.frame.height ?? 100) - 22)
        
        
        subTimeLineViewController.showAnimation(parentVC: targetSubVC)
    }
    
    @objc func followAction() {
        ProfileAction.follow(id: self.accountData?.id ?? "", hostName: hostName, accessToken: accessToken)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let url = URL(string: "https://\(self.hostName)/api/v1/accounts/relationships/?id[]=\(self.accountData?.id ?? "")") {
                try? MastodonRequest.get(url: url, accessToken: self.accessToken) { (data, response, error) in
                    DispatchQueue.main.async {
                        guard let view = self.superview as? FollowingTableView else { return }
                        
                        if let data = data {
                            do {
                                guard let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]] else { return }
                                
                                if let id = responseJson.first?["id"] as? String {
                                    view.model.relationshipList.updateValue(responseJson.first!, forKey: id)
                                }
                                
                                DispatchQueue.main.async {
                                    view.reloadData()
                                }
                            } catch { }
                        }
                    }
                }
            }
        }
    }
    
    @objc func unfollowAction() {
        Dialog.show(message: I18n.get("ALERT_UNFOLLOW"),
                    okName: I18n.get("ACTION_UNFOLLOW"),
                    cancelName: I18n.get("BUTTON_CANCEL"),
                    callback: { result in
                        ProfileAction.unfollow(id: self.accountData?.id ?? "", hostName: self.hostName, accessToken: self.accessToken)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            if let url = URL(string: "https://\(self.hostName)/api/v1/accounts/relationships/?id[]=\(self.accountData?.id ?? "")") {
                                try? MastodonRequest.get(url: url, accessToken: self.accessToken) { (data, response, error) in
                                    DispatchQueue.main.async {
                                        guard let view = self.superview as? FollowingTableView else { return }
                                        
                                        if let data = data {
                                            do {
                                                guard let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]] else { return }
                                                
                                                if let id = responseJson.first?["id"] as? String {
                                                    view.model.relationshipList.updateValue(responseJson.first!, forKey: id)
                                                }
                                                
                                                DispatchQueue.main.async {
                                                    view.reloadData()
                                                }
                                            } catch { }
                                        }
                                    }
                                }
                            }
                        }
        })
    }
    
    override func layout() {
        guard let screenBounds = self.superview?.bounds else { return }
        
        self.lineLayer.frame = CGRect(x: 0,
                                      y: 0,
                                      width: screenBounds.width,
                                      height: 1 / (NSScreen.main?.backingScaleFactor ?? 1))
        
        self.iconView.frame = CGRect(x: 6,
                                     y: 8,
                                     width: 40,
                                     height: 40)
        
        self.iconCoverView.frame = self.iconView.frame
        
        self.nameLabel.frame = CGRect(x: 50,
                                      y: 28,
                                      width: self.nameLabel.frame.width,
                                      height: (SettingsData.fontSize + 1) * 1.5)
        
        self.idLabel.frame = CGRect(x: 50,
                                    y: 0,
                                    width: screenBounds.width - 110,
                                    height: SettingsData.fontSize * 1.5)
        
        self.followButton.frame = CGRect(x: screenBounds.width - 60,
                                         y: 8,
                                         width: 40,
                                         height: 40)
    }
}
