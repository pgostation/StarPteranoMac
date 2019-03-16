//
//  iTunesInfo.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/14.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa
import AVFoundation

// iTunesの再生中の曲情報
// https://blog.nishimu.land/entry/2016/04/19/090000

final class iTunesInfo {
    private static var currentTrack: Info? = nil
    
    // 保持している現在のトラックを返す
    static func get() -> Info? {
        return currentTrack
    }
    
    // 通知から現在のトラックを記憶しておく
    static func set(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        currentTrack = Info(title: userInfo["Name"] as? String,
                            album: userInfo["Album"] as? String,
                            artist: userInfo["Artist"] as? String,
                            location: userInfo["Location"] as? String,
                            artwork: nil)
    }
    
    struct Info {
        let title: String?
        let album: String?
        let artist: String?
        let location: String?
        let artwork: NSImage?
    }
}