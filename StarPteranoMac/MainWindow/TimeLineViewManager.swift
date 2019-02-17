//
//  TimeLineViewManager.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/31.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class TimeLineViewManager {
    private static var list: [String: TimeLineViewController] = [:]
    
    static func get(key: String) -> TimeLineViewController? {
        return list[key]
    }
    
    static func set(key: String, vc: TimeLineViewController) {
        list[key] = vc
    }
    
    static func makeKey(hostName: String, accessToken: String, type: SettingsData.TLMode, option: String? = nil) -> String {
        switch type {
        case.list, .users, .notifications:
            return hostName + "_" + accessToken + "_" + type.rawValue + "_" + (option ?? "")
        default:
            return hostName + "_" + accessToken + "_" + type.rawValue
        }
    }
    
    // 選択中のTLを返す
    static func getLastSelectedTLView() -> TimeLineViewController? {
        var date: Date? = nil
        var selected: TimeLineViewController? = nil
        
        for vc in list.values {
            if let view = vc.view as? TimeLineView {
                if date == nil || view.selectedDate > date! {
                    date = view.selectedDate
                    selected = vc
                }
            }
        }
        
        return selected
    }
}
