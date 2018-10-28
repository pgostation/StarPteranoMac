//
//  SubViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class SubViewController: NSViewController {
    init(hostName: String, accessToken: String) {
        super.init(nibName: nil, bundle: nil)
        
        let scrollView = NSScrollView()
        scrollView.scrollerStyle = .legacy
        scrollView.hasVerticalScroller = true
        self.view = scrollView
        
        let timelineVC: TimeLineViewController
        switch SettingsData.tlMode(key: hostName + "," + accessToken) {
        case .home:
            timelineVC = TimeLineViewController(hostName: hostName, accessToken: accessToken, type: .home)
        case .local:
            timelineVC = TimeLineViewController(hostName: hostName, accessToken: accessToken, type: .local)
        case .federation:
            timelineVC = TimeLineViewController(hostName: hostName, accessToken: accessToken, type: .federation)
        case .list:
            timelineVC = TimeLineViewController(hostName: hostName, accessToken: accessToken, type: .list)
        }
        
        scrollView.documentView = timelineVC.view
        self.addChild(timelineVC)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
