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
        case federation // 連合タイムライン
        case user // 指定ユーザータイムライン
        case favorites // お気に入り
        case localTag
        case federationTag
        case mentions // 単一トゥート(と会話)
        case direct // ダイレクトメッセージ
        case list // リスト
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
}
