//
//  I18n.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/23.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class I18n {
    static func get(_ text: String) -> String {
        return NSLocalizedString(text, comment: "")
    }
}
