//
//  TimeLineViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class TimeLineViewController: NSViewController {
    enum TimeLineType {
        case home // ホーム
        case local // ローカルタイムライン
        case homeLocal // ホームローカル統合TL
        case federation // 連合タイムライン
        case user // 指定ユーザータイムライン
        case favorites // お気に入り
        case localTag
        case federationTag
        case mentions // 単一トゥート(と会話)
        case direct // ダイレクトメッセージ
        case list // リスト
        case scheduled // 予約投稿
        case notifications // 通知一覧
        case notificationMentions // 通知一覧(メンションのみ)
        case search // 検索
        case filter0 // 抽出1
        case filter1 // 抽出2
        case filter2 // 抽出3
        case filter3 // 抽出4
    }
    
    let hostName: String
    let accessToken: String
    let type: TimeLineType
    private var option: String? // user指定時はユーザID、タグ指定時はタグ、リスト指定時はリストID
    private let mentions: ([AnalyzeJson.ContentData], [String: AnalyzeJson.AccountData])? // typeに.mentions指定時のみ有効
    var headerView: NSView? // リスト選択や検索フィールドをここに登録すると、上に表示する
    
    init(hostName: String, accessToken: String, type: TimeLineType, option: String? = nil, mentions: ([AnalyzeJson.ContentData], [String: AnalyzeJson.AccountData])? = nil) {
        self.hostName = hostName
        self.accessToken = accessToken
        self.type = type
        self.option = option
        self.mentions = mentions
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = TimeLineView(hostName: hostName, accessToken: accessToken, type: self.type, option: self.option, mentions: mentions)
        view.vc = self
        self.view = view
    
        // ヘッダービューを追加
        if self.type == .list && self.headerView == nil {
            // リスト選択用のポップアップ
            self.headerView = ListPopUp(hostName: hostName, accessToken: accessToken)
        }
        
        (self.view as? TimeLineView)?.startStreaming()
    }
    
    override func viewDidAppear() {
        if let headerView = self.headerView {
            DispatchQueue.main.async {
                if self.view.superview != nil {
                    self.view.superview?.superview?.superview?.addSubview(headerView)
                    self.view.superview?.superview?.superview?.needsLayout = true
                }
            }
        }
        
        switch self.type {
        case .filter0, .filter1, .filter2, .filter3:
            (self.view as? TimeLineView)?.model.setFiltering()
        default:
            break
        }
    }
    
    override func viewDidDisappear() {
        self.headerView?.removeFromSuperview()
    }
    
    // ユーザータイムライン/詳細トゥートを閉じる
    @objc func closeAction() {
        self.removeFromParent()
        self.view.removeFromSuperview()
    }
    
    // リストを選択
    func selectList(listId: String?) {
        let scrollView = self.view.superview?.superview as? NSScrollView
        self.view.removeFromSuperview()
        
        self.option = listId
        loadView()
        
        scrollView?.documentView = self.view
    }
    
    override func viewDidLayout() {
        if let frame = self.view.superview?.frame, let view = self.view as? TimeLineView {
            var sumHeight: CGFloat = 0
            let isMiniView = SettingsData.isMiniView
            var baseHeight = SettingsData.fontSize * 2
            for i in 0..<view.numberOfRows {
                if i > 10 {
                    if i == 11 && isMiniView == .full || isMiniView == .normal {
                        baseHeight = sumHeight / 10
                    }
                    switch isMiniView {
                    case .full:
                        sumHeight += 350
                    case .normal:
                        sumHeight += 300
                    case .miniView:
                        sumHeight += baseHeight * 2
                    case .superMini:
                        sumHeight += baseHeight
                    }
                } else {
                    sumHeight += view.model.tableView(view, heightOfRow: i)
                }
            }
            
            view.frame = NSRect(x: 0, y: 0, width: frame.width, height: sumHeight)
        }
    }
}
