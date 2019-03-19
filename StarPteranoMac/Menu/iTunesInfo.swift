//
//  iTunesInfo.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/14.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa
import ScriptingBridge

// iTunesの再生中の曲情報 (AppleScriptを使う方法)
// https://stackoverflow.com/questions/50087508/swift-macos-app-that-displays-itunes-album-artwork-hangs-on-non-square-images

// iTunesの再生中の曲情報 (Notificationを使う方法)
// https://blog.nishimu.land/entry/2016/04/19/090000

final class iTunesInfo {
    private static var currentTrack: Info? = nil
    
    // 保持している現在のトラックを返す
    static func get() -> Info? {
        // AppleScriptでiTUnesの再生情報取得 (entitlementsとInfo.plistに権限がいる)
        let appleScript = "tell application \"iTunes\"\n"
            + "  try\n"
            + "      set currentTitle to name of current track\n"
            + "      set currentArtist to artist of current track\n"
            + "      set currentAlbum to album of current track\n"
            + "      if count of artwork of current track > 0 then\n"
            + "        set currentArtwork to raw data of front artwork of current track\n"
            + "      else\n"
            + "        set currentArtwork to null\n"
            + "      end if\n"
            + "  set theResult to {currentTitle, currentArtist, currentAlbum, currentArtwork}\n"
            + "    return theResult\n"
            + "  end try\n"
            + "end tell\n"
    
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(&error)
            if let error = error {
                for key in error.allKeys {
                    print("\(key) = \(String(describing: error.value(forKey: key as! String)))")
                }
            } else {
                // アートワーク情報
                let artworkImage: NSImage?
                if let data = output.atIndex(4)?.data {
                    artworkImage = NSImage(data: data)
                } else {
                    artworkImage = nil
                }
                
                // infoをセット
                let info = Info(title: output.atIndex(1)?.stringValue,
                                album: output.atIndex(2)?.stringValue,
                                artist: output.atIndex(3)?.stringValue,
                                artwork: artworkImage)
                return info
            }
        }
        
        // AppleScriptで失敗しても、Notificationからの情報を使う
        return currentTrack
    }
    
    // 通知から現在のトラックを記憶しておく
    static func set(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        currentTrack = Info(title: userInfo["Name"] as? String,
                            album: userInfo["Album"] as? String,
                            artist: userInfo["Artist"] as? String,
                            artwork: nil)
    }
    
    struct Info {
        let title: String?
        let album: String?
        let artist: String?
        let artwork: NSImage?
    }
}
