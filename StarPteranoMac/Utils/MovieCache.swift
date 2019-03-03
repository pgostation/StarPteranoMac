//
//  MovieCache.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import AVFoundation

final class MovieCache {
    private static var waitingDict: [String: [(AVPlayer?, Any?, Any?)->Void]] = [:] // AVPlayer or AVPlayerLooper
    private static let fileManager = FileManager()
    private static let imageQueue = DispatchQueue(label: "MovieCache")
    private static let imageGlobalQueue = DispatchQueue.global()
    
    static func movie(urlStr: String?, callback: @escaping (AVPlayer?, Any?, Any?)->Void) {
        guard let urlStr = urlStr else { return }
        
        // ストレージキャッシュにある場合
        let cacheDir = NSHomeDirectory() + "/Library/Caches/StarPteranoMac"
        let filePath = cacheDir + "/" + urlStr.replacingOccurrences(of: "/", with: "|")
        if fileManager.fileExists(atPath: filePath) {
            imageGlobalQueue.async {
                let url = URL(fileURLWithPath: filePath)
                var player: AVPlayer? = nil
                var queuePlayer: Any? = nil
                var playerLooper: Any? = nil
                if #available(OSX 10.12, *) {
                    let playerItem = AVPlayerItem(url: url)
                    queuePlayer = AVQueuePlayer(items: [playerItem])
                    playerLooper = AVPlayerLooper(player: queuePlayer as! AVQueuePlayer, templateItem: playerItem)
                } else {
                    player = AVPlayer(url: url)
                }
                DispatchQueue.main.async {
                    callback(player, queuePlayer, playerLooper)
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
                var player: AVPlayer? = nil
                var queuePlayer: Any? = nil
                var playerLooper: Any? = nil
                if #available(OSX 10.12, *) {
                    let playerItem = AVPlayerItem(url: url)
                    queuePlayer = AVQueuePlayer(items: [playerItem])
                    playerLooper = AVPlayerLooper(player: queuePlayer as! AVQueuePlayer, templateItem: playerItem)
                } else {
                    player = AVPlayer(url: url)
                }
                DispatchQueue.main.async {
                    callback(player, queuePlayer, playerLooper)
                    
                    for waitingCallback in waitingDict[urlStr] ?? [] {
                        waitingCallback(player, queuePlayer, playerLooper)
                    }
                    
                    waitingDict.removeValue(forKey: urlStr)
                }
                
                // ストレージにキャッシュする
                let fileUrl = URL(fileURLWithPath: filePath)
                try? data.write(to: fileUrl)
                
                // ストレージの古いファイルを削除する
                let cacheDirUrl = URL(fileURLWithPath: cacheDir)
                let urls = try? fileManager.contentsOfDirectory(at: cacheDirUrl, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
                let nowDate = Date()
                for url in urls ?? [] {
                    if let attr = try? fileManager.attributesOfItem(atPath: url.path) {
                        if let fileDate = attr[FileAttributeKey.modificationDate] as? Date {
                            let time: Double = 3600
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
    }
}
