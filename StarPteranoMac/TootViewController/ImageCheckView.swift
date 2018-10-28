//
//  ImageCheckView.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/28.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class ImageCheckView: NSView {
    private let nsfwLabel = NSTextField()
    let nsfwSw = NSButton()
    var urls: [URL] = []
    private var imageViews: [NSView] = []
    private var deleteButtons: [NSButton] = []
    
}
