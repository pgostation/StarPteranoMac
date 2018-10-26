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
}
