//
//  ImageCache.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa
import APNGKit

final class ImageCache {
    private static let scale = NSScreen.main?.backingScaleFactor ?? 1
    private static var memCache: [String: NSImage] = [:]
    private static var oldMemCache: [String: NSImage] = [:]
    private static var waitingDict: [String: [(NSImage)->Void]] = [:]
    private static let fileManager = FileManager()
    private static let imageQueue = DispatchQueue(label: "ImageCache")
    private static let imageGlobalQueue = DispatchQueue.global()
    
    // 画像をキャッシュから取得する。なければネットに取りに行く
    static func image(urlStr: String?, isTemp: Bool, isSmall: Bool, shortcode: String? = nil, isPreview: Bool = false, callback: @escaping (NSImage)->Void) {
        guard let urlStr = urlStr else { return }
        
        // メモリキャッシュにある場合
        if let image = memCache[urlStr] {
            if image.size.width > 50 * self.scale || isSmall {
                callback(image)
                return
            }
        }
        // 破棄候補のメモリキャッシュにある場合
        if let image = oldMemCache[urlStr] {
            if image.size.width > 50 * self.scale || isSmall {
                memCache[urlStr] = image
                oldMemCache.removeValue(forKey: urlStr)
                callback(image)
                return
            }
        }
        
        // ストレージキャッシュにある場合
        let cacheDir: String
        if isTemp {
            cacheDir = NSHomeDirectory() + "/Library/Caches/preview"
            try? fileManager.createDirectory(atPath: cacheDir, withIntermediateDirectories: true, attributes: nil)
        } else {
            cacheDir = NSHomeDirectory() + "/Library/Caches"
            try? fileManager.createDirectory(atPath: cacheDir, withIntermediateDirectories: true, attributes: nil)
        }
        let filePath = cacheDir + "/" + urlStr.replacingOccurrences(of: "/", with: "|")
        if fileManager.fileExists(atPath: filePath) {
            imageGlobalQueue.async {
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
                        DispatchQueue.main.async {
                            memCache.updateValue(smallImage, forKey: urlStr)
                            callback(image)
                            
                            if memCache.count >= 120 { // メモリの使いすぎを防ぐ
                                oldMemCache = memCache
                                memCache = [:]
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
        imageQueue.async {
            guard let url = URL(string: urlStr) else { return }
            if let data = try? Data(contentsOf: url) {
                if let image = EmojiImage(data: data) {
                    let smallImage = isSmall ? ImageUtils.small(image: image, size: 50) : image
                    smallImage.shortcode = shortcode
                    DispatchQueue.main.async {
                        if !isTemp {
                            memCache.updateValue(smallImage, forKey: urlStr)
                        }
                        callback(image)
                        
                        for waitingCallback in waitingDict[urlStr] ?? [] {
                            waitingCallback(image)
                        }
                        
                        waitingDict.removeValue(forKey: urlStr)
                        
                        if memCache.count >= 120 { // メモリの使いすぎを防ぐ
                            oldMemCache = memCache
                            memCache = [:]
                        }
                    }
                    
                    // ストレージにキャッシュする
                    let fileUrl = URL(fileURLWithPath: filePath)
                    try? data.write(to: fileUrl)
                    
                    // ストレージの古いファイルを削除する
                    if isTemp {
                        let cacheDirUrl = URL(fileURLWithPath: cacheDir)
                        let urls = try? fileManager.contentsOfDirectory(at: cacheDirUrl, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
                        let nowDate = Date()
                        for url in urls ?? [] {
                            if let attr = try? fileManager.attributesOfItem(atPath: url.path) {
                                if let fileDate = attr[FileAttributeKey.creationDate] as? Date {
                                    if nowDate.timeIntervalSince(fileDate) > 86400 {
                                        try? fileManager.removeItem(at: url)
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                waitingDict.removeValue(forKey: urlStr)
            }
        }
    }
    
    static func clear() {
        oldMemCache = [:]
    }
}

final class APNGImageCache {
    private static var memCache: [String: APNGImage] = [:]
    private static var oldMemCache: [String: APNGImage] = [:]
    private static var waitingDict: [String: [(APNGImage)->Void]] = [:]
    private static let fileManager = FileManager()
    private static let imageQueue = DispatchQueue(label: "APNGImageCache")
    private static let imageGlobalQueue = DispatchQueue.global()
    
    static func image(urlStr: String?, callback: @escaping (APNGImage)->Void) {
        guard let urlStr = urlStr else { return }
        
        // メモリキャッシュにある場合
        if let image = memCache[urlStr] {
            callback(image)
            return
        }
        // 破棄候補のメモリキャッシュにある場合
        if let image = oldMemCache[urlStr] {
            memCache[urlStr] = image
            oldMemCache.removeValue(forKey: urlStr)
            callback(image)
            return
        }
        
        // ストレージキャッシュにある場合
        let cacheDir = NSHomeDirectory() + "/Library/Caches"
        let filePath = cacheDir + "/" + urlStr.replacingOccurrences(of: "/", with: "|")
        if fileManager.fileExists(atPath: filePath) {
            imageGlobalQueue.async {
                let url = URL(fileURLWithPath: filePath)
                if let data = try? Data(contentsOf: url) {
                    if let image = APNGImage(data: data) {
                        DispatchQueue.main.async {
                            memCache.updateValue(image, forKey: urlStr)
                            callback(image)
                            
                            if memCache.count >= 40 { // メモリの使いすぎを防ぐ
                                oldMemCache = memCache
                                memCache = [:]
                                APNGCache.defaultCache.clearMemoryCache()
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
        imageQueue.async {
            guard let url = URL(string: urlStr) else { return }
            if let data = try? Data(contentsOf: url) {
                if let image = APNGImage(data: data) {
                    DispatchQueue.main.async {
                        memCache.updateValue(image, forKey: urlStr)
                        callback(image)
                        
                        for waitingCallback in waitingDict[urlStr] ?? [] {
                            waitingCallback(image)
                        }
                        
                        waitingDict.removeValue(forKey: urlStr)
                        
                        if memCache.count >= 40 { // メモリの使いすぎを防ぐ
                            oldMemCache = memCache
                            memCache = [:]
                            APNGCache.defaultCache.clearMemoryCache()
                        }
                    }
                    
                    // ストレージにキャッシュする
                    let fileUrl = URL(fileURLWithPath: filePath)
                    try? data.write(to: fileUrl)
                }
            }
        }
    }
    
    static func clear() {
        oldMemCache = [:]
    }
}
