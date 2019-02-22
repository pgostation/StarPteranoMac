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
    private static var memCache: [String: NSImage] = [:]
    private static var oldMemCache: [String: NSImage] = [:]
    private static var waitingDict: [String: [(NSImage)->Void]] = [:]
    private static let fileManager = FileManager()
    private static let imageQueue = DispatchQueue(label: "ImageCache")
    private static let webpDecoder = SDWebImageWebPCoder()
    
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
            cacheDir = NSHomeDirectory() + "/Library/Caches/StarPteranoMac/preview"
            try? fileManager.createDirectory(atPath: cacheDir, withIntermediateDirectories: true, attributes: nil)
        } else {
            cacheDir = NSHomeDirectory() + "/Library/Caches/StarPteranoMac"
            try? fileManager.createDirectory(atPath: cacheDir, withIntermediateDirectories: true, attributes: nil)
        }
        let filePath = cacheDir + "/" + urlStr.replacingOccurrences(of: "/", with: "|")
        if fileManager.fileExists(atPath: filePath) {
            imageQueue.async {
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
                        memCache.updateValue(smallImage, forKey: urlStr)
                        DispatchQueue.main.async {
                            callback(image)
                        }
                        
                        if memCache.count >= 120 { // メモリの使いすぎを防ぐ
                            oldMemCache = memCache
                            memCache = [:]
                        }
                    } else if let image = webpDecoder.decodedImage(with: data) {
                        memCache.updateValue(image, forKey: urlStr)
                        DispatchQueue.main.async {
                            callback(image)
                        }
                        
                        if memCache.count >= 120 { // メモリの使いすぎを防ぐ
                            oldMemCache = memCache
                            memCache = [:]
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
                DispatchQueue.main.async {
                    if let image = EmojiImage(data: data) {
                        let smallImage = isSmall ? ImageUtils.small(image: image, size: 50) : image
                        smallImage.shortcode = shortcode
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
                    } else if let image = webpDecoder.decodedImage(with: data) {
                        memCache.updateValue(image, forKey: urlStr)
                        callback(image)
                        
                        if memCache.count >= 120 { // メモリの使いすぎを防ぐ
                            oldMemCache = memCache
                            memCache = [:]
                        }
                        
                        // ストレージにキャッシュする
                        let fileUrl = URL(fileURLWithPath: filePath)
                        try? data.write(to: fileUrl)
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
    
    static func isNormal(urlStr: String?) -> Bool {
        guard let urlStr = urlStr else { return true }
        return userDefault?.bool(forKey: urlStr) == true
    }
}
