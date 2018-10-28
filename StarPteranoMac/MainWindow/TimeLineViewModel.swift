//
//  TimeLineViewModel.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa
import APNGKit
import AVFoundation

final class TimeLineViewModel: NSObject, NSTableViewDataSource, NSTableViewDelegate, NSTextViewDelegate {
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
    
    // 途中読み込みセルをタップしたら
    @objc func reloadOld(_ sender: NSButton) {
        // 一番上で見つかった途中読み込みセルより前をすべて消す
        for (index, data) in self.list.enumerated() {
            if data.id == nil {
                self.list.removeLast(self.list.count - index)
                if let tableView = sender.superview?.superview as? NSTableView {
                    tableView.reloadData()
                }
                break
            }
        }
    }
    
    // セルの数
    private var isFirstView = true
    func numberOfRows(in tableView: NSTableView) -> Int {
        if list.count == 0, isFirstView {
            isFirstView = false
            if let timelineView = tableView as? TimeLineView {
                timelineView.refresh()
            }
        }
        
        if let timelineView = tableView as? TimeLineView {
            if timelineView.type == .user {
                self.cellCount = list.count + 2
                return list.count + 2 // プロフィール表示とオートページャライズ用のセル
            }
        }
        
        self.cellCount = list.count + 1
        return list.count + 1 // オートページャライズ用のセル
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        var index = row
        
        if let timelineView = tableView as? TimeLineView {
            if timelineView.type == .user {
                index -= 1
                if index < 0 {
                    // プロフィール表示用セルの高さ
                    let accountData = timelineView.accountList[timelineView.option ?? ""]
                    let cell = ProfileViewCell(accountData: accountData, isTemp: true)
                    cell.layout()
                    return cell.frame.height
                }
            }
        }
        
        if row == list.count {
            // AutoPagerize用セルの高さ
            return 300
        }
        
        if index < self.animationCellsCount {
            return 1
        }
        
        let isSelected = !SettingsData.tapDetailMode && row == self.selectedRow
        
        if SettingsData.isMiniView == .miniView && !isSelected {
            return 23 + SettingsData.fontSize * 1.5
        }
        if SettingsData.isMiniView == .superMini && !isSelected {
            return 10 + SettingsData.fontSize
        }
        
        // メッセージのビューを一度作り、高さを求める
        let (messageView, data, _) = getMessageViewAndData(tableView: tableView, index: index, row: row, add: false, callback: nil)
        
        // セルを拡大表示するかどうか
        var detailOffset: CGFloat = isSelected ? 40 : 0
        if isDetailTimeline && row == selectedRow { // 詳細拡大表示
            detailOffset += 20
            
            // ブーストした人の名前を表示
            if let reblogs_count = data.reblogs_count, reblogs_count > 0 {
                detailOffset += (SettingsData.fontSize + 4) * CGFloat(min(10, reblogs_count)) + 4
            }
            // お気に入りした人の名前を表示
            if let favourites_count = data.favourites_count, favourites_count > 0 {
                detailOffset += (SettingsData.fontSize + 4) * CGFloat(min(10, favourites_count)) + 4
            }
        }
        
        if (data.sensitive == 1 && data.mediaData != nil) { // もっと見る
            detailOffset += 20
        }
        if data.spoiler_text != "" && data.spoiler_text != nil {
            if data.spoiler_text!.count > 15 {
                let spolerTextLabel = NSTextField()
                spolerTextLabel.stringValue = data.spoiler_text ?? ""
                spolerTextLabel.font = NSFont.systemFont(ofSize: SettingsData.fontSize)
                //spolerTextLabel.numberOfLines = 0
                spolerTextLabel.lineBreakMode = .byCharWrapping
                spolerTextLabel.frame.size.width = tableView.frame.width - 70
                spolerTextLabel.sizeToFit()
                detailOffset += 20 + spolerTextLabel.frame.height
            } else {
                detailOffset += 20 + SettingsData.fontSize + 5
            }
        }
        
        let imagesOffset: CGFloat
        if let mediaData = data.mediaData {
            imagesOffset = (isSelected ? tableView.frame.width - 70 : 90) * CGFloat(mediaData.count)
        } else {
            imagesOffset = 0
        }
        
        let reblogOffset: CGFloat
        if data.reblog_acct != nil || data.visibility == "direct" {
            reblogOffset = 20
        } else {
            reblogOffset = 0
        }
        
        return max(55, messageView.frame.height + 36 + reblogOffset + imagesOffset + detailOffset)
    }
    
