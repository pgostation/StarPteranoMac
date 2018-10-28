//
//  SubViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class SubViewController: NSViewController {
    private let popUp = NSPopUpButton()
    private let scrollView = NSScrollView()
    
    init(hostName: String, accessToken: String) {
        super.init(nibName: nil, bundle: nil)
        
        self.view = NSView()
        
        self.view.addSubview(popUp)
        self.view.addSubview(scrollView)
        
        setProperties()
        
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
        
        self.view.needsLayout = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        setPopUp()
        
        scrollView.scrollerStyle = .legacy
        scrollView.hasVerticalScroller = true
    }
    
    private func setPopUp() {
        let menu = NSMenu()
        popUp.menu = menu
        
        // ホーム、ローカル、ローカル + ホーム、連合
        do {
            let menuItems = ["ACTION_HOME", "ACTION_LOCAL", "ACTION_LOCAL_HOME", "ACTION_FEDERATION"]
            for str in menuItems {
                let menuItem = NSMenuItem(title: I18n.get(str),
                                          action: #selector(menuAction(_:)),
                                          keyEquivalent: "")
                menu.addItem(menuItem)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // リスト
        do {
            let menuItem = NSMenuItem(title: I18n.get("ACTION_LIST"),
                                      action: #selector(menuAction(_:)),
                                      keyEquivalent: "")
            menu.addItem(menuItem)
            
            let subMenu = NSMenu(title: I18n.get("ACTION_LIST"))
            menuItem.submenu = subMenu
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // 通知、メンション、DM、お気に入り、検索、ユーザー指定
        do {
            let menuItems = ["ACTION_NOTIFICATIONS", "ACTION_MENTIONS", "ACTION_DM", "ACTION_FAVORITES", "ACTION_SEARCH", "ACTION_USERS"]
            for str in menuItems {
                let menuItem = NSMenuItem(title: I18n.get(str),
                                          action: #selector(menuAction(_:)),
                                          keyEquivalent: "")
                menu.addItem(menuItem)
            }
        }
    }
    
    @objc func menuAction(_ menuItem: NSMenuItem) {
        
    }
    
    override func viewDidLayout() {
        popUp.frame = NSRect(x: 0,
                             y: self.view.frame.height - 32,
                             width: min(300, self.view.frame.width),
                             height: 32)
        
        scrollView.frame = NSRect(x: 0,
                                  y: 0,
                                  width: self.view.frame.width,
                                  height: self.view.frame.height - 32)
    }
}
