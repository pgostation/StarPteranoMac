//
//  ListPopUp.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/03.
//  Copyright © 2019 pgostation. All rights reserved.
//

// リスト選択用ポップアップを表示するビュー

import Cocoa

final class ListPopUp: NSView {
    let hostName: String
    let accessToken: String
    let popUp = NSPopUpButton()
    
    init(hostName: String, accessToken: String) {
        self.hostName = hostName
        self.accessToken = accessToken
        
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        
        self.addSubview(popUp)
        
        getLists(force: false)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // リスト一覧を取得
    func getLists(force: Bool = false) {
        // キャッシュがあれば使う
        if !force, ListData.getCache(accessToken: accessToken) != nil {
            DispatchQueue.main.async {
                self.refresh()
            }
            return
        }
        
        guard let url = URL(string: "https://\(hostName)/api/v1/lists") else { return }
        
        try? MastodonRequest.get(url: url, accessToken: accessToken) { [weak self] (data, response, error) in
            
            if let data = data {
                do {
                    if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: AnyObject]] {
                        var list: [AnalyzeJson.ListData] = []
                        for listJson in responseJson {
                            let data = AnalyzeJson.ListData(id: listJson["id"] as? String,
                                                            title: listJson["title"] as? String)
                            list.append(data)
                        }
                        
                        list.sort(by: { (data1, data2) -> Bool in
                            return (data1.title ?? "") < (data2.title ?? "")
                        })
                        
                        if let accessToken = self?.accessToken {
                            ListData.setCache(accessToken: accessToken, value: list)
                        }
                        
                        DispatchQueue.main.async {
                            self?.refresh()
                        }
                    }
                } catch {
                    
                }
            }
        }
    }
    
    // ポップアップの内容を更新
    private func refresh() {
        let listData = ListData.getCache(accessToken: accessToken)
        
        let menu = NSMenu(title: "")
        
        for data in listData ?? [] {
            let item = NSMenuItem(title: data.title ?? "",
                                  action: #selector(menuAction(_:)),
                                  keyEquivalent: "")
            menu.addItem(item)
            
            if SettingsData.selectedListId(accessToken: accessToken, index: 0) == data.id {
                popUp.select(item)
            }
            
            item.target = self
        }
        
        popUp.menu = menu
        
        // 何も選ばれていない場合は最初のものを選択する
        if SettingsData.selectedListId(accessToken: accessToken, index: 0) == nil, let listId = listData?.first?.id {
            SettingsData.selectListId(accessToken: accessToken, index: 0, listId: listId)
        }
        
        // 初期状態での選択内容を通知する
        if let listId = SettingsData.selectedListId(accessToken: accessToken, index: 0) {
            select(listId: listId)
        }
    }
    
    // ポップアップ選択時の処理
    @objc func menuAction(_ sender: NSMenuItem) {
        let selectedTitle = sender.title
        
        let listData = ListData.getCache(accessToken: accessToken)
        
        for data in listData ?? [] {
            if selectedTitle == data.title {
                select(listId: data.id)
                
                break
            }
        }
    }
    
    private func select(listId: String?) {
        // 選択したリストIDを伝える
        let key = TimeLineViewManager.makeKey(hostName: hostName, accessToken: accessToken, type: SettingsData.TLMode.list)
        let vc = TimeLineViewManager.get(key: key)
        if let vc = vc as? TimeLineViewController {
            vc.selectList(listId: listId)
        }
    }
    
    // レイアウト
    override func layout() {
        self.popUp.frame = NSRect(x: 10,
                                  y: 2,
                                  width: self.frame.width - 20,
                                  height: 26)
    }
}