    // メッセージのビューとデータを返す
    private var cacheDict: [String: (NSView, AnalyzeJson.ContentData, Bool)] = [:]
    private var oldCacheDict: [String: (NSView, AnalyzeJson.ContentData, Bool)] = [:]
    private func getMessageViewAndData(tableView: NSTableView, index: Int, row: Int, add: Bool, callback: (()->Void)?) -> (NSView, AnalyzeJson.ContentData, Bool) {
        let data = list[index]
        
        if data.emojis == nil, let id = data.id, let cache = self.cacheDict[id] ?? self.oldCacheDict[id] {
            if row == selectedRow {
            } else if cache.0.superview == nil {
                return cache
            }
        }
        
        // content解析
        let (attributedText, hasLink) = DecodeToot.decodeContentFast(content: data.content, emojis: data.emojis, callback: callback)
        
        // 行間を広げる
        let paragrahStyle = NSMutableParagraphStyle()
        paragrahStyle.minimumLineHeight = SettingsData.fontSize + 10
        paragrahStyle.maximumLineHeight = SettingsData.fontSize + 10
        attributedText.addAttributes([NSAttributedString.Key.paragraphStyle : paragrahStyle],
                                     range: NSMakeRange(0, attributedText.length))
        
        // プロパティ設定
        let msgView = NSTextView()
        msgView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: ThemeColor.linkTextColor]
        msgView.textContainer?.lineBreakMode = .byCharWrapping
        //msgView.isOpaque = true
        //msgView.isScrollEnabled = false
        msgView.isEditable = false
        msgView.delegate = self // URLタップ用
        msgView.textStorage?.append(attributedText)
        msgView.font = NSFont.systemFont(ofSize: SettingsData.fontSize)
        msgView.textColor = ThemeColor.messageColor
        msgView.backgroundColor = ThemeColor.cellBgColor
        //msgView.cachingFlag = true
        
        let messageView = msgView
        
        // ビューの高さを決める
        messageView.frame.size.width = tableView.frame.width - (SettingsData.iconSize * 2 + 2)
        if SettingsData.isMiniView == .normal || self.selectedRow == row {
            messageView.sizeToFit()
        }
        var isContinue = false
        if self.selectedRow == row {
            // 詳細表示の場合
        } else {
            if messageView.frame.size.height >= 200 - 28 {
                messageView.frame.size.height = 180 - 28
                isContinue = true
            }
        }
        
        if let id = data.id, row != selectedRow {
            if self.oldCacheDict[id] != nil {
                /*if let textView = self.oldCacheDict[id]?.0 as? MyTextView {
                    textView.cachingFlag = false
                }*/
                self.oldCacheDict[id] = nil
            }
            if self.cacheDict[id] != nil {
                /*if let textView = self.cacheDict[id]?.0 as? MyTextView {
                    textView.cachingFlag = false
                }*/
                self.cacheDict[id] = nil
            }
            self.cacheDict[id] = (messageView, data, isContinue)
            
            // 破棄候補を破棄して、キャッシュを破棄候補に移す
            if self.cacheDict.count > 10 {
                // キャッシュ中フラグを倒す
                for data in self.oldCacheDict {
                    /*if let textView = data.value.0 as? MyTextView {
                        textView.cachingFlag = false
                    }*/
                }
                
                self.oldCacheDict = self.cacheDict
                self.cacheDict = [:]
            }
        }
        
