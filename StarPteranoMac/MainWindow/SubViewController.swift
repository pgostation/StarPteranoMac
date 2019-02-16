//
//  SubViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class SubViewController: NSViewController {
    private let hostName: String
    private let accessToken: String
    private let popUp = NSPopUpButton()
    let scrollView = NSScrollView()
    
    init(hostName: String, accessToken: String) {
        self.hostName = hostName
        self.accessToken = accessToken
        
        super.init(nibName: nil, bundle: nil)
        
        self.view = NSView()
        
        self.view.addSubview(popUp)
        self.view.addSubview(scrollView)
        
        setProperties()
        
        for (index, mode) in SettingsData.tlMode(key: hostName + "," + accessToken).enumerated() {
            switch mode {
            case .home:
                popUp.selectItem(at: 0)
            case .local:
                popUp.selectItem(at: 1)
            case .homeLocal:
                popUp.selectItem(at: 2)
            case .federation:
                popUp.selectItem(at: 3)
            case .list:
                popUp.selectItem(at: 5)
                let listOption = SettingsData.selectedListId(accessToken: accessToken, index: index)
                let key = TimeLineViewManager.makeKey(hostName: hostName, accessToken: accessToken, type: .list, option: listOption)
                let vc = TimeLineViewManager.get(key: key) ?? TimeLineViewController(hostName: hostName, accessToken: accessToken, type: .list, option: listOption)
                TimeLineViewManager.set(key: key, vc: vc)
            case .notifications:
                popUp.selectItem(at: 7)
            case .mentions:
                popUp.selectItem(at: 8)
            case .dm:
                popUp.selectItem(at: 9)
            case .favorites:
                popUp.selectItem(at: 10)
            case .search:
                popUp.selectItem(at: 11)
            case .users:
                popUp.selectItem(at: 12)
            }
            
            if let title = popUp.selectedItem?.title {
                self.doMenu(title: title)
            }
        }
        
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
                menuItem.target = self
                menu.addItem(menuItem)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // リスト
        do {
            let menuItem = NSMenuItem(title: I18n.get("ACTION_LIST"),
                                      action: #selector(menuAction(_:)),
                                      keyEquivalent: "")
            menuItem.target = self
            menu.addItem(menuItem)
            
            do {
                let subMenu = NSMenu(title: I18n.get("ACTION_LIST"))
                menuItem.submenu = subMenu
                
                subMenu.addItem(NSMenuItem.separator())
                let menuItem = NSMenuItem(title: I18n.get("ACTION_REFRESH_LIST"),
                                          action: #selector(menuAction(_:)),
                                          keyEquivalent: "")
                menuItem.target = self
                subMenu.addItem(menuItem)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // 通知、メンション、DM、お気に入り、検索、ユーザー指定
        do {
            let menuItems = ["ACTION_NOTIFICATIONS", "ACTION_MENTIONS", "ACTION_DM", "ACTION_FAVORITES", "ACTION_SEARCH", "ACTION_USERS"]
            for str in menuItems {
                let menuItem = NSMenuItem(title: I18n.get(str),
                                          action: #selector(menuAction(_:)),
                                          keyEquivalent: "")
                menuItem.target = self
                menu.addItem(menuItem)
            }
        }
    }
    
    @objc func menuAction(_ menuItem: NSMenuItem) {
        doMenu(title: menuItem.title)
    }
    
    private func doMenu(title: String) {
        func setTimeLineViewController(mode: SettingsData.TLMode) {
            let key = TimeLineViewManager.makeKey(hostName: hostName, accessToken: accessToken, type: mode)
            
            let type: TimeLineViewController.TimeLineType
            if mode == .local { type = .local }
            else if mode == .homeLocal { type = .homeLocal }
            else if mode == .federation { type = .federation }
            else { type = .home }
            
            let vc = TimeLineViewManager.get(key: key) ?? TimeLineViewController(hostName: hostName, accessToken: accessToken, type: type)
            scrollView.documentView = vc.view
            
            self.children.first?.removeFromParent()
            self.addChild(vc)
            
            TimeLineViewManager.set(key: key, vc: vc)
            
            SettingsData.setTlMode(key: hostName + "," + accessToken, modes: [mode])
        }
        
        func setTimeLineViewController(vc: TimeLineViewController) {
            scrollView.documentView = vc.view
            
            self.children.first?.removeFromParent()
            self.addChild(vc)
        }
        
        if title == I18n.get("ACTION_HOME") {
            setTimeLineViewController(mode: .home)
        } else if title == I18n.get("ACTION_LOCAL") {
            setTimeLineViewController(mode: .local)
        } else if title == I18n.get("ACTION_LOCAL_HOME") {
            setTimeLineViewController(mode: .homeLocal)
        } else if title == I18n.get("ACTION_FEDERATION") {
            setTimeLineViewController(mode: .federation)
        } else if title == I18n.get("ACTION_NOTIFICATIONS") {
            //
        } else if title == I18n.get("ACTION_MENTIONS") {
            //
        } else if title == I18n.get("ACTION_DM") {
            let vc = TimeLineViewController(hostName: hostName, accessToken: accessToken, type: .direct)
            setTimeLineViewController(vc: vc)
        } else if title == I18n.get("ACTION_FAVORITES") {
            let vc = TimeLineViewController(hostName: hostName, accessToken: accessToken, type: .favorites)
            setTimeLineViewController(vc: vc)
        } else if title == I18n.get("ACTION_SEARCH") {
            //
        } else if title == I18n.get("ACTION_USERS") {
            //
        }
    }
    
    override func viewDidLayout() {
        popUp.frame = NSRect(x: 0,
                             y: self.view.frame.height - 32,
                             width: min(150, self.view.frame.width),
                             height: 32)
        
        scrollView.frame = NSRect(x: 0,
                                  y: 0,
                                  width: self.view.frame.width,
                                  height: self.view.frame.height - 32)
    }
}
