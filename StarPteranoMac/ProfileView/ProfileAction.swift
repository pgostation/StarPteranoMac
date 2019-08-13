//
//  ProfileAction.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/26.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class ProfileAction {
    static weak var timelineView: TimeLineView? = nil
    
    private init() {}
    
    static func unfollow(id: String, hostName: String, accessToken: String) {
        let url = URL(string: "https://\(hostName)/api/v1/accounts/\(id)/unfollow")!
        
        try? MastodonRequest.post(url: url, accessToken: accessToken, body: [:]) { (data, response, error) in
            if let data = data, data.count > 0 {
                refresh()
            } else {
            }
        }
    }
    
    static func follow(id: String, hostName: String, accessToken: String) {
        let url = URL(string: "https://\(hostName)/api/v1/accounts/\(id)/follow")!
        
        try? MastodonRequest.post(url: url, accessToken: accessToken, body: [:]) { (data, response, error) in
            if let data = data, data.count > 0 {
                refresh()
            }
        }
    }
    
    static func unmute(id: String, hostName: String, accessToken: String) {
        let url = URL(string: "https://\(hostName)/api/v1/accounts/\(id)/unmute")!
        
        try? MastodonRequest.post(url: url, accessToken: accessToken, body: [:]) { (data, response, error) in
            if let data = data, data.count > 0 {
                refresh()
            }
        }
    }
    
    static func mute(id: String, hostName: String, accessToken: String) {
        let url = URL(string: "https://\(hostName)/api/v1/accounts/\(id)/mute")!
        
        try? MastodonRequest.post(url: url, accessToken: accessToken, body: [:]) { (data, response, error) in
            if let data = data, data.count > 0 {
                refresh()
            }
        }
    }
    
    // 通知もミュートする
    static func muteAlsoNotify(id: String, hostName: String, accessToken: String) {
        let url = URL(string: "https://\(hostName)/api/v1/accounts/\(id)/mute")!
        
        try? MastodonRequest.post(url: url, accessToken: accessToken, body: [:]) { (data, response, error) in
            if let data = data, data.count > 0 {
                refresh()
            }
        }
    }
    
    static func unblock(id: String, hostName: String, accessToken: String) {
        let url = URL(string: "https://\(hostName)/api/v1/accounts/\(id)/unblock")!
        
        try? MastodonRequest.post(url: url, accessToken: accessToken, body: [:]) { (data, response, error) in
            if let data = data, data.count > 0 {
                refresh()
            }
        }
    }
    
    static func block(id: String, hostName: String, accessToken: String) {
        let url = URL(string: "https://\(hostName)/api/v1/accounts/\(id)/block")!
        
        try? MastodonRequest.post(url: url, accessToken: accessToken, body: [:]) { (data, response, error) in
            if let data = data, data.count > 0 {
                refresh()
            }
        }
    }
    
    static func hideBoost(id: String, hostName: String, accessToken: String) {
        let url = URL(string: "https://\(hostName)/api/v1/accounts/\(id)/follow")!
        
        try? MastodonRequest.post(url: url, accessToken: accessToken, body: ["reblogs": 0]) { (data, response, error) in
            if let data = data, data.count > 0 {
                refresh()
            }
        }
    }
    
    static func showBoost(id: String, hostName: String, accessToken: String) {
        let url = URL(string: "https://\(hostName)/api/v1/accounts/\(id)/follow")!
        
        try? MastodonRequest.post(url: url, accessToken: accessToken, body: ["reblogs": 1]) { (data, response, error) in
            if let data = data, data.count > 0 {
                refresh()
            }
        }
    }
    
    // プロフィールのセルを再読み込み
    private static func refresh() {
        DispatchQueue.main.async {
            if let view = self.timelineView {
                if view.type == .user {
                    view.reloadData(forRowIndexes: IndexSet(integer: 0), columnIndexes: IndexSet())
                }
            }
        }
    }
}