        return (messageView, data, isContinue)
    }
    
    // セルを返す
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var index = row
        
        guard let timelineView = tableView as? TimeLineView else {
            return NSView()
        }
        
        if timelineView.type == .user {
            index -= 1
            if index < 0 {
                // プロフィール表示用セル
                let accountData = timelineView.accountList[timelineView.option ?? ""]
                let isTemp = (self.list.count == 0)
                let cell = ProfileViewCell(accountData: accountData, isTemp: isTemp)
                cell.timelineView = tableView as? TimeLineView
                return cell
            }
        }
        
        if row < self.animationCellsCount {
            let screenCellCount: Int
            if SettingsData.isMiniView == .superMini {
                screenCellCount = Int(tableView.frame.height / (10 + SettingsData.fontSize))
            } else {
                screenCellCount = Int(tableView.frame.height / (23 + SettingsData.fontSize * 1.5))
            }
            if row > screenCellCount {
                return NSView()
            }
        }
        
        if index >= list.count {
            if self.showAutoPagerizeCell, let timelineView = tableView as? TimeLineView {
                // 過去のトゥートに遡る
                timelineView.refreshOld(id: timelineView.model.getLastTootId())
            }
            let cell = NSView()
            return cell
        }
        
        var cell: TimeLineViewCell! = nil
        var id: String = ""
        
        // 表示用のデータを取得
        let (messageView, data, isContinue) = getMessageViewAndData(tableView: tableView, index: index, row: row, add: true, callback: { [weak self] in
            guard let strongSelf = self else { return }
            // あとから絵文字が読み込めた場合の更新処理
            if cell.id != id { return }
            let (messageView, _, _) = strongSelf.getMessageViewAndData(tableView: tableView, index: index, row: row, add: true, callback: nil)
            let isHidden = cell?.messageView?.isHidden ?? false
            messageView.isHidden = isHidden
            if let oldMessageView = cell?.messageView {
                cell?.replaceSubview(oldMessageView, with: messageView)
            } else {
                cell?.addSubview(messageView)
            }
            cell?.messageView = messageView
            strongSelf.setCellColor(cell: cell)
            if cell?.isMiniView != .normal && strongSelf.selectedRow != row {
                //(messageView as? NSTextField)?.numberOfLines = 1
                (messageView as? NSTextView)?.sizeToFit()
            }
            let y = cell.isMiniView == .superMini ? -9 : cell.detailDateLabel?.frame.maxY ?? cell.spolerTextLabel?.frame.maxY ?? ((cell.isMiniView != .normal ? -9 : 5) + SettingsData.fontSize)
            messageView.frame.origin.y = y
        })
        while let apngView = messageView.viewWithTag(5555) as? APNGImageView {
            apngView.stopAnimating()
            apngView.removeFromSuperview()
        }
        
        if data.id == nil && (timelineView.type != .user && timelineView.type != .mentions) {
            // タイムライン途中読み込み用のセル
            let cell = NSView()
            cell.wantsLayer = true
            cell.layer?.backgroundColor = ThemeColor.viewBgColor.cgColor
            //cell.selectionStyle = .none
            let loadButton = NSButton()
            loadButton.title = "🔄"
            loadButton.frame = NSRect(x: 0, y: 0, width: tableView.frame.width, height: SettingsData.isMiniView == .normal ? 60 : (SettingsData.isMiniView == .miniView ? 44 : 30))
            cell.addSubview(loadButton)
            loadButton.action = #selector(reloadOld(_:))
            return cell
        } else if data.id == nil {
            let cell = NSView()
            return cell
        }
        
        /*
        // カスタム絵文字のAPNGアニメーション対応
        if SettingsData.useAnimation, let emojis = data.emojis, emojis.count > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                guard let messageView = cell?.messageView as? NSTextView else { return }
                
                guard let attributedText = messageView.textStorage?.attributedSubstring(from: NSMakeRange(0, messageView.textStorage?.length ?? 0)) else { return }
                let list = DecodeToot.getEmojiList(attributedText: attributedText, textStorage: messageView.textStorage!)
                for data in list {
                    let beginning = messageView.beginningOfDocument
                    guard let start = messageView.position(from: beginning, offset: data.0.location) else { continue }
                    guard let end = messageView.position(from: start, offset: data.0.length) else { continue }
                    guard let textRange = messageView.textRange(from: start, to: end) else { continue }
                    let position = messageView.firstRect(for: textRange)
                    if position.origin.x == CGFloat.infinity { continue }
                    
                    for emoji in emojis {
                        if emoji["shortcode"] as? String == data.1 {
                            APNGImageCache.image(urlStr: emoji["url"] as? String) { image in
                                if image.frameCount <= 1 { return }
                                let apngView = APNGImageView(image: image)
                                //apngView.tag = 5555
                                apngView.autoStartAnimation = true
                                //apngView.backgroundColor = ThemeColor.cellBgColor
                                let size = min(position.size.width, position.size.height)
                                apngView.frame = CGRect(x: position.origin.x,
                                                        y: position.origin.y + 3,
                                                        width: size,
                                                        height: size)
                                messageView.addSubview(apngView)
                            }
                            break
                        }
                    }
                }
            }
        }*/
        
        let account = accountList[data.accountId]
        
        let height = max(55, messageView.frame.height + 28)
        cell = getCell(view: tableView, height: height)
        cell.frame = NSRect(x: 0, y: 0, width: tableView.frame.width, height: height)
        cell.id = data.id ?? ""
        cell.reblog_id = data.reblog_id
        id = data.id ?? ""
        cell.tableView = tableView as? TimeLineView
        cell.indexPath = row
        cell.accountId = account?.id
        cell.mentionsList = data.mentions
        cell.contentData = data.content ?? ""
        cell.urlStr = data.url ?? ""
        cell.isMiniView = SettingsData.isMiniView
        cell.accountData = account
        cell.visibility = data.visibility
        
        if cell.isMiniView != .normal && self.selectedRow != row {
            //(messageView as? NSTextField)?.numberOfLines = 1
            (messageView as? NSTextView)?.sizeToFit()
        }
        
        cell.isFaved = (data.favourited == 1)
        cell.isBoosted = (data.reblogged == 1)
        
        cell.messageView = messageView
        cell.addSubview(messageView)
        
        // 「もっと見る」の場合
        if (data.sensitive == 1 && data.mediaData != nil) || (data.spoiler_text != nil && data.spoiler_text != "") {
            if data.spoiler_text != nil && data.spoiler_text != "" {
                messageView.isHidden = true
            }
            cell.spolerTextLabel = NSTextView()
            cell.spolerTextLabel?.textColor = ThemeColor.messageColor
            cell.spolerTextLabel?.font = NSFont.systemFont(ofSize: SettingsData.fontSize)
            let attributedText = DecodeToot.decodeName(name: data.spoiler_text ?? "", emojis: data.emojis, callback: {
                if cell.id == id {
                    let attributedText = DecodeToot.decodeName(name: data.spoiler_text ?? "", emojis: data.emojis, callback: nil)
                    cell.spolerTextLabel?.textStorage?.append(attributedText)
                    cell?.layout()
                }
            })
            cell.spolerTextLabel?.textStorage?.append(attributedText)
            //cell.spolerTextLabel?.numberOfLines = 0
            //cell.spolerTextLabel?.lineBreakMode = .byCharWrapping
            cell.spolerTextLabel?.frame.size.width = tableView.frame.width - 70
            cell.spolerTextLabel?.sizeToFit()
            cell.addSubview(cell.spolerTextLabel!)
        }
        
        func barColor(color: NSColor) {
            cell.DMBarLeft = NSView()
            cell.DMBarLeft?.wantsLayer = true
            cell.DMBarLeft?.layer?.backgroundColor = color.cgColor
            cell.addSubview(cell.DMBarLeft!)
            cell.DMBarRight = NSView()
            cell.DMBarRight?.wantsLayer = true
            cell.DMBarRight?.layer?.backgroundColor = color.cgColor
            cell.addSubview(cell.DMBarRight!)
        }
        
        if data.visibility == "direct" {
            // ダイレクトメッセージは赤
            barColor(color: ThemeColor.directBar)
        } else if data.visibility == "private" {
            // プライベートメッセージはオレンジ
            barColor(color: ThemeColor.privateBar)
        } else if timelineView.type == .local && data.isMerge {
            // ローカルのトゥートがこれ以上なければ、過去のトゥートを取得してTLはこれ以上表示しない
            var isHomeOnly = true
            for i in row..<list.count {
                if !list[i].isMerge {
                    isHomeOnly = false
                    break
                }
            }
            if isHomeOnly {
                if self.showAutoPagerizeCell, let timelineView = tableView as? TimeLineView {
                    // 過去のトゥートに遡る
                    timelineView.refreshOld(id: timelineView.model.getLastTootId())
                }
                let cell = NSView()
                //cell.backgroundColor = ThemeColor.viewBgColor
                //cell.selectionStyle = .none
                return cell
            }
            
            if data.visibility == "unlisted" || data.reblog_id != nil || accountList[data.accountId]?.acct?.contains("@") == true || data.in_reply_to_id != nil || data.in_reply_to_account_id != nil {
                // バーの色は青
                barColor(color: ThemeColor.unlistedBar)
            }
        }
        
        // 詳細表示の場合
        if self.selectedRow == row {
            cell.showDetail = true
            //cell.isSelected = true
            
            self.selectedAccountId = account?.id
            self.inReplyToTootId = data.in_reply_to_id
            self.inReplyToAccountId = data.in_reply_to_account_id
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.setCellColor(cell: cell)
                
                for subview in tableView.subviews {
                    if let cell = subview as? TimeLineViewCell {
                        if self.selectedRow == cell.indexPath { continue }
                        
                        self.setCellColor(cell: cell)
                    }
                }
            }
            
            // 返信ボタンを追加
            cell.replyButton = NSButton()
            cell.replyButton?.title = "↩︎"
            //cell.replyButton?.setTitleColor(ThemeColor.detailButtonsColor, for: .normal)
            cell.replyButton?.action = #selector(cell.replyAction)
            cell.addSubview(cell.replyButton!)
            
            // 返信された数
            cell.repliedLabel = NSTextField()
            cell.addSubview(cell.repliedLabel!)
            if let replies_count = data.replies_count, replies_count > 0 {
                cell.repliedLabel?.stringValue = "\(replies_count)"
                cell.repliedLabel?.textColor = ThemeColor.messageColor
                cell.repliedLabel?.font = NSFont.systemFont(ofSize: SettingsData.fontSize - 2)
            }
            
            // ブーストボタン
            cell.boostButton = NSButton()
            if data.visibility == "direct" || data.visibility == "private" {
                cell.boostButton?.title = "🔐"
            } else {
                cell.boostButton?.title = "⇄"
                if data.reblogged == 1 {
                    //cell.boostButton?.setTitleColor(ThemeColor.detailButtonsHiliteColor, for: .normal)
                } else {
                    //cell.boostButton?.setTitleColor(ThemeColor.detailButtonsColor, for: .normal)
                }
                cell.boostButton?.action = #selector(cell.boostAction)
            }
            cell.addSubview(cell.boostButton!)
            
            // ブーストされた数
            cell.boostedLabel = NSTextField()
            cell.addSubview(cell.boostedLabel!)
            if let reblogs_count = data.reblogs_count, reblogs_count > 0 {
                cell.boostedLabel?.stringValue = "\(reblogs_count)"
                cell.boostedLabel?.textColor = ThemeColor.messageColor
                cell.boostedLabel?.font = NSFont.systemFont(ofSize: SettingsData.fontSize - 2)
            }
            
            // お気に入りボタン
            cell.favoriteButton = NSButton()
            cell.favoriteButton?.title = "★"
            if data.favourited == 1 {
                //cell.favoriteButton?.setTitleColor(ThemeColor.detailButtonsHiliteColor, for: .normal)
            } else {
                //cell.favoriteButton?.setTitleColor(ThemeColor.detailButtonsColor, for: .normal)
            }
            cell.favoriteButton?.action = #selector(cell.favoriteAction)
            cell.addSubview(cell.favoriteButton!)
            
            // お気に入りされた数
            cell.favoritedLabel = NSTextField()
            cell.addSubview(cell.favoritedLabel!)
            if let favourites_count = data.favourites_count, favourites_count > 0 {
                cell.favoritedLabel?.stringValue = "\(favourites_count)"
                cell.favoritedLabel?.textColor = ThemeColor.messageColor
                cell.favoritedLabel?.font = NSFont.systemFont(ofSize: SettingsData.fontSize - 2)
            }
            
            // 詳細ボタン
            cell.detailButton = NSPopUpButton()
            cell.setDetailButton(cell.detailButton!)
            cell.addSubview(cell.detailButton!)
            
            // 使用アプリケーション
            if let application = data.application, let name = application["name"] as? String {
                cell.applicationLabel = NSTextField()
                cell.addSubview(cell.applicationLabel!)
                cell.applicationLabel?.stringValue = name
                cell.applicationLabel?.textColor = ThemeColor.dateColor
                //cell.applicationLabel?.textAlignment = .right
                //cell.applicationLabel?.adjustsFontSizeToFitWidth = true
                cell.applicationLabel?.font = NSFont.systemFont(ofSize: SettingsData.fontSize - 2)
            }
        } else {
            setCellColor(cell: cell)
        }
        
        ImageCache.image(urlStr: account?.avatar ?? account?.avatar_static, isTemp: false, isSmall: true) { image in
            if cell.id == id {
                cell.iconView?.removeFromSuperview()
                let iconView: NSImageView
                iconView = NSImageView()
                
                cell.iconView = iconView
                cell.addSubview(iconView)
                cell.iconView?.image = image
                cell.iconView?.layer?.cornerRadius = 5
                //cell.iconView?.clipsToBounds = true
                //cell.iconView?.insets = UIEdgeInsetsMake(5, 5, 5, 5)
                
                // アイコンのタップジェスチャー
                //let tapGesture = UITapGestureRecognizer(target: cell, action: #selector(cell.tapAccountAction))
                //cell.iconView?.addGestureRecognizer(tapGesture)
                //cell.iconView?.isUserInteractionEnabled = true
                
                // アイコンの長押しジェスチャー
                //let pressGesture = UILongPressGestureRecognizer(target: cell, action: #selector(cell.pressAccountAction(_:)))
                //cell.iconView?.addGestureRecognizer(pressGesture)
                let iconSize = SettingsData.iconSize
                
                cell.iconView?.frame = CGRect(x: cell.isMiniView != .normal ? 4 : 8,
                                              y: cell.isMiniView == .superMini ? 12 - iconSize / 2 : (cell.isMiniView != .normal ? 6 : 10),
                                              width: iconSize,
                                              height: iconSize)
            }
        }
        
        cell.nameLabel.attributedStringValue = DecodeToot.decodeName(name: account?.display_name ?? "", emojis: account?.emojis, callback: {
            if cell.id == id {
                cell.nameLabel.attributedStringValue = DecodeToot.decodeName(name: account?.display_name ?? "", emojis: account?.emojis, callback: nil)
                cell?.needsLayout = true
            }
        })
        if row > 15 {
            DispatchQueue.main.async {
                cell.nameLabel.sizeToFit()
            }
        } else {
            cell.nameLabel.sizeToFit()
        }
        
        cell.idLabel.stringValue = account?.acct ?? ""
        
        if let created_at = data.reblog_created_at ?? data.created_at {
            let date = DecodeToot.decodeTime(text: created_at)
            
            if isDetailTimeline && row == selectedRow { // 拡大表示
                cell.dateLabel.isHidden = true
                cell.detailDateLabel = NSTextField()
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .medium
                cell.detailDateLabel?.stringValue = dateFormatter.string(from: date)
                cell.detailDateLabel?.textColor = ThemeColor.dateColor
                cell.detailDateLabel?.font = NSFont.systemFont(ofSize: SettingsData.fontSize)
                //cell.detailDateLabel?.textAlignment = .right
                cell.addSubview(cell.detailDateLabel!)
            } else {
                cell.date = date
                cell.refreshDate()
                if cell.isMiniView != .superMini {
                    cell.dateLabel.isHidden = false
                }
            }
        }
        
        // 画像や動画ありの場合
        if let mediaData = data.mediaData {
            cell.previewUrls = []
            cell.imageUrls = []
            cell.originalUrls = []
            cell.imageTypes = []
            
            for (index, media) in mediaData.enumerated() {
                func addImageView(withPlayButton: Bool) {
                    let imageView = NSImageView()
                    
                    imageView.wantsLayer = true
                    imageView.layer?.backgroundColor = NSColor.gray.withAlphaComponent(0.3).cgColor
                    //imageView.clipsToBounds = true
                    imageView.layer?.borderColor = NSColor.gray.withAlphaComponent(0.2).cgColor
                    imageView.layer?.borderWidth = 1 / (NSScreen.main?.backingScaleFactor ?? 1)
                    
                    /*
                    // タップで全画面表示
                    let tapGesture = UITapGestureRecognizer(target: cell, action: #selector(cell.imageTapAction(_:)))
                    imageView.addGestureRecognizer(tapGesture)
                    imageView.isUserInteractionEnabled = true */
                    
                    // 画像読み込み
                    let isPreview = !(isDetailTimeline && row == selectedRow)
                    ImageCache.image(urlStr: media.preview_url, isTemp: true, isSmall: false, isPreview: isPreview) { image in
                        imageView.image = image
                        imageView.layer?.backgroundColor = nil
                        cell.needsLayout = true
                    }
                    cell.addSubview(imageView)
                    cell.imageViews.append(imageView)
                    
                    if data.sensitive == 1 || data.spoiler_text != "" {
                        imageView.isHidden = true
                    }
                    
                    cell.previewUrls.append(media.preview_url ?? "")
                    cell.imageUrls.append(media.url ?? "")
                    cell.originalUrls.append(media.remote_url ?? "")
                    cell.imageTypes.append(media.type ?? "")
                    
                    if withPlayButton {
                        // 再生の絵文字を表示
                        let triangleView = NSTextField()
                        triangleView.stringValue = "▶️"
                        triangleView.font = NSFont.systemFont(ofSize: 24)
                        triangleView.sizeToFit()
                        imageView.addSubview(triangleView)
                        DispatchQueue.main.async {
                            triangleView.frame.origin = CGPoint(x: imageView.bounds.width / 2 - 12, y: imageView.bounds.height / 2 - 12)
                        }
                    }
                }
                
                if media.type == "unknown" {
                    // 不明
                    addImageView(withPlayButton: false)
                    
                    // リンク先のファイル名を表示
                    let label = NSTextField()
                    label.stringValue = String((media.remote_url ?? "").split(separator: "/").last ?? "")
                    //label.textAlignment = .center
                    //label.numberOfLines = 0
                    label.lineBreakMode = .byCharWrapping
                    label.textColor = ThemeColor.linkTextColor
                    cell.imageViews.last?.addSubview(label)
                    DispatchQueue.main.async {
                        label.frame = cell.imageViews.last?.bounds ?? CGRect(x: 0, y: 0, width: 0, height: 0)
                    }
                } else if media.type == "gifv" || media.type == "video" {
                    // 動画の場合
                    if row == selectedRow {
                        // とりあえずプレビューを表示
                        addImageView(withPlayButton: false)
                        
                        // 動画読み込み
                        MovieCache.movie(urlStr: media.url) { player, queuePlayer, looper in
                            if let player = player {
                                // レイヤーの追加
                                let playerLayer = AVPlayerLayer(player: player)
                                cell.layer?.addSublayer(playerLayer)
                                cell.movieLayers.append(playerLayer)
                                
                                if index < cell.imageViews.count {
                                    cell.layout()
                                    playerLayer.frame = cell.imageViews[index].frame
                                }
                                
                                // 再生
                                player.play()
                                
                                if data.sensitive == 1 || data.spoiler_text != "" {
                                    playerLayer.isHidden = true
                                }
                            } else {
                                if #available(OSX 10.12, *) {
                                    if let queuePlayer = queuePlayer as? AVQueuePlayer, let looper = looper as? AVPlayerLooper {
                                        // レイヤーの追加
                                        let playerLayer = AVPlayerLayer(player: queuePlayer)
                                        cell.layer?.addSublayer(playerLayer)
                                        cell.movieLayers.append(playerLayer)
                                        cell.looper = looper
                                        
                                        if index < cell.imageViews.count {
                                            cell.layout()
                                            playerLayer.frame = cell.imageViews[index].frame
                                        }
                                        
                                        // ループ再生
                                        queuePlayer.play()
                                        
                                        if data.sensitive == 1 || data.spoiler_text != "" {
                                            playerLayer.isHidden = true
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        addImageView(withPlayButton: true)
                    }
                } else {
                    // 静止画の場合
                    addImageView(withPlayButton: false)
                }
            }
        }
        
        // 長すぎて省略している場合
        if isContinue {
            cell.continueView = NSTextField()
            cell.continueView?.font = NSFont.systemFont(ofSize: SettingsData.fontSize)
            cell.continueView?.stringValue = "▼"
            cell.continueView?.textColor = ThemeColor.nameColor
            //cell.continueView?.textAlignment = .center
            cell.addSubview(cell.continueView!)
        }
        
        // ブーストの場合
        if let reblog_acct = data.reblog_acct {
            let account = accountList[reblog_acct]
            cell.boostView = NSTextField()
            cell.boostView?.font = NSFont.systemFont(ofSize: SettingsData.fontSize - 2)
            cell.boostView?.textColor = ThemeColor.dateColor
            var username = account?.display_name ?? ""
            if username == "" {
                username = account?.acct ?? ""
            }
            let name = String(format: I18n.get("BOOSTED_BY_%@"), username)
            cell.boostView?.attributedStringValue = DecodeToot.decodeName(name: name, emojis: account?.emojis, callback: nil)
            cell.addSubview(cell.boostView!)
        }
        
        // もっと見るの場合
        if (data.sensitive == 1 && data.mediaData != nil) || (data.spoiler_text != "" && data.spoiler_text != nil) {
            cell.showMoreButton = NSButton()
            cell.showMoreButton?.title = I18n.get("BUTTON_SHOW_MORE")
            //cell.showMoreButton?.setTitleColor(ThemeColor.nameColor, for: .normal)
            cell.showMoreButton?.action = #selector(cell.showMoreAction)
            cell.addSubview(cell.showMoreButton!)
            
            if let id = data.id, id != "" && TimeLineViewCell.showMoreList.contains(id) {
                // すでに解除済み
                cell.showMoreAction(forceShow: true)
            }
        }
        
        // DMの場合
        if data.visibility == "direct" {
            cell.boostView = NSTextField()
            cell.boostView?.font = NSFont.boldSystemFont(ofSize: SettingsData.fontSize)
            cell.boostView?.textColor = NSColor.red
            cell.boostView?.stringValue = I18n.get("THIS_TOOT_IS_DIRECT_MESSAGE")
            cell.addSubview(cell.boostView!)
        }
        
        // お気に入りした人やブーストした人の名前表示
        if isDetailTimeline && row == selectedRow { // 詳細拡大表示
            //getBoosterAndFavoriter(data: data, cell: cell)
        }
        
        return cell
    }
    
    // セルの色を設定
    private func setCellColor(cell: TimeLineViewCell) {
        func mentionContains(selectedAccountId: String?, mentions: [AnalyzeJson.MentionData]?) -> Bool {
            guard let selectedAccountId = selectedAccountId else { return false }
            guard let mentions = mentions else { return false }
            for mention in mentions {
                if selectedAccountId == mention.id {
                    return true
                }
            }
            return false
        }
        
        if self.selectedRow != nil && self.selectedRow == cell.indexPath {
            // 選択色
            cell.layer?.backgroundColor = ThemeColor.selectedBgColor.cgColor
            //cell.messageView?.backgroundColor = ThemeColor.selectedBgColor
            cell.nameLabel.backgroundColor = ThemeColor.selectedBgColor
            cell.idLabel.backgroundColor = ThemeColor.selectedBgColor
            cell.dateLabel.backgroundColor = ThemeColor.selectedBgColor
        } else if self.selectedAccountId == cell.accountId && self.inReplyToTootId == cell.id {
            // 選択したアカウントと同一で、返信先のトゥートの色
            cell.layer?.backgroundColor = ThemeColor.mentionedMeBgColor.cgColor
            //cell.messageView?.backgroundColor = ThemeColor.mentionedMeBgColor
            cell.nameLabel.backgroundColor = ThemeColor.mentionedMeBgColor
            cell.idLabel.backgroundColor = ThemeColor.mentionedMeBgColor
            cell.dateLabel.backgroundColor = ThemeColor.mentionedMeBgColor
        } else if self.selectedAccountId == cell.accountId && cell.accountId != "" {
            // 選択したアカウントと同一のアカウントの色
            cell.layer?.backgroundColor = ThemeColor.sameAccountBgColor.cgColor
            //cell.messageView?.backgroundColor = ThemeColor.sameAccountBgColor
            cell.nameLabel.backgroundColor = ThemeColor.sameAccountBgColor
            cell.idLabel.backgroundColor = ThemeColor.sameAccountBgColor
            cell.dateLabel.backgroundColor = ThemeColor.sameAccountBgColor
        } else if self.inReplyToTootId == cell.id && cell.id != "" {
            // 返信先のトゥートの色
            cell.layer?.backgroundColor = ThemeColor.mentionedBgColor.cgColor
            //cell.messageView?.backgroundColor = ThemeColor.mentionedBgColor
            cell.nameLabel.backgroundColor = ThemeColor.mentionedBgColor
            cell.idLabel.backgroundColor = ThemeColor.mentionedBgColor
            cell.dateLabel.backgroundColor = ThemeColor.mentionedBgColor
        } else if self.inReplyToAccountId == cell.accountId && cell.accountId != nil {
            // 返信先のアカウントの色
            cell.layer?.backgroundColor = ThemeColor.mentionedSameBgColor.cgColor
            //cell.messageView?.backgroundColor = ThemeColor.mentionedSameBgColor
            cell.nameLabel.backgroundColor = ThemeColor.mentionedSameBgColor
            cell.idLabel.backgroundColor = ThemeColor.mentionedSameBgColor
            cell.dateLabel.backgroundColor = ThemeColor.mentionedSameBgColor
        } else if mentionContains(selectedAccountId: self.selectedAccountId, mentions: cell.mentionsList) {
            // メンションが選択中アカウントの場合の色
            cell.layer?.backgroundColor = ThemeColor.toMentionBgColor.cgColor
            //cell.messageView?.backgroundColor = ThemeColor.toMentionBgColor
            cell.nameLabel.backgroundColor = ThemeColor.toMentionBgColor
            cell.idLabel.backgroundColor = ThemeColor.toMentionBgColor
            cell.dateLabel.backgroundColor = ThemeColor.toMentionBgColor
        } else {
            // 通常色
            cell.layer?.backgroundColor = ThemeColor.cellBgColor.cgColor
            //cell.messageView?.backgroundColor = ThemeColor.cellBgColor
            cell.nameLabel.backgroundColor = ThemeColor.cellBgColor
            cell.idLabel.backgroundColor = ThemeColor.cellBgColor
            cell.dateLabel.backgroundColor = ThemeColor.cellBgColor
        }
    }
    
    // セルを使い回す
    private func getCell(view: NSTableView, height: CGFloat) -> TimeLineViewCell {
        let reuseIdentifier = "TimeLineViewModel"
        let cell = TimeLineViewCell(reuseIdentifier: reuseIdentifier)
        
        if SettingsData.isMiniView == .superMini {
            cell.nameLabel.isHidden = true
            cell.idLabel.isHidden = true
            cell.dateLabel.isHidden = true
        } else {
            cell.nameLabel.isHidden = false
            cell.idLabel.isHidden = false
            cell.dateLabel.isHidden = false
        }
        
        return cell
    }
}
