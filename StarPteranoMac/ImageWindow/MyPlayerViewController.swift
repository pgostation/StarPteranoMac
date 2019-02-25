//
//  MyPlayerViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/28.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa
import AVKit

final class MyPlayerViewController: NSViewController {
    var player: AVPlayer?
    var movieLayer: AVPlayerLayer?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        self.view = MyPlayerView()
        self.view.wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class MyPlayerView: NSView {
    override func layout() {
        self.layer?.sublayers?.first?.frame = self.frame
    }
}
