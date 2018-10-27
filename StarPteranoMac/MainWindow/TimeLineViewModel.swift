//
//  TimeLineViewModel.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class TimeLineViewModel: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    private var list: [AnalyzeJson.ContentData] = []
    private var accountList: [String: AnalyzeJson.AccountData] = [:]
    private var accountIdDict: [String: String] = [:]
    var showAutoPagerizeCell = true // 過去遡り用セルを表示するかどうか
    var selectedRow: Int? = nil
    private var selectedAccountId: String?
    private var inReplyToTootId: String?
    private var inReplyToAccountId: String?
    var isDetailTimeline = false
    private var cellCount = 0 // 現在のセル数
    private var animationCellsCount = 0
    var inAnimating = false
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 一番新しいトゥートのID
    func getFirstTootId() -> String? {
        for data in list {
            if !data.isMerge {
                return data.id
            }
        }
        return nil
    }
    
    // 一番古いトゥートのID
    func getLastTootId() -> String? {
        for data in list.reversed() {
            if !data.isMerge {
                return data.id
            }
        }
        return nil
    }
    
    // 一番古いトゥートのin_reply_to_id
    func getLastInReplyToId() -> String? {
        return list.last?.in_reply_to_id
    }
    
    //
    func clear() {
        self.list = []
        self.showAutoPagerizeCell = true
        clearSelection()
    }
    
    //
    func clearSelection() {
        self.selectedRow = nil
        self.selectedAccountId = nil
        self.inReplyToTootId = nil
        self.inReplyToAccountId = nil
    }
    
    // トゥートの追加
    func change(tableView: TimeLineView, addList: [AnalyzeJson.ContentData], accountList: [String: AnalyzeJson.AccountData], isStreaming: Bool = false, isNewRefresh: Bool = false, isBoosted: Bool = false) {
        
        // ミュートフラグの立っているものは削除しておく
        var addList2 = addList
        if tableView.type == .home || tableView.type == .local || tableView.type == .federation {
            for (index, data) in addList2.enumerated().reversed() {
                if data.muted == 1 {
                    addList2.remove(at: index)
                }
            }
        }
        
        DispatchQueue.main.async {
            // アカウント情報を更新
            for account in accountList {
                self.accountList.updateValue(account.value, forKey: account.key)
            }
            
            // アカウントID情報を更新
            for data in addList {
                if let mentions = data.mentions {
                    for mention in mentions {
                        if let acct = mention.acct, let id = mention.id {
                            self.accountIdDict.updateValue(id, forKey: acct)
                        }
                    }
                }
            }
            
            if self.list.count == 0 {
                self.list = addList2
                if isStreaming {
                    tableView.reloadData()
                }
            } else if let firstDate1 = self.list.first?.created_at, let firstDate2 = addList2.first?.created_at, let lastDate1 = self.list.last?.created_at, let lastDate2 = addList2.last?.created_at {
                
                if addList2.count == 1 && isBoosted {
                    // 自分でブーストした場合、上に持ってくるとおかしくなるので
                    // すでにあるデータを更新する
                    if let newContent = addList2.first {
                        var index = 0
                        while index < self.list.count {
                            let listData = self.list[index]
                            if listData.id == newContent.id || listData.id == newContent.reblog_id || listData.reblog_id == newContent.reblog_id || listData.reblog_id == newContent.id {
                                self.list[index] = newContent
                                break
                            }
                            // タイムラインの方が古いので、その前に追加する
                            if (listData.id ?? "") < (newContent.reblog_id ?? "") {
                                self.list.insert(newContent, at: index)
                                
                                // 選択位置がずれないようにする
                                if self.selectedRow != nil && index < self.selectedRow! {
                                    self.selectedRow = self.selectedRow! + 1
                                }
                                break
                            }
                            index += 1
                        }
                    }
                } else if lastDate1 > firstDate2 {
                    // 後に付ければ良い
                    self.list = self.list + addList2
                    
                    if self.list.count > 5000 {
                        // 5000トゥートを超えると削除する
                        self.list.removeFirst(self.list.count - 5000)
                    }
                    if isStreaming {
                        tableView.reloadData()
                    }
                } else if lastDate2 > firstDate1 {
                    if self.list.count > 5000 && !isStreaming {
                        // 5000トゥートを超えると流石に削除する
                        self.list.removeLast(self.list.count - 5000)
                    }
                    
                    if isStreaming {
                        self.animationCellsCount = addList2.count
                    }
                    
                    if isNewRefresh && addList.count >= 40 {
                        // 再読み込み用のセルをつける
                        self.list.insert(AnalyzeJson.emptyContentData(), at: 0)
                    }
                    // 前に付ければ良い
                    self.list = addList2 + self.list
                    
                    // 選択位置がずれないようにする
                    if self.selectedRow != nil {
                        self.selectedRow = self.selectedRow! + addList2.count
                    }
                    
                    if addList2.count <= 3 && tableView.visibleRect.maxY >= tableView.preparedContentRect.maxY - 60 {
                        // 一番上の場合、ずれさせる
                    } else {
                        /*DispatchQueue.main.async {
                            // スクロールして、表示していたツイートがあまりずれないようにする
                            tableView.reloadData()
                            let oldOffsetY = tableView.contentOffset.y
                            let indexPath = IndexPath(row: min(self.cellCount, addList2.count), section: 0)
                            tableView.scrollToRow(at: indexPath,
                                                  at: UITableViewScrollPosition.top,
                                                  animated: false)
                            tableView.contentOffset.y = max(0, tableView.contentOffset.y + oldOffsetY)
                        }*/
                    }
                    
                    if isStreaming {
                        tableView.reloadData()
                        
                        self.inAnimating = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            self.animationCellsCount = 0
                            var indexPathList: [IndexPath] = []
                            for i in 0..<self.animationCellsCount {
                                indexPathList.append(IndexPath(item: i, section: 0))
                            }
                            tableView.reloadData()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                self.inAnimating = false
                            }
                        }
                    }
                } else {
                    // すでにあるデータを更新する
                    var index = 0
                    for newContent in addList2 {
                        var flag = false
                        while index < self.list.count {
                            let listData = self.list[index]
                            if listData.id == newContent.id {
                                // 更新
                                if newContent.isMerge && !self.list[index].isMerge {
                                    // 何もしない
                                } else {
                                    self.list[index] = newContent
                                }
                                flag = true
                                break
                            }
                            // タイムラインの方が古いので、その前に追加する
                            if (listData.id ?? "") < (newContent.id ?? "") {
                                self.list.insert(newContent, at: index)
                                flag = true
                                
                                // 選択位置がずれないようにする
                                if self.selectedRow != nil && index < self.selectedRow! {
                                    self.selectedRow = self.selectedRow! + 1
                                }
                                
                                break
                            }
                            index += 1
                        }
                        if !flag {
                            self.list.append(newContent)
                        }
                    }
                    
                    if isStreaming {
                        tableView.reloadData()
                    }
                }
            }
            
            if !isStreaming {
                tableView.reloadData()
            }
        }
    }
    
    // トゥートの削除
    func delete(tableView: NSTableView, deleteId: String) {
        DispatchQueue.main.async {
            for (index, data) in self.list.enumerated() {
                if index >= 500 { break }
                
                if deleteId == data.id {
                    tableView.reloadData()
                    
                    // 選択位置がずれないようにする
                    if self.selectedRow != nil && index < self.selectedRow! {
                        self.selectedRow = self.selectedRow! - 1
                    }
                    
                    // 削除
                    self.list.remove(at: index)
                    tableView.beginUpdates()
                    tableView.removeRows(at: IndexSet(integer: index), withAnimation: NSTableView.AnimationOptions.effectFade)
                    tableView.endUpdates()
                    break
                }
            }
        }
    }
}
