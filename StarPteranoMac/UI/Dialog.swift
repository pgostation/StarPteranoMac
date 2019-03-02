//
//  Dialog.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/26.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class Dialog {
    // OKボタンだけのダイアログを表示
    static func show(message: String, window: NSWindow? = nil) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = message
            
            if let window = window {
                alert.beginSheetModal(for: window, completionHandler: nil)
            } else {
                alert.runModal()
            }
        }
    }
    
    // 2ボタンのダイアログを表示
    static func show(message: String, window: NSWindow? = nil, okName: String, cancelName: String, callback: @escaping (Bool)->Void) {
        let alert = NSAlert()
        alert.messageText = message
        
        alert.addButton(withTitle: okName)
        alert.addButton(withTitle: cancelName)
        
        if let window = window {
            alert.beginSheetModal(for: window, completionHandler: { result in
                callback(result == .alertFirstButtonReturn)
            })
        } else {
            let result = alert.runModal()
            callback(result == .alertFirstButtonReturn)
        }
    }
    
    // 入力欄付きのダイアログを表示
    static func showWithTextInput(message: String, window: NSWindow? = nil, okName: String, cancelName: String, defaultText: String?, callback: @escaping (NSTextField, Bool)->Void) {
        let alert = NSAlert()
        alert.messageText = message
        
        let textField = MyTextField()
        textField.stringValue = defaultText ?? ""
        alert.accessoryView = textField
        
        alert.addButton(withTitle: okName)
        alert.addButton(withTitle: cancelName)
        
        if let window = window {
            alert.beginSheetModal(for: window, completionHandler: { result in
                callback(textField, result == .alertFirstButtonReturn)
            })
        } else {
            let result = alert.runModal()
            callback(textField, result == .alertFirstButtonReturn)
        }
    }
    
    // View付きのダイアログを表示
    static func showWithView(message: String, window: NSWindow? = nil, okName: String, view: NSView) {
        let alert = NSAlert()
        alert.messageText = message
        alert.accessoryView = view
        
        alert.addButton(withTitle: okName)
        
        if let window = window {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }
}
