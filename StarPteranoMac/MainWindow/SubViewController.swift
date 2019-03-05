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
        for mode in tlModes {
            addTab(mode: mode)
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
            type = .search
        }
        
        let vc: NSViewController
        if type == .notifications || type == .notificationMentions {
            vc = TimeLineViewManager.get(key: key) ?? NotificationViewController(hostName: hostName, accessToken: accessToken, type: type)
        } else if type == .search {
            vc = TimeLineViewManager.get(key: key) ?? SearchViewController(hostName: hostName, accessToken: accessToken, type: TimeLineViewController.TimeLineType.search, option: nil)
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
        
        let existMenus = SettingsData.tlMode(key: hostName + "," + accessToken)
        
        selectedItem = nil
        
        do {
            let menuItems = ["ACTION_HOME", "ACTION_LOCAL", "ACTION_HOMELOCAL", "ACTION_FEDERATION", "ACTION_LIST", "ACTION_NOTIFICATIONS", "ACTION_MENTIONS", "ACTION_DM", "ACTION_FAVORITES", "ACTION_SEARCH"]
            for str in menuItems {
                // すでにタブがあるなら飛ばす
                let mode = convert(title: I18n.get(str))
                if existMenus.contains(mode) {
                    continue
                }
                
                // メニューアイテム追加
                let menuItem = NSMenuItem(title: I18n.get(str),
                                          action: #selector(menuAction(_:)),
                                          keyEquivalent: "")
                menuItem.target = self
                menu.addItem(menuItem)
                
                // デフォルトでは最初のアイテムを選択したことにする
                if selectedItem == nil {
                    selectedItem = mode
                }
            }
        }
        
        return popUp
    }
    
    @objc func menuAction(_ menuItem: NSMenuItem) {
        doMenu(title: menuItem.title)
    }
    
    private var selectedItem: SettingsData.TLMode?
    private func doMenu(title: String) {
        selectedItem = convert(title: title)
    }
    
    // 文字列からTLModeに変換
    private func convert(title: String) -> SettingsData.TLMode {
        if title == I18n.get("ACTION_HOME") {
            return .home
        } else if title == I18n.get("ACTION_LOCAL") {
            return .local
        } else if title == I18n.get("ACTION_HOMELOCAL") {
            return .homeLocal
        } else if title == I18n.get("ACTION_FEDERATION") {
            return .federation
        } else if title == I18n.get("ACTION_MENTIONS") {
            return .mentions
        } else if title == I18n.get("ACTION_NOTIFICATIONS") {
            return .notifications
        } else if title == I18n.get("ACTION_DM") {
            return .dm
        } else if title == I18n.get("ACTION_FAVORITES") {
            return .favorites
        } else if title == I18n.get("ACTION_LIST") {
            return .list
        } else if title == I18n.get("ACTION_SEARCH") {
            return .search
        }
        return .home
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
        
        var headHeight: CGFloat = 0
        for childVc in self.children {
            if let tlVc = childVc as? TimeLineViewController {
                if let headerView = tlVc.headerView {
                    headerView.frame = NSRect(x: 0,
                                              y: self.view.frame.height - 20 - tootVC.view.frame.height - 22 - 30,
                                              width: self.view.frame.width,
                                              height: 30)
                    headHeight = 30
                }
            }
        }
        
        scrollView.frame = NSRect(x: 0,
                                  y: 0,
                                  width: self.view.frame.width,
                                  height: self.view.frame.height - 20 - tootVC.view.frame.height - 22 - headHeight)
        
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
