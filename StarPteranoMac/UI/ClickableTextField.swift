//
//  ClickableTextField.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/14.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class ClickableTextField: NSTextField {
    private var callback: (()->Void)? = nil
    
    func addTarget(callback: @escaping ()->Void) {
        self.callback = callback
    }
    
    override func mouseUp(with event: NSEvent) {
        self.callback?()
    }
}
