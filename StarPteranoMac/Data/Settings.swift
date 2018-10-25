//
//  Settings.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/24.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class Settings {
    private static let defaults = UserDefaults(suiteName: "Settings")!
    
    // 接続が確認されたアカウントの情報を保持
    static var accountList: [(String, String)] {
        get {
            var list: [(String, String)] = []
            let array = defaults.array(forKey: "accountList")
            
            for str in array as? [String] ?? [] {
                let items = str.split(separator: ",")
                if items.count < 2 { continue }
                list.append((String(items[0]), String(items[1])))
            }
            
            return list
        }
        set(newValue) {
            var array: [String] = []
            
            for data in newValue {
                array.append(data.0 + "," + data.1)
            }
            
            defaults.set(array, forKey: "accountList")
        }
    }
}
