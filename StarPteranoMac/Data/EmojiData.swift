//
//  EmojiData.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/22.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Foundation

final class EmojiData {
    private static var cacheData: [String: [EmojiStruct]] = [:]
    private static var waitingList: [String] = []
    
    static func getEmojiCache(host: String, accessToken: String, showHiddenEmoji: Bool) -> [EmojiStruct] {
        var list = getEmojiCacheAll(host: host, accessToken: accessToken)
        
        if showHiddenEmoji {
            return list
        }
        
        // 隠し絵文字を省く
        for (index, data) in list.enumerated().reversed() {
            if data.visible_in_picker != 1 {
                list.remove(at: index)
            }
        }
        
        return list
    }
    
    private static func getEmojiCacheAll(host: String, accessToken: String) -> [EmojiStruct] {
        // メモリキャッシュにある場合それを返す
        if let list = cacheData[host] {
            return list
        }
        
        if !waitingList.contains(host) {
            waitingList.append(host)
            // ネットに取りに行く
            guard let url = URL(string: "https://\(host)/api/v1/custom_emojis") else { return [] }
            try? MastodonRequest.get(url: url, accessToken: accessToken) { (data, response, error) in
                if let data = data {
                    do {
                        let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Array<AnyObject>
                        
                        if let responseJson = responseJson {
                            var list: [EmojiStruct] = []
                            
                            for json in responseJson {
                                let short_code = json["shortcode"] as? String
                                let static_url = json["static_url"] as? String
                                let url = json["url"] as? String
                                let visible_in_picker = json["visible_in_picker"] as? Int
                                
                                let data = EmojiStruct(short_code: short_code,
                                                       static_url: static_url,
                                                       url: url,
                                                       visible_in_picker: visible_in_picker)
                                list.append(data)
                            }
                            
                            cacheData.updateValue(list, forKey: host)
                            
                            for (index, key) in self.waitingList.enumerated() {
                                if host == key {
                                    self.waitingList.remove(at: index)
                                }
                            }
                        }
                    } catch {
                    }
                } else if let error = error {
                    print(error)
                }
            }
        }
        
        return []
    }
    
    struct EmojiStruct {
        let short_code: String?
        let static_url: String?
        let url: String?
        let visible_in_picker: Int?
    }
}
