//
//  SearchViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/05.
//  Copyright © 2019 pgostation. All rights reserved.
//

// 検索画面 (ユーザー, ハッシュタグ)

import Cocoa

final class SearchViewController: NSViewController {
    let hostName: String
    let accessToken: String
    let type: TimeLineViewController.TimeLineType
    let option: String?
    
    init(hostName: String, accessToken: String, type: TimeLineViewController.TimeLineType, option: String?) {
        self.hostName = hostName
        self.accessToken = accessToken
        self.type = type
        self.option = option
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = SearchView(hostName: hostName, accessToken: accessToken)
        self.view = view
    }
}

private final class SearchView: NSView, NSTextFieldDelegate {
    let hostName: String
    let accessToken: String
    let segmentControl = NSSegmentedControl()
    let textField = NSTextField()
    var tagTableView: TimeLineView?
    let scrollView = NSScrollView()
    var accountTableView: FollowingTableView?
    
    init(hostName: String, accessToken: String) {
        self.hostName = hostName
        self.accessToken = accessToken
        
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        
        self.addSubview(segmentControl)
        self.addSubview(textField)
        self.addSubview(scrollView)
        
        self.accountTableView = FollowingTableView(hostName: hostName, accessToken: accessToken, type: "")
        
        scrollView.documentView = accountTableView
        
        setProperties()
        
        DispatchQueue.main.async {
            self.needsLayout = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        self.wantsLayer = true
        self.layer?.backgroundColor = ThemeColor.viewBgColor.cgColor
        
        // アカウント/トゥートの切り替え
        segmentControl.segmentCount = 2
        segmentControl.setLabel(I18n.get("SEARCH_SEG_TAG"), forSegment: 0)
        segmentControl.setLabel(I18n.get("SEARCH_SEG_ACCOUNT"), forSegment: 1)
        segmentControl.selectedSegment = 0
        
        // 検索文字列入力フィールド
        textField.backgroundColor = ThemeColor.cellBgColor
        textField.textColor = ThemeColor.idColor
        textField.layer?.borderWidth = 1
        textField.layer?.borderColor = ThemeColor.dateColor.cgColor
        textField.delegate = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.textField.becomeFirstResponder()
        }
    }
    
    override func layout() {
        let screenBounds = self.superview?.frame ?? self.frame
        
        self.frame = screenBounds
        
        segmentControl.frame = CGRect(x: screenBounds.width / 2 - 160 / 2,
                                      y: screenBounds.height - 25,
                                      width: 160,
                                      height: 20)
        
        textField.frame = CGRect(x: 5,
                                 y: screenBounds.height - 50,
                                 width: screenBounds.width - 10,
                                 height: 25)
        
        scrollView.frame = CGRect(x: 0,
                                  y: 0,
                                  width: screenBounds.width,
                                  height: textField.frame.minY)
    }
    
    // テキストフィールドでリターン押した時の処理
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        let text = self.textField.stringValue
        
        textField.resignFirstResponder()
        
        if segmentControl.selectedSegment == 0 {
            searchTag(text: text)
            
            self.tagTableView?.isHidden = false
            self.accountTableView?.isHidden = true
        } else {
            searchAccounts(text: text)
            
            self.scrollView.documentView = self.accountTableView
            self.tagTableView?.isHidden = true
            self.accountTableView?.isHidden = false
        }
        
        return true
    }
    
    // タグ検索
    private func searchTag(text: String) {
        self.tagTableView = TimeLineView(hostName: hostName, accessToken: accessToken, type: .federationTag, option: text, mentions: nil)
        self.scrollView.documentView = self.tagTableView
        self.needsLayout = true
    }
    
    // アカウント検索
    private var prevLinkStr: String?
    private func searchAccounts(text: String) {
        guard let url = URL(string: "https://\(hostName)/api/v1/accounts/search?q=\(text.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? "")") else { return }
        
        try? MastodonRequest.get(url: url, accessToken: accessToken) { (data, response, error) in
            
            guard let data = data else { return }
            
            do {
                guard let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Array<AnyObject> else { return }
                
                var list: [AnalyzeJson.AccountData] = []
                for json in responseJson {
                    if let accountJson = json as? [String: Any] {
                        let accountData = AnalyzeJson.analyzeAccountJson(account: accountJson)
                        list.append(accountData)
                    }
                }
                
                DispatchQueue.main.async {
                    self.accountTableView?.model.clear()
                    if self.accountTableView?.model.change(addList: list) == false {
                        // 重複したデータを受信したら、終了
                        self.accountTableView?.model.showAutoPegerizeCell = false
                    }
                    self.accountTableView?.reloadData()
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
                        if let data = data {
                            do {
                                guard let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]] else { return }
                                
                                for json in responseJson {
                                    if let id = json["id"] as? String {
                                        self.accountTableView?.model.relationshipList.updateValue(json, forKey: id)
                                    }
                                }
                                
                                DispatchQueue.main.async {
                                    self.accountTableView?.reloadData()
                                }
                            } catch { }
                        }
                    }
                }
            } catch { }
            
            if let response = response as? HTTPURLResponse {
                if let linkStr = response.allHeaderFields["Link"] as? String {
                    if linkStr.contains("rel=\"prev\"") {
                        if let prefix = linkStr.split(separator: ">").first {
                            self.prevLinkStr = String(prefix.suffix(prefix.count - 1))
                        }
                    } else {
                        self.accountTableView?.model.showAutoPegerizeCell = false
                    }
                } else {
                    self.accountTableView?.model.showAutoPegerizeCell = false
                }
            }
        }
    }
}
