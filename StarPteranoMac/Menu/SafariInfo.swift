//
//  SafariInfo.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/14.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Foundation
import ScriptingBridge

@objc fileprivate protocol SafariApplication {
    @objc optional var windows: [Any] { get }
}

final class SafariInfo {
    static func get() -> Info? {
        // AppleScriptでSafariのタブ情報取得 (entitlementsとInfo.plistに権限がいる)
        let appleScript = "tell application \"Safari\"\n"
            + "  set theTab to current tab of window 1\n"
            + "  tell theTab\n"
            + "    set theResult to {name, URL}\n"
            + "  end tell\n"
            + "  return theResult\n"
            + "end tell\n"
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(&error)
            if let error = error {
                for key in error.allKeys {
                    print("\(key) = \(error.value(forKey: key as! String))")
                }
            } else {
                let info = Info(title: output.atIndex(1)?.stringValue,
                                url: output.atIndex(2)?.stringValue)
                return info
            }
        }
        
        return nil
    }
    
    struct Info {
        let title: String?
        let url: String?
    }
}

