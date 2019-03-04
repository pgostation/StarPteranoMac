//
//  AllListsViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/26.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class AllListsViewController: NSViewController {
    let hostName: String
    let accessToken: String
    let accountId: String
    
    init(accountId: String, hostName: String, accessToken: String) {
        self.hostName = hostName
        self.accessToken = accessToken
        self.accountId = accountId
        
        super.init(nibName: nil, bundle: nil)
        
        getListData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.getAccountListData()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = AllListsView(accountId: self.accountId, hostName: hostName, accessToken: accessToken)
        self.view = view
    }
    
    private func getListData() {
        let urlStr = "https://\(hostName)/api/v1/lists"
        
        guard let url = URL(string: urlStr) else { return }
        try? MastodonRequest.get(url: url, accessToken: accessToken) { (data, response, error) in
            if let data = data {
                do {
                    guard let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]] else { return }
                    
                    var list: [AnalyzeJson.ListData] = []
                    for json in responseJson {
                        let data = AnalyzeJson.ListData(id: json["id"] as? String,
                                                        title: json["title"] as? String)
                        list.append(data)
                    }
                    
                    list.sort(by: { (data1, data2) -> Bool in
                        return (data1.title ?? "") < (data2.title ?? "")
                    })
                    
                    DispatchQueue.main.async {
                        if let view = self.view as? AllListsView {
                            view.tableView.model.list = list
                            view.tableView.reloadData()
                        }
                    }
                } catch { }
            }
        }
    }
    
    private func getAccountListData() {
        let urlStr = "https://\(hostName)/api/v1/accounts/\(self.accountId)/lists"
        
        guard let url = URL(string: urlStr) else { return }
        try? MastodonRequest.get(url: url, accessToken: accessToken) { (data, response, error) in
            if let data = data {
                do {
                    guard let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]] else { return }
                    
                    var list: [AnalyzeJson.ListData] = []
                    for json in responseJson {
                        let data = AnalyzeJson.ListData(id: json["id"] as? String,
                                                        title: json["title"] as? String)
                        list.append(data)
                    }
                    
                    DispatchQueue.main.async {
                        if let view = self.view as? AllListsView {
                            view.tableView.model.accountList = list
                            view.tableView.reloadData()
                        }
                    }
                } catch { }
            }
        }
    }
}

private final class AllListsView: NSView {
    let scrollView = NSScrollView()
    let tableView: AllListsTableView
    
    init(accountId: String, hostName: String, accessToken: String) {
        self.tableView = AllListsTableView(accountId: accountId, hostName: hostName, accessToken: accessToken)
        
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        
        self.addSubview(scrollView)
        
        scrollView.documentView = tableView
        
        self.wantsLayer = true
        self.layer?.backgroundColor = ThemeColor.cellBgColor.cgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layout() {
        scrollView.frame = self.frame
    }
}

final class AllListsTableView: NSTableView {
    let model: AllListsTableModel
    let hostName: String
    let accessToken: String
    
    init(accountId: String, hostName: String, accessToken: String) {
        self.hostName = hostName
        self.accessToken = accessToken
        self.model = AllListsTableModel(accountId: accountId)
        
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        
        self.delegate = model
        self.dataSource = model
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: ""))
        column.width = 200
        self.addTableColumn(column)
        
        self.rowHeight = 52
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class AllListsTableModel: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    private let accountId: String
    var list: [AnalyzeJson.ListData] = []
    var accountList: [AnalyzeJson.ListData]? = nil // アカウントが属しているリスト
    
    init(accountId: String) {
        self.accountId = accountId
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return list.count + 2
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if row >= list.count {
            let cell = NSView()
            return cell
        }
        
        let cell = AllListsTableCell(tableView: tableView as! AllListsTableView)
        
        let data = list[row]
        
        cell.accountId = self.accountId
        cell.listId = data.id ?? ""
        
        cell.nameLabel.stringValue = data.title ?? ""
        
        // ボタンの表示/非表示
        cell.addButton.isHidden = true
        cell.removeButton.isHidden = true
        if let accountList = self.accountList {
            var flag = false
            for hasAccount in accountList {
                if data.id == hasAccount.id {
                    flag = true
                    break
                }
            }
            
            if flag {
                cell.removeButton.isHidden = false
            } else {
                cell.addButton.isHidden = false
            }
        }
        
        return cell
    }
}

private final class AllListsTableCell: NSView {
    var listId = ""
    var accountId = ""
    
    // 基本ビュー
    let lineLayer = CALayer()
    let nameLabel = NSTextField()
    
    let addButton = NSButton()
    let removeButton = NSButton()
    
    private weak var tableView: AllListsTableView?
    
    init(tableView: AllListsTableView) {
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        
        self.tableView = tableView
        
        self.addSubview(nameLabel)
        self.addSubview(addButton)
        self.addSubview(removeButton)
        self.layer?.addSublayer(self.lineLayer)
        
        addButton.target = self
        addButton.action = #selector(addButtonAction)
        removeButton.target = self
        removeButton.action = #selector(removeButtonAction)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.nameLabel.textColor = ThemeColor.contrastColor
        self.nameLabel.font = NSFont.systemFont(ofSize: SettingsData.fontSize + 2)
        self.nameLabel.isBordered = false
        self.nameLabel.isEditable = false
        self.nameLabel.isSelectable = false
        self.nameLabel.drawsBackground = false
        
        self.lineLayer.backgroundColor = ThemeColor.separatorColor.cgColor
        
        self.addButton.title = "+"
        
        self.removeButton.title = "-"
    }
    
    // リストに追加
    @objc func addButtonAction() {
        guard let tableView = self.tableView else { return }
        
        let url = URL(string: "https://\(tableView.hostName)/api/v1/lists/\(self.listId)/accounts")!
        
        try? MastodonRequest.post(url: url, accessToken: tableView.accessToken, body: ["account_ids": ["\(self.accountId)"]]) { (data, response, error) in
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                DispatchQueue.main.async {
                    self.removeButton.isHidden = false
                    self.addButton.isHidden = true
                }
            }
        }
    }
    
    // リストから削除
    @objc func removeButtonAction() {
        guard let tableView = self.tableView else { return }
        
        let url = URL(string: "https://\(tableView.hostName)/api/v1/lists/\(self.listId)/accounts")!
        
        try? MastodonRequest.delete(url: url, accessToken: tableView.accessToken, body: ["account_ids": ["\(self.accountId)"]]) { (data, response, error) in
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                DispatchQueue.main.async {
                    self.removeButton.isHidden = true
                    self.addButton.isHidden = false
                }
            }
        }
    }
    
    override func layout() {
        let screenBounds = self.superview?.frame ?? self.frame
        
        self.lineLayer.frame = CGRect(x: 0,
                                      y: 0,
                                      width: screenBounds.width,
                                      height: 1 / (NSScreen.main?.backingScaleFactor ?? 1))
        
        self.nameLabel.frame = CGRect(x: 20,
                                      y: 52 / 2 - (SettingsData.fontSize + 2) / 2,
                                      width: screenBounds.width - 20 - 60,
                                      height: SettingsData.fontSize * 1.5 + 2)
        
        self.addButton.frame = CGRect(x: screenBounds.width - 60,
                                      y: 8,
                                      width: 40,
                                      height: 40)
        
        self.removeButton.frame = CGRect(x: screenBounds.width - 60,
                                         y: 8,
                                         width: 40,
                                         height: 40)
    }
}
