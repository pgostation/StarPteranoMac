//
//  EmojiImage.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class EmojiImage: NSImage {
    var shortcode: String? = nil
    
    override init(size: NSSize) {
        super.init(size: size)
        
        LeakCounter.add("EmojiImage")
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        fatalError("init(pasteboardPropertyList:ofType:) has not been implemented")
    }
    
    deinit {
        LeakCounter.sub("EmojiImage")
    }
}
