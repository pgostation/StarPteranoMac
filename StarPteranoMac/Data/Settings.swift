//
//  Settings.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/24.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

class Settings {
    private static let defaults = UserDefaults(suiteName: "Settings")!
    
    static var hostName: String? {
        get {
            return defaults.string(forKey: "hostName")
        }
        set(newValue) {
            defaults.set(newValue, forKey: "hostName")
        }
    }
}
