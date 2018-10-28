//
//  AnalyzeJson.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Foundation

final class AnalyzeJson {
    // タイムラインのJSONデータを解析して、リストに格納
    static func analyzeJsonArray(view: TimeLineView, model: TimeLineViewModel, jsonList: [AnyObject], isNew: Bool, isNewRefresh: Bool = false, isMerge: Bool = false) {
        var contentList: [ContentData] = []
        
        var acct: String = ""
        for json in jsonList {
            guard let json = json as? [String: Any] else { continue }
            
            let data = analyzeJson(view: view, model: model, json: json, acct: &acct, isMerge: isMerge)
            
            contentList.append(data)
        }
        
        /*
        // 新着の場合、更新した数を一時的に表示
        DispatchQueue.main.async {
            if view.window != nil && isNew && model.getFirstTootId() != nil && contentList.count > 0 {
                if view.type != .user && view.type != .mentions {
                    let count = contentList.count
                    MainViewController.instance?.showNotify(text: String(format: I18n.get("NOTIFY_COUNT_%D"), count))
                }
            }
        }
         */
        
        model.change(tableView: view, addList: contentList, accountList: view.accountList, isNewRefresh: isNewRefresh)
    }
    
    static func analyzeJson(view: TimeLineView?, model: TimeLineViewModel?, json: [String: Any], acct: inout String, isMerge: Bool = false) -> ContentData {
        if let account = json["account"] as? [String: Any] {
            acct = account["acct"] as? String ?? ""
            let data = analyzeAccountJson(account: account)
            view?.accountList.updateValue(data, forKey: acct)
        }
        let reblog = json["reblog"] as? [String: Any]
        var reblog_acct: String? = nil
        if let account = reblog?["account"] as? [String: Any] {
            reblog_acct = acct
            acct = account["acct"] as? String ?? ""
            let data = analyzeAccountJson(account: account)
            view?.accountList.updateValue(data, forKey: acct)
        }
        
        var mediaData: [MediaData]? = nil
        let media_attachments: [[String: Any]]?
        if reblog_acct == nil {
            media_attachments = json["media_attachments"] as? [[String: Any]]
        } else {
            media_attachments = reblog?["media_attachments"] as? [[String: Any]]
        }
        if let media_attachments = media_attachments {
            for media_attachment in media_attachments {
                let id = media_attachment["id"] as? Int64
                let preview_url = media_attachment["preview_url"] as? String
                let url = media_attachment["url"] as? String
                let remote_url = media_attachment["remote_url"] as? String
                let type = media_attachment["type"] as? String
                
                let data = MediaData(id: id,
                                     preview_url: preview_url,
                                     type: type,
                                     url: url,
                                     remote_url: remote_url)
                if mediaData == nil {
                    mediaData = []
                }
                mediaData?.append(data)
            }
        }
        
        var mentions: [MentionData]? = nil
        let mentionsJson: [[String: Any]]?
        if reblog_acct == nil {
            mentionsJson = json["mentions"] as? [[String: Any]]
        } else {
            mentionsJson = reblog?["mentions"] as? [[String: Any]]
        }
        if let mentionsJson = mentionsJson {
            for json in mentionsJson {
                let acct = json["acct"] as? String
                let id = json["id"] as? String
                let url = json["url"] as? String
                let username = json["username"] as? String
                
                let data = MentionData(acct: acct,
                                       id: id,
                                       url: url,
                                       username: username)
                if mentions == nil {
                    mentions = []
                }
                mentions?.append(data)
            }
        }
        
        var application: [String: Any]?
        if reblog_acct == nil {
            application = json["application"] as? [String: Any]
            if let name = application?["name"] as? String {
                application?["name"] = String(name.prefix(64))
            }
        } else {
            application = reblog?["application"] as? [String: Any]
            if let name = application?["name"] as? String {
                application?["name"] = String(name.prefix(64))
            }
        }
        
        let content = json["content"] as? String
        
        let created_at: String?
        let reblog_created_at: String?
        if reblog_acct == nil {
            created_at = json["created_at"] as? String
            reblog_created_at = nil
        } else {
            created_at = reblog?["created_at"] as? String
            reblog_created_at = reblog?["created_at"] as? String
        }
        
        var emojis: [[String: Any]]? = nil
        if reblog_acct == nil {
            emojis = json["emojis"] as? [[String: Any]]
        } else {
            emojis = reblog?["emojis"] as? [[String: Any]]
        }
        if emojis != nil && emojis!.count == 0 {
            emojis = nil
        }
        
        let favourited: Int?
        if reblog_acct == nil {
            favourited = json["favourited"] as? Int
        } else {
            favourited = reblog?["favourited"] as? Int
        }
        
        let favourites_count: Int?
        if reblog_acct == nil {
            favourites_count = json["favourites_count"] as? Int
        } else {
            favourites_count = reblog?["favourites_count"] as? Int
        }
        
        let id = json["id"] as? String
        let reblog_id = reblog?["id"] as? String
        
        let in_reply_to_account_id: String?
        if reblog_acct == nil {
            in_reply_to_account_id = json["in_reply_to_account_id"] as? String
        } else {
            in_reply_to_account_id = reblog?["in_reply_to_account_id"] as? String
        }
        
        let in_reply_to_id: String?
        if reblog_acct == nil {
            in_reply_to_id = json["in_reply_to_id"] as? String
        } else {
            in_reply_to_id = reblog?["in_reply_to_id"] as? String
        }
        
        let language = json["language"] as? String
        
        var muted: Int? = nil
        if reblog_acct == nil {
            muted = json["muted"] as? Int
        } else {
            muted = reblog?["muted"] as? Int
            if muted == 0 {
                muted = json["muted"] as? Int
            }
        }
        
        let reblogged: Int?
        if reblog_acct == nil {
            reblogged = json["reblogged"] as? Int
        } else {
            reblogged = reblog?["reblogged"] as? Int
        }
        
        let reblogs_count: Int?
        if reblog_acct == nil {
            reblogs_count = json["reblogs_count"] as? Int
        } else {
            reblogs_count = reblog?["reblogs_count"] as? Int
        }
        
        let replies_count: Int?
        if reblog_acct == nil {
            replies_count = json["replies_count"] as? Int
        } else {
            replies_count = reblog?["replies_count"] as? Int
        }
        
        let sensitive: Int?
        if reblog_acct == nil {
            sensitive = json["sensitive"] as? Int
        } else {
            sensitive = reblog?["sensitive"] as? Int
        }
        
        let spoiler_text: String?
        if reblog_acct == nil {
            spoiler_text = json["spoiler_text"] as? String
        } else {
            spoiler_text = reblog?["spoiler_text"] as? String
        }
        
        //let tags = json["tags"] as? [String]
        //let uri = json["uri"] as? String
        
        let url: String?
        if reblog_acct == nil {
            url = json["url"] as? String
        } else {
            url = reblog?["url"] as? String
        }
        
        let visibility: String?
        if reblog_acct == nil {
            visibility = json["visibility"] as? String
        } else {
            visibility = reblog?["visibility"] as? String
        }
        
        let data = ContentData(accountId: acct,
                               application: application,
                               content: content,
                               created_at: created_at,
                               emojis: emojis,
                               favourited: favourited,
                               favourites_count: favourites_count,
                               id: id,
                               in_reply_to_account_id: in_reply_to_account_id,
                               in_reply_to_id: in_reply_to_id,
                               language: language,
                               mediaData: mediaData,
                               mentions: mentions,
                               muted: muted,
                               reblog_acct: reblog_acct,
                               reblog_created_at: reblog_created_at,
                               reblog_id: reblog_id,
                               reblogged: reblogged,
                               reblogs_count: reblogs_count,
                               replies_count: replies_count,
                               sensitive: sensitive,
                               spoiler_text: spoiler_text,
                               //tags: tags,
            //uri: uri,
            url: url,
            visibility: visibility,
            isMerge: isMerge)
        return data
    }
    
