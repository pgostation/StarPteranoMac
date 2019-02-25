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
    }
    
    private let hostName: String
    private let accessToken: String
    let type: TimeLineType
    private let option: String? // user指定時はユーザID、タグ指定時はタグ
    private let mentions: ([AnalyzeJson.ContentData], [String: AnalyzeJson.AccountData])? // typeに.mentions指定時のみ有効
    
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
        if self.type == .user || self.type == .mentions || self.type == .localTag || self.type == .federationTag || self.type == .direct || self.type == .favorites {
            let view = TimeLineView(hostName: hostName, accessToken: accessToken, type: self.type, option: self.option, mentions: mentions)
            view.vc = self
            self.view = view
        } else {
            let view = TimeLineView(hostName: hostName, accessToken: accessToken, type: self.type, option: self.option, mentions: mentions)
            view.vc = self
            self.view = view
        }
        
        (self.view as? TimeLineView)?.startStreaming()
    }
    
    // ユーザータイムライン/詳細トゥートを閉じる
    @objc func closeAction() {
        self.removeFromParent()
        self.view.removeFromSuperview()
    }
    
    override func viewDidLayout() {
        if let frame = self.view.superview?.frame, let view = self.view as? TimeLineView {
            var sumHeight: CGFloat = 0
            for i in 0..<view.numberOfRows {
                if i > 10 {
                    sumHeight += 150
                } else {
                    sumHeight += view.model.tableView(view, heightOfRow: i)
                }
            }
            
            view.frame = NSRect(x: 0, y: 0, width: frame.width, height: sumHeight)
        }
    }
}
