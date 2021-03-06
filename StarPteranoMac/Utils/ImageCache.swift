//
//  ImageCache.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa
import SDWebImage
import SDWebImageAPNGCoder
import APNGKit

final class ImageCache {
    private static let scale = NSScreen.main?.backingScaleFactor ?? 1
    private static var memCache: [String: (NSImage, URL?)] = [:]
    private static var oldMemCache: [String: (NSImage, URL?)] = [:]
    private static var waitingDict: [String: [(NSImage, URL?)->Void]] = [:]
    private static let fileManager = FileManager()
    private static let imageQueue = DispatchQueue(label: "ImageCache")
    private static let imageParallelQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
    private static let webpDecoder = SDWebImageWebPCoder()
    private static var deleteCacheDate: Date?
    
    // 画像をキャッシュから取得する。なければネットに取りに行く
    static func image(urlStr: String?, isTemp: Bool, isSmall: Bool, shortcode: String? = nil, isPreview: Bool = false, isThread: Bool = false, callback: @escaping (NSImage, URL?)->Void) {
        guard let urlStr = urlStr else { return }
        
        // メモリキャッシュにある場合
        if let (image, url) = memCache[urlStr] {
            if image.size.width > 50 * self.scale || isSmall {
                callback(image, url)
                return
            }
        }
        // 破棄候補のメモリキャッシュにある場合
        if let (image, url) = oldMemCache[urlStr] {
            if image.size.width > 50 * self.scale || isSmall {
                memCache[urlStr] = (image, url)
                oldMemCache.removeValue(forKey: urlStr)
                callback(image, url)
                return
            }
        }
        
        // ストレージキャッシュにある場合
        let cacheDir: String
        if isTemp {
            cacheDir = NSHomeDirectory() + "/Library/Caches/StarPteranoMac/preview"
            try? fileManager.createDirectory(atPath: cacheDir, withIntermediateDirectories: true, attributes: nil)
        } else {
            cacheDir = NSHomeDirectory() + "/Library/Caches/StarPteranoMac"
            try? fileManager.createDirectory(atPath: cacheDir, withIntermediateDirectories: true, attributes: nil)
        }
        let filePath = cacheDir + "/" + urlStr.replacingOccurrences(of: "/", with: "|")
        if fileManager.fileExists(atPath: filePath) {
            (isThread ? imageQueue : DispatchQueue.main).async {
                let url = URL(fileURLWithPath: filePath)
                if let data = try? Data(contentsOf: url) {
                    if let image = EmojiImage(data: data) {
                        let smallImage: EmojiImage
                        if filePath.hasSuffix(".gif") {
                            smallImage = image
                        } else {
                            smallImage = isSmall ? ImageUtils.small(image: image, size: 50) : image
                        }
                        smallImage.shortcode = shortcode
                        memCache.updateValue((smallImage, url), forKey: urlStr)
                        DispatchQueue.main.async {
                            callback(image, url)
                        }
                        
                        if memCache.count >= SettingsData.ramCacheCount { // メモリの使いすぎを防ぐ
                            oldMemCache = memCache
                            memCache = [:]
                        }
                    } else if let image = webpDecoder.decodedImage(with: data) {
                        memCache.updateValue((image, url), forKey: urlStr)
                        DispatchQueue.main.async {
                            callback(image, url)
                        }
                        
                        if memCache.count >= SettingsData.ramCacheCount { // メモリの使いすぎを防ぐ
                            oldMemCache = memCache
                            memCache = [:]
                        }
                    }
                    
                    if SettingsData.useStorageCache {
                        if let attr = try? fileManager.attributesOfItem(atPath: url.path) {
                            if let fileDate = attr[FileAttributeKey.modificationDate] as? Date {
                                if fileDate.timeIntervalSinceNow < (isTemp ? -180 : -3600) {
                                    // 最終アクセス時刻を更新
                                    try? fileManager.setAttributes([FileAttributeKey.modificationDate : Date()], ofItemAtPath: url.path)
                                }
                            }
                        }
                    }
                }
            }
            return
        }
        
        // リクエスト済みの場合、コールバックリストに追加する
        if waitingDict.keys.contains(urlStr) {
            waitingDict[urlStr]?.append(callback)
            return
        }
        
        waitingDict[urlStr] = []
        
        // ネットワークに取りに行く
        imageParallelQueue.async {
            guard let url = URL(string: urlStr) else { return }
            if let data = try? Data(contentsOf: url) {
                DispatchQueue.main.async {
                    let fileUrl = URL(fileURLWithPath: filePath)
                    if let image = EmojiImage(data: data) {
                        let smallImage = isSmall ? ImageUtils.small(image: image, size: 50) : image
                        smallImage.shortcode = shortcode
                        memCache.updateValue((smallImage, fileUrl), forKey: urlStr)
                        callback(image, fileUrl)
                        
                        for waitingCallback in waitingDict[urlStr] ?? [] {
                            waitingCallback(image, fileUrl)
                        }
                        
                        waitingDict.removeValue(forKey: urlStr)
                        
                        if memCache.count >= SettingsData.ramCacheCount { // メモリの使いすぎを防ぐ
                            oldMemCache = memCache
                            memCache = [:]
                        }
                        
                        if SettingsData.useStorageCache {
                            // ストレージにキャッシュする
                            try? data.write(to: fileUrl)
                            
                            if deleteCacheDate == nil || deleteCacheDate!.timeIntervalSinceNow < -60 {
                                deleteCacheDate = Date()
                                
                                // ストレージの古いファイルを削除する
                                let cacheDirUrl = URL(fileURLWithPath: cacheDir)
                                let urls = try? fileManager.contentsOfDirectory(at: cacheDirUrl, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
                                let nowDate = Date()
                                for url in urls ?? [] {
                                    if let attr = try? fileManager.attributesOfItem(atPath: url.path) {
                                        if let fileDate = attr[FileAttributeKey.modificationDate] as? Date {
                                            let time: Double = isTemp ? 3600 : 86400 * 7
                                            if nowDate.timeIntervalSince(fileDate) > time {
                                                do {
                                                    try fileManager.removeItem(at: url)
                                                } catch {
                                                    print("delete cache file failure: \(error)")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else if let image = webpDecoder.decodedImage(with: data) {
                        memCache.updateValue((image, fileUrl), forKey: urlStr)
                        callback(image, fileUrl)
                        
                        if memCache.count >= SettingsData.ramCacheCount { // メモリの使いすぎを防ぐ
                            oldMemCache = memCache
                            memCache = [:]
                        }
                        
                        if SettingsData.useStorageCache {
                            // ストレージにキャッシュする
                            let fileUrl = URL(fileURLWithPath: filePath)
                            try? data.write(to: fileUrl)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    waitingDict.removeValue(forKey: urlStr)
                }
            }
        }
    }
    
    static func clear() {
        oldMemCache = [:]
    }
}

final class APNGImageCache {
    private static var waitingDict: [String: [(APNGImage, URL)->Void]] = [:]
    private static let fileManager = FileManager()
    private static let imageQueue = DispatchQueue(label: "APNGImageCache")
    private static let apngCoder = SDWebImageAPNGCoder.shared()
    private static let manager = SDWebImageCodersManager.sharedInstance()
    private static var firstCall = true
    
    static func image(urlStr: String?, callback: @escaping (APNGImage, URL)->Void) {
        guard let urlStr = urlStr else { return }
        
        if firstCall {
            manager.addCoder(apngCoder)
            firstCall = false
        }
        
        // ストレージキャッシュにある場合
        let cacheDir = NSHomeDirectory() + "/Library/Caches/StarPteranoMac"
        let filePath = cacheDir + "/" + urlStr.replacingOccurrences(of: "/", with: "|")
        if fileManager.fileExists(atPath: filePath) {
            imageQueue.async {
                let url = URL(fileURLWithPath: filePath)
                if let data = try? Data(contentsOf: url) {
                    if let image = APNGImage(data: data) {
                        DispatchQueue.main.async {
                            callback(image, url)
                        }
                    }
                }
            }
            return
        }
        
        // リクエスト済みの場合、コールバックリストに追加する
        if waitingDict.keys.contains(urlStr) {
            waitingDict[urlStr]?.append(callback)
            return
        }
        
        waitingDict[urlStr] = []
        
        // ネットワークに取りに行く
        imageQueue.async {
            guard let url = URL(string: urlStr) else { return }
            if let data = try? Data(contentsOf: url) {
                if let image = APNGImage(data: data) {
                    // ストレージにキャッシュする
                    let fileUrl = URL(fileURLWithPath: filePath)
                    try? data.write(to: fileUrl)
                    
                    DispatchQueue.main.async {
                        callback(image, fileUrl)
                        
                        for waitingCallback in waitingDict[urlStr] ?? [] {
                            waitingCallback(image, fileUrl)
                        }
                        
                        waitingDict.removeValue(forKey: urlStr)
                    }
                }
            }
        }
    }
    
    static func clear() {
    }
}

// APNGじゃないファイルを判定
final class NormalPNGFileList {
    private static let userDefault = UserDefaults(suiteName: "StarPteranoMac_NormalPNGFileList")
    
    static func add(urlStr: String?) {
        guard let urlStr = urlStr else { return }
        if userDefault?.bool(forKey: urlStr) == true {
            return
        }
        
        if let dict = userDefault?.dictionaryRepresentation() {
            if dict.count > 1000 {
                for key in dict.keys {
                    userDefault?.removeObject(forKey: key)
                }
            }
        }
        
        userDefault?.set(true, forKey: urlStr)
    }
    
    static func addAnime(urlStr: String?) {
        guard let urlStr = urlStr else { return }
        if userDefault?.bool(forKey: urlStr) == false {
            return
        }
        
        userDefault?.set(false, forKey: urlStr)
    }
    
    static func isNormal(urlStr: String?) -> Bool {
        guard let urlStr = urlStr else { return true }
        return userDefault?.bool(forKey: urlStr) == true
    }
    
    static func isAnime(urlStr: String?) -> Bool {
        guard let urlStr = urlStr else { return true }
        return userDefault?.bool(forKey: urlStr) == false
    }
}
