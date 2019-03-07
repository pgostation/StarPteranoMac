//
//  HashtagCache.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/07.
//  Copyright © 2019 pgostation. All rights reserved.
//

// 最近TLで見たハッシュタグを保持する

import Foundation

final class HashtagCache {
    private static var cache: [String: [String]] = [:]
    private static var oldCache: [String: [String]] = [:]
    
    static var recentHashtagList: [String] {
        return (cache[""] ?? []) + (oldCache[""] ?? [])
    }
    
    static func addHashtagList(text: String) {
        let accessToken = ""
        
        if cache[accessToken] == nil {
            cache[accessToken] = []
        }
        
        // キャッシュに未登録であれば登録する
        if cache[accessToken]?.firstIndex(of: text) == nil {
            cache[accessToken]?.append(text)
            
            // oldCacheにあれば削除する
            if let index = oldCache[accessToken]?.firstIndex(of: text) {
                oldCache[accessToken]?.remove(at: index)
            }
            
            // 登録数が100を超えるとoldCacheに移す
            if let count = cache[accessToken]?.count, count > 100 {
                oldCache[accessToken] = cache[accessToken]
                cache[accessToken] = []
            }
        }
    }
}