    static func analyzeAccountJson(account: [String: Any]) -> AccountData {
        let acct = account["acct"] as? String ?? ""
        let avatar = account["avatar"] as? String
        let avatar_static = account["avatar_static"] as? String
        let bot = account["bot"] as? Int
        let created_at = account["created_at"] as? String
        let display_name = account["display_name"] as? String
        let emojis = account["emojis"] as? [[String: Any]]
        let fields = account["fields"] as? [[String: Any]]
        let followers_count = account["followers_count"] as? Int
        let following_count = account["following_count"] as? Int
        let header = account["header"] as? String
        let header_static = account["header_static"] as? String
        let id = account["id"] as? String
        let locked = account["locked"] as? Int
        let note = account["note"] as? String
        let statuses_count = account["statuses_count"] as? Int
        let url = account["url"] as? String
        let username = account["username"] as? String
        
        let data = AccountData(acct: acct,
                               avatar: avatar,
                               avatar_static: avatar_static,
                               bot: bot,
                               created_at: created_at,
                               display_name: display_name,
                               emojis: emojis,
                               fields: fields,
                               followers_count: followers_count,
                               following_count: following_count,
                               header: header,
                               header_static: header_static,
                               id: id,
                               locked: locked,
                               note: note,
                               statuses_count: statuses_count,
                               url: url,
                               username: username)
        return data
    }
    
