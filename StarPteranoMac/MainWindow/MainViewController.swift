//
//  MainViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class MainViewController: NSViewController {
    static weak var instance: MainViewController?
    var timelineList: [String: TimeLineViewController] = [:]
    private var subVCList: [SubViewController] = []
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        self.view = NSView()
        self.view.needsLayout = true
        self.view.frame.size = MainWindow.window?.frame.size ?? NSSize(width: 0, height: 0)
        
        for account in SettingsData.accountList {
            let subVC = SubViewController(hostName: account.0, accessToken: account.1)
            self.subVCList.append(subVC)
            self.view.addSubview(subVC.view)
            self.addChild(subVC)
            
            subVC.view.needsLayout = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayout() {
        guard let size = MainWindow.window?.frame.size else { return }
        
        for (index, subVC) in self.subVCList.enumerated() {
            subVC.view.frame = NSRect(x: size.width * CGFloat(index) / CGFloat(self.subVCList.count),
                                      y: 0,
                                      width: size.width / CGFloat(self.subVCList.count),
                                      height: size.height)
        }
    }
}
