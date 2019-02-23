//
//  LeakCounter.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/18.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class LeakCounter {
    private init() {}
    
    private static var dict: [String: Int] = [:]
    private static var alerted: [String: Bool] = [:]
    private static let queue = DispatchQueue.global()
    
    static func add(_ str: String) {
        queue.async {
            dict[str] = (dict[str] ?? 0) + 1
            
            if dict[str]! > 200 && alerted[str] != true {
                print("#### \(str).count = \(dict[str]!)")
                
                print("#### dict = \(dict)")
                
                alerted[str] = true
            }
        }
    }
    
    static func sub(_ str: String) {
        queue.async {
            dict[str] = (dict[str] ?? 0) - 1
        }
    }
}

class MyImageView: NSImageView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        LeakCounter.add("MyImageView")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        LeakCounter.sub("MyImageView")
    }
}

class MyTextField: NSTextField {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        LeakCounter.add("MyTextField")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        LeakCounter.sub("MyTextField")
    }
}