    static func analyzeRelationshipJson(json: [String: Any]) -> RelationshipData {
        let id = json["id"] as? String
        let following = json["following"] as? Int
        let followed_by = json["followed_by"] as? Int
        let blocking = json["blocking"] as? Int
        let muting = json["muting"] as? Int
        let muting_notifications = json["muting_notifications"] as? Int
        let requested = json["requested"] as? Int
        let domain_blocking = json["domain_blocking"] as? Int
        let showing_reblogs = json["showing_reblogs"] as? Int
        let endorsed = json["endorsed"] as? Int
        
        let data = RelationshipData(id: id,
                                    following: following,
                                    followed_by: followed_by,
                                    blocking: blocking,
                                    muting: muting,
                                    muting_notifications: muting_notifications,
                                    requested: requested,
                                    domain_blocking: domain_blocking,
                                    showing_reblogs: showing_reblogs,
                                    endorsed: endorsed)
        return data
    }
    
    static func emptyContentData() -> ContentData {
        return ContentData(accountId: "",
                           application: nil,
                           content: nil,
                           created_at: nil,
                           emojis: nil,
                           favourited: nil,
                           favourites_count: nil,
                           id: nil,
                           in_reply_to_account_id: nil,
                           in_reply_to_id: nil,
                           language: nil,
                           mediaData: nil,
                           mentions: nil,
                           muted: nil,
                           reblog_acct: nil,
                           reblog_created_at: nil,
                           reblog_id: nil,
                           reblogged: nil,
                           reblogs_count: nil,
                           replies_count: nil,
                           sensitive: nil,
                           spoiler_text: nil,
                           url: nil,
                           visibility: nil,
                           isMerge: false)
    }
    
    // トゥートした人の情報 (あるいはブーストした人)
    struct AccountData {
        let acct: String?
        let avatar: String?
        let avatar_static: String?
        let bot: Int?
        let created_at: String?
        let display_name: String?
        let emojis: [[String: Any]]?
        let fields: [[String: Any]]?
        let followers_count: Int?
        let following_count: Int?
        let header: String?
        let header_static: String?
        let id: String? // 数値のID
        let locked: Int?
        let note: String?
        let statuses_count: Int?
        let url: String?
        let username: String?
    }
    
    // トゥート内容
    struct ContentData {
        let accountId: String
        let application: [String: Any]?
        let content: String?
        let created_at: String?
        let emojis: [[String: Any]]?
        let favourited: Int?
        let favourites_count: Int?
        let id: String? // 数値のID
        let in_reply_to_account_id: String?
        let in_reply_to_id: String?
        let language: String?
        let mediaData: [MediaData]?
        let mentions: [MentionData]?
        let muted: Int?
        let reblog_acct: String?
        let reblog_created_at: String?
        let reblog_id: String?
        let reblogged: Int?
        let reblogs_count: Int?
        let replies_count: Int?
        let sensitive: Int?
        let spoiler_text: String?
        //let tags: [String]?
        //let uri: String?
        let url: String?
        let visibility: String?
        var isMerge: Bool
    }
    
    // 添付画像、動画
    struct MediaData {
        let id: Int64?
        let preview_url: String?
        let type: String?
        let url: String?
        let remote_url: String?
    }
    
    // メンション
    struct MentionData {
        let acct: String?
        let id: String? // 数値のID
        let url: String?
        let username: String?
    }
    
    // 通知
    struct NotificationData {
        let id: String?
        let type: String?
        let created_at: String?
        let account: AccountData?
        let status: ContentData?
    }
    
    // リスト
    struct ListData {
        let id: String?
        let title: String?
    }
    
    // フォロー関係
    struct RelationshipData {
        let id: String?
        let following: Int?
        let followed_by: Int?
        let blocking: Int?
        let muting: Int?
        let muting_notifications: Int?
        let requested: Int?
        let domain_blocking: Int?
        let showing_reblogs: Int?
        let endorsed: Int?
    }
}