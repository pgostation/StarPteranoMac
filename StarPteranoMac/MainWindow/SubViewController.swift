//
//  SubViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class SubViewController: NSViewController, NSTabViewDelegate {
    private let hostName: String
    private let accessToken: String
    let tootVC: TootViewController
    private let tabView = PgoTabView(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
    private let tabCoverView = CoverView(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
    let scrollView = NSScrollView()
    
    init(hostName: String, accessToken: String) {
        self.hostName = hostName
        self.accessToken = accessToken
        self.tootVC = TootViewController(hostName: hostName, accessToken: accessToken)
        
        super.init(nibName: nil, bundle: nil)
        
        self.view = NSView()
        
        self.view.addSubview(tootVC.view)
        self.view.addSubview(tabView)
        DispatchQueue.main.async {
            DispatchQueue.main.async {
                self.view.addSubview(self.tabCoverView)
            }
        }
        self.view.addSubview(scrollView)
        
        setProperties()
        
        let tlModes = SettingsData.tlMode(key: hostName + "," + accessToken)
        for (index, mode) in tlModes.enumerated() {
            switch mode {
            case .list:
                let listOption = SettingsData.selectedListId(accessToken: accessToken, index: index)
                let key = TimeLineViewManager.makeKey(hostName: hostName, accessToken: accessToken, type: .list, option: listOption)
                let vc = TimeLineViewManager.get(key: key) ?? TimeLineViewController(hostName: hostName, accessToken: accessToken, type: .list, option: listOption)
                TimeLineViewManager.set(key: key, vc: vc)
            default:
                addTab(mode: mode)
            }
        }
        
        if tlModes.count == 0 {
            addTab(mode: .home)
        }
        
        self.view.needsLayout = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        tabView.autoresizesSubviews = true
        tabView.delegate = self
        
        tabView.addNewTabButtonAction = #selector(newTabAction)
        tabView.addNewTabButtonTarget = self
        
        //scrollView.scrollerStyle = .legacy
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
    }
    
    private func addTab(mode: SettingsData.TLMode) {
        let item = PgoTabItem(identifier: mode.rawValue)
        item.label = I18n.get("ACTION_" + mode.rawValue.uppercased())
        item.identifier = mode.rawValue
        tabView.addTabViewItem(item)
    }
    
    @objc func newTabAction() {
        let popUp = getPopUp()
        
        popUp.frame = NSRect(x: 50, y: 50, width: 200, height: 30)
            
        Dialog.showWithView(message: I18n.get("ALERT_ADD_TAB"),
                            okName: I18n.get("BUTTON_ADD"),
                            view: popUp)
        
        if let item = self.selectedItem {
            addTab(mode: item)
        }
    }
    
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        guard let tabViewItem = tabViewItem else { return }
        
        guard let mode = SettingsData.TLMode(rawValue: tabViewItem.identifier as? String ?? "") else { return }
        
        let key = TimeLineViewManager.makeKey(hostName: hostName, accessToken: accessToken, type: mode)
        
        let type: TimeLineViewController.TimeLineType
        switch mode {
        case .home:
            type = .home
        case .local:
            type = .local
        case .homeLocal:
            type = .homeLocal
        case .federation:
            type = .federation
        case .list:
            type = .list
        case .favorites:
            type = .favorites
        case .dm:
            type = .direct
        case .mentions:
            type = .notificationMentions
        case .notifications:
            type = .notifications
        case .users:
            type = .home // これは使用しない
        case .search:
            type = .home // 検索ビューは未作成
        }
        
        let vc: NSViewController
        if type == .notifications || type == .notificationMentions {
            vc = TimeLineViewManager.get(key: key) ?? NotificationViewController(hostName: hostName, accessToken: accessToken, type: type)
        } else {
            vc = TimeLineViewManager.get(key: key) ?? TimeLineViewController(hostName: hostName, accessToken: accessToken, type: type)
        }
        scrollView.documentView = vc.view
        
        self.children.first?.removeFromParent()
        self.addChild(vc)
        
        TimeLineViewManager.set(key: key, vc: vc)
        
        var modes = SettingsData.tlMode(key: hostName + "," + accessToken)
        modes.append(mode)
    }
    
    func tabViewDidChangeNumberOfTabViewItems(_ tabView: NSTabView) {
        var modes: [SettingsData.TLMode] = []
        
        for item in (tabView as? PgoTabView)?.items ?? [] {
            guard let mode = SettingsData.TLMode(rawValue: item.identifier as! String) else { continue }
            modes.append(mode)
        }
        
        SettingsData.setTlMode(key: hostName + "," + accessToken, modes: modes)
    }
    
    private func getPopUp() -> NSPopUpButton {
        let popUp = NSPopUpButton()
        let menu = NSMenu()
        popUp.menu = menu
        
        // ホーム、ローカル、ローカル + ホーム、連合
        do {
            let menuItems = ["ACTION_HOME", "ACTION_LOCAL", "ACTION_HOMELOCAL", "ACTION_FEDERATION"]
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
            let menuItems = ["ACTION_NOTIFICATIONS", "ACTION_MENTIONS", "ACTION_DM", "ACTION_FAVORITES"]
            for str in menuItems {
                let menuItem = NSMenuItem(title: I18n.get(str),
                                          action: #selector(menuAction(_:)),
                                          keyEquivalent: "")
                menuItem.target = self
                menu.addItem(menuItem)
            }
        }
        
        selectedItem = .home
        
        return popUp
    }
    
    @objc func menuAction(_ menuItem: NSMenuItem) {
        doMenu(title: menuItem.title)
    }
    
    private var selectedItem: SettingsData.TLMode?
    private func doMenu(title: String) {
        if title == I18n.get("ACTION_HOME") {
            selectedItem = .home
        } else if title == I18n.get("ACTION_LOCAL") {
            selectedItem = .local
        } else if title == I18n.get("ACTION_HOMELOCAL") {
            selectedItem = .homeLocal
        } else if title == I18n.get("ACTION_FEDERATION") {
            selectedItem = .federation
        } else if title == I18n.get("ACTION_MENTIONS") {
            selectedItem = .mentions
        } else if title == I18n.get("ACTION_NOTIFICATIONS") {
            selectedItem = .notifications
        } else if title == I18n.get("ACTION_DM") {
            selectedItem = .dm
        } else if title == I18n.get("ACTION_FAVORITES") {
            selectedItem = .favorites
        } else if title == I18n.get("ACTION_LIST") {
            selectedItem = .list
        }
    }
    
    override func viewDidLayout() {
        tootVC.view.frame = NSRect(x: 0,
                                   y: self.view.frame.height - tootVC.view.frame.height - 22,
                                   width: self.view.frame.width,
                                   height: tootVC.view.frame.height)
        
        tabView.frame = NSRect(x: 0,
                               y: self.view.frame.height - 20 - tootVC.view.frame.height - 22,
                               width: self.view.frame.width,
                               height: 20)
        tabView.needsLayout = true
        
        tabCoverView.frame = tabView.frame
        
        scrollView.frame = NSRect(x: 0,
                                  y: 0,
                                  width: self.view.frame.width,
                                  height: self.view.frame.height - 20 - tootVC.view.frame.height - 22)
        
        for subview in self.view.subviews {
            if subview is SubTimeLineView {
                subview.needsLayout = true
            }
        }
        
        // 絵文字キーボード
        if let emojiView = self.view.viewWithTag(3948) {
            let height = min(500, scrollView.frame.height)
            emojiView.frame = NSRect(x: 0,
                                     y: scrollView.frame.height - height,
                                     width: min(320, self.view.frame.width),
                                     height: height)
            
            emojiView.needsLayout = true
        }
        
        // 画像確認画面
        if let imageCheckView = self.view.viewWithTag(7624) {
            let height = imageCheckView.frame.height
            imageCheckView.frame = NSRect(x: 0,
                                          y: scrollView.frame.height - height,
                                          width: imageCheckView.frame.width,
                                          height: height)
        }
    }
    
    final class CoverView: NSView {
        override func mouseDown(with event: NSEvent) {
            super.mouseDown(with: event)
            
            for subview in self.superview?.subviews ?? [] {
                if let scrollview = subview as? NSScrollView {
                    if let tlView = scrollview.documentView as? TimeLineView {
                        tlView.selectedDate = Date()
                        MainViewController.instance?.unboldAll()
                        (self.superview?.viewWithTag(5823) as? PgoTabView)?.bold = true
                        break
                    }
                }
            }
        }
    }
}
