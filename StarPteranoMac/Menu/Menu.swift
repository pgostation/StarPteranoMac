//
//  Menu.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/23.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class Menu: NSObject, NSMenuDelegate {
    private static var menuTarget = Menu()
    
    private override init() {
        super.init()
    }
    
    static func makeMainMenus() {
        // Application Menu
        let appMenuItem = NSMenuItem(title: "App", action: nil, keyEquivalent: "")
        appMenuItem.target = menuTarget
        do {
            let appMenu = NSMenu(title: "App")
            
            do {
                let menuItem = NSMenuItem(title: I18n.get("About StarPterano"), action: #selector(doAppMenu(_:)), keyEquivalent: "")
                menuItem.target = menuTarget
                appMenu.addItem(menuItem)
            }
            appMenu.addItem(NSMenuItem.separator())
            do {
                let menuItem = NSMenuItem(title: I18n.get("Preferences…"), action: #selector(doAppMenu(_:)), keyEquivalent: ",")
                menuItem.target = menuTarget
                appMenu.addItem(menuItem)
            }
            appMenu.addItem(NSMenuItem.separator())
            do {
                let menuItem1 = NSMenuItem(title: I18n.get("Hide StarPterano"), action: #selector(doAppMenu(_:)), keyEquivalent: "h")
                menuItem1.target = menuTarget
                appMenu.addItem(menuItem1)
                
                let menuItem2 = NSMenuItem(title: I18n.get("Hide Others"), action: #selector(doAppMenu(_:)), keyEquivalent: "h")
                menuItem2.keyEquivalentModifierMask = NSEvent.ModifierFlags.command.union(NSEvent.ModifierFlags.control)
                menuItem2.target = menuTarget
                appMenu.addItem(menuItem2)
                
                let menuItem3 = NSMenuItem(title: I18n.get("Show All"), action: #selector(doAppMenu(_:)), keyEquivalent: "")
                menuItem3.target = menuTarget
                appMenu.addItem(menuItem3)
            }
            appMenu.addItem(NSMenuItem.separator())
            do {
                let menuItem = NSMenuItem(title: I18n.get("Quit StarPterano"), action: #selector(doAppMenu(_:)), keyEquivalent: "q")
                menuItem.target = menuTarget
                appMenu.addItem(menuItem)
            }
            
            appMenuItem.submenu = appMenu
        }
        
        // File Menu
        let fileMenuItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        fileMenuItem.target = menuTarget
        do {
            let fileMenu = NSMenu(title: I18n.get("File"))
            
            do {
                let menuItem = NSMenuItem(title: I18n.get("New window"), action: #selector(doAppMenu(_:)), keyEquivalent: "N")
                menuItem.target = menuTarget
                fileMenu.addItem(menuItem)
            }
            
            do {
                let menuItem = NSMenuItem(title: I18n.get("Close"), action: #selector(doAppMenu(_:)), keyEquivalent: "w")
                menuItem.target = menuTarget
                fileMenu.addItem(menuItem)
            }
            
            fileMenuItem.submenu = fileMenu
        }
        
        // Edit Menu
        let editMenuItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        editMenuItem.target = menuTarget
        do {
            let editMenu = NSMenu(title: I18n.get("Edit"))
            
            do {
                let menuItem1 = NSMenuItem(title: I18n.get("Undo"), action: #selector(doEditMenu(_:)), keyEquivalent: "z")
                menuItem1.target = menuTarget
                editMenu.addItem(menuItem1)
                
                let menuItem2 = NSMenuItem(title: I18n.get("Redo"), action: #selector(doEditMenu(_:)), keyEquivalent: "Z")
                menuItem2.target = menuTarget
                editMenu.addItem(menuItem2)
            }
            editMenu.addItem(NSMenuItem.separator())
            do {
                let menuItem1 = NSMenuItem(title: I18n.get("Cut"), action: #selector(doEditMenu(_:)), keyEquivalent: "x")
                menuItem1.target = menuTarget
                editMenu.addItem(menuItem1)
                
                let menuItem2 = NSMenuItem(title: I18n.get("Copy"), action: #selector(doEditMenu(_:)), keyEquivalent: "c")
                menuItem2.target = menuTarget
                editMenu.addItem(menuItem2)
                
                let menuItem3 = NSMenuItem(title: I18n.get("Paste"), action: #selector(doEditMenu(_:)), keyEquivalent: "v")
                menuItem3.target = menuTarget
                editMenu.addItem(menuItem3)
                
                let menuItem4 = NSMenuItem(title: I18n.get("Select All"), action: #selector(doEditMenu(_:)), keyEquivalent: "a")
                menuItem4.target = menuTarget
                editMenu.addItem(menuItem4)
            }
            
            editMenuItem.submenu = editMenu
        }
        
        // View Menu
        let viewMenuItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        viewMenuItem.target = menuTarget
        do {
            let viewMenu = NSMenu(title: I18n.get("View"))
            
            do {
                let menuItem1 = NSMenuItem(title: I18n.get("Mini View"), action: #selector(doViewMenu(_:)), keyEquivalent: "m")
                menuItem1.keyEquivalentModifierMask =  NSEvent.ModifierFlags.command.union(NSEvent.ModifierFlags.control)
                menuItem1.target = menuTarget
                viewMenu.addItem(menuItem1)
                
                let menuItem2 = NSMenuItem(title: I18n.get("Compact View"), action: #selector(doViewMenu(_:)), keyEquivalent: "c")
                menuItem2.keyEquivalentModifierMask =  NSEvent.ModifierFlags.command.union(NSEvent.ModifierFlags.control)
                menuItem2.target = menuTarget
                viewMenu.addItem(menuItem2)
                
                let menuItem3 = NSMenuItem(title: I18n.get("Standard View"), action: #selector(doViewMenu(_:)), keyEquivalent: "s")
                menuItem3.keyEquivalentModifierMask =  NSEvent.ModifierFlags.command.union(NSEvent.ModifierFlags.control)
                menuItem3.target = menuTarget
                viewMenu.addItem(menuItem3)
                
                /*let menuItem4 = NSMenuItem(title: I18n.get("Full View"), action: #selector(doViewMenu(_:)), keyEquivalent: "f")
                menuItem4.keyEquivalentModifierMask =  NSEvent.ModifierFlags.command.union(NSEvent.ModifierFlags.control)
                menuItem4.target = menuTarget
                viewMenu.addItem(menuItem4)*/
            }
            viewMenu.addItem(NSMenuItem.separator())
            do {
                let menuItem1 = NSMenuItem(title: I18n.get("Show user…"), action: #selector(doViewMenu(_:)), keyEquivalent: "u")
                menuItem1.target = menuTarget
                viewMenu.addItem(menuItem1)
            }
            viewMenu.addItem(NSMenuItem.separator())
            do {
                let menuItem1 = NSMenuItem(title: I18n.get("Larger"), action: #selector(doViewMenu(_:)), keyEquivalent: "+")
                menuItem1.target = menuTarget
                viewMenu.addItem(menuItem1)
                
                let menuItem2 = NSMenuItem(title: I18n.get("Smaller"), action: #selector(doViewMenu(_:)), keyEquivalent: "-")
                menuItem2.target = menuTarget
                viewMenu.addItem(menuItem2)
            }
            viewMenu.addItem(NSMenuItem.separator())
            
            viewMenuItem.submenu = viewMenu
        }
        
        // Toot Menu
        let tootMenuItem = NSMenuItem(title: "Toot", action: nil, keyEquivalent: "")
        tootMenuItem.target = menuTarget
        do {
            let tootMenu = NSMenu(title: I18n.get("Toot"))
            
            do {
                let menuItem1 = NSMenuItem(title: I18n.get("New Toot"), action: #selector(doTootMenu(_:)), keyEquivalent: "n")
                menuItem1.target = menuTarget
                tootMenu.addItem(menuItem1)
                
                let menuItem2 = NSMenuItem(title: I18n.get("Toot"), action: #selector(doTootMenu(_:)), keyEquivalent: "\n")
                menuItem2.target = menuTarget
                tootMenu.addItem(menuItem2)
            }
            
            tootMenu.addItem(NSMenuItem.separator())
            do {
                /*let menuItem1 = NSMenuItem(title: I18n.get("Now Playing"), action: #selector(doTootMenu(_:)), keyEquivalent: "i")
                menuItem1.keyEquivalentModifierMask =  NSEvent.ModifierFlags.command.union(NSEvent.ModifierFlags.option)
                menuItem1.target = menuTarget
                tootMenu.addItem(menuItem1)
                
                let menuItem2 = NSMenuItem(title: I18n.get("Now Browsing"), action: #selector(doTootMenu(_:)), keyEquivalent: "s")
                menuItem2.keyEquivalentModifierMask =  NSEvent.ModifierFlags.command.union(NSEvent.ModifierFlags.option)
                menuItem2.target = menuTarget
                tootMenu.addItem(menuItem2)
                
                let menuItem3 = NSMenuItem(title: I18n.get("Add Image…"), action: #selector(doTootMenu(_:)), keyEquivalent: "i")
                menuItem3.target = menuTarget
                tootMenu.addItem(menuItem3)
                
                let menuItem4 = NSMenuItem(title: I18n.get("Scheduled Toot…"), action: #selector(doTootMenu(_:)), keyEquivalent: "")
                menuItem4.target = menuTarget
                tootMenu.addItem(menuItem4)*/
            }
            
            tootMenuItem.submenu = tootMenu
        }
        
        // Tool Menu
        /*let toolMenuItem = NSMenuItem(title: "Tool", action: nil, keyEquivalent: "")
        toolMenuItem.target = menuTarget
        do {
            let toolMenu = NSMenu(title: I18n.get("Tool"))
            
            do {
                let menuItem1 = NSMenuItem(title: I18n.get("Edit Profile…"), action: #selector(doToolMenu(_:)), keyEquivalent: "p")
                menuItem1.keyEquivalentModifierMask =  NSEvent.ModifierFlags.command.union(NSEvent.ModifierFlags.option)
                menuItem1.target = menuTarget
                toolMenu.addItem(menuItem1)
            }
            toolMenu.addItem(NSMenuItem.separator())
            
            toolMenuItem.submenu = toolMenu
        }*/
        
        // Set Menus to App
        let mainMenu = NSMenu(title: "Main")
        mainMenu.addItem(appMenuItem)
        mainMenu.addItem(fileMenuItem)
        mainMenu.addItem(editMenuItem)
        mainMenu.addItem(viewMenuItem)
        mainMenu.addItem(tootMenuItem)
        //mainMenu.addItem(toolMenuItem)
        NSApplication.shared.mainMenu = mainMenu
    }
    
    @objc func doAppMenu(_ item: NSMenuItem) {
        if item.title == I18n.get("Quit StarPterano") {
            NSApplication.shared.terminate(nil)
        }
        else if item.title == I18n.get("Preferences…") {
            SettingsWindow.show()
        }
        else if item.title == I18n.get("Show All") {
            NSApplication.shared.unhideAllApplications(nil)
        }
        else if item.title == I18n.get("Hide StarPterano") {
            NSApplication.shared.hide(nil)
        }
        else if item.title == I18n.get("Hide Others") {
            NSApplication.shared.hideOtherApplications(nil)
        }
        else if item.title == I18n.get("About StarPterano") {
            NSApplication.shared.orderFrontStandardAboutPanel(nil)
        }
        else if item.title == I18n.get("New window") {
            MainWindow.show()
        }
        else if item.title == I18n.get("Close") {
            NSApplication.shared.keyWindow?.close()
        }
    }
    
    @objc func doEditMenu(_ item: NSMenuItem) {
        guard let activeField = NSApplication.shared.keyWindow?.firstResponder as? NSTextView else { return }
        
        if item.title == I18n.get("Undo") {
            activeField.undoManager?.undo()
        }
        else if item.title == I18n.get("Redo") {
            activeField.undoManager?.redo()
        }
        else if item.title == I18n.get("Cut") {
            activeField.cut(nil)
        }
        else if item.title == I18n.get("Copy") {
            activeField.copy(nil)
        }
        else if item.title == I18n.get("Paste") {
            activeField.pasteAsPlainText(nil)
        }
        else if item.title == I18n.get("Select All") {
            activeField.selectAll(nil)
        }
    }
    
    @objc func doViewMenu(_ item: NSMenuItem) {
        if item.title == I18n.get("Mini View") {
            if SettingsData.isMiniView == .superMini {
                SettingsData.isMiniView = .normal
            } else {
                SettingsData.isMiniView = .superMini
            }
            MainViewController.refreshAllTimeLineViews()
        }
        else if item.title == I18n.get("Compact View") {
            if SettingsData.isMiniView == .miniView {
                SettingsData.isMiniView = .normal
            } else {
                SettingsData.isMiniView = .miniView
            }
            MainViewController.refreshAllTimeLineViews()
        }
        else if item.title == I18n.get("Standard View") {
            SettingsData.isMiniView = .normal
            MainViewController.refreshAllTimeLineViews()
        }
        else if item.title == I18n.get("Full View") {
            SettingsData.isMiniView = .full
            MainViewController.refreshAllTimeLineViews()
        }
        else if item.title == I18n.get("Larger") {
            SettingsData.fontSize += 1
            MainViewController.refreshAllTimeLineViews()
        }
        else if item.title == I18n.get("Smaller") {
            SettingsData.fontSize -= 1
            MainViewController.refreshAllTimeLineViews()
        }
        else if item.title == I18n.get("Show user…") {
            let vc = TimeLineViewManager.getLastSelectedTLView()
            let hostName = (vc as? TimeLineViewController)?.hostName ?? (vc as? NotificationViewController)?.hostName
            let accessToken = (vc as? TimeLineViewController)?.accessToken ?? (vc as? NotificationViewController)?.accessToken
            let accountList = (vc?.view as? TimeLineView)?.accountList ?? (vc?.view as? NotificationTableView)?.accountList
            let subAccountList = SettingsData.recentMentionList(accessToken: accessToken ?? "") + SettingsData.followingList(accessToken: accessToken ?? "")
            
            AccountDialog.showWithTextInput(
                message: I18n.get("Show user…"),
                okName: "OK",
                cancelName: "Cancel",
                defaultText: nil,
                accountList: accountList,
                subAccountList: subAccountList) { (textField, result) in
                    if !result { return }
                    
                    let account = textField.stringValue
                    
                    if account == "" { return }
                    
                    var accountId: String? = nil
                    
                    for tmpAccount in accountList ?? [:] {
                        if account == tmpAccount.value.acct {
                            accountId = tmpAccount.value.id
                            break
                        }
                    }
                    
                    func show(accountData: AnalyzeJson.AccountData) {
                        let accountTimeLineViewController = TimeLineViewController(hostName: hostName ?? "", accessToken: accessToken ?? "", type: TimeLineViewController.TimeLineType.user, option: accountId)
                        if let timelineView = accountTimeLineViewController.view as? TimeLineView {
                            timelineView.accountList.updateValue(accountData, forKey: accountId ?? "")
                        }
                        
                        let subTimeLineViewController = SubTimeLineViewController(name: NSAttributedString(string: account), icon: nil, timelineVC: accountTimeLineViewController)
                        
                        var targetSubVC: SubViewController? = nil
                        for subVC in MainViewController.instance?.subVCList ?? [] {
                            if hostName == subVC.tootVC.hostName && accessToken == subVC.tootVC.accessToken {
                                targetSubVC = subVC
                                break
                            }
                        }
                        
                        // 複数のサブTLを開かないようにする
                        for subVC in targetSubVC?.children ?? [] {
                            if subVC is SubTimeLineViewController || subVC is FollowingViewController {
                                subVC.removeFromParent()
                                subVC.view.removeFromSuperview()
                            }
                        }
                        
                        targetSubVC?.addChild(subTimeLineViewController)
                        targetSubVC?.view.addSubview(subTimeLineViewController.view)
                        
                        subTimeLineViewController.view.frame = CGRect(x: (targetSubVC?.view.frame.width ?? 100),
                                                                      y: 0,
                                                                      width: (targetSubVC?.view.frame.width ?? 100),
                                                                      height: (targetSubVC?.view.frame.height ?? 100) - 22)
                        
                        
                        subTimeLineViewController.showAnimation(parentVC: targetSubVC)
                    }
                    
                    if let accountData = accountList?[account] {
                        // アカウントデータがあればすぐ表示
                        show(accountData: accountData)
                    } else {
                        // 情報を取得してから表示
                        guard let url = URL(string: "https://\(hostName ?? "")/api/v1/accounts/search?q=\(account)") else { return }
                        try? MastodonRequest.get(url: url, accessToken: accessToken ?? "") { (data, response, error) in
                            if let data = data {
                                do {
                                    if let responseJsonList = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]] {
                                        var accountData: AnalyzeJson.AccountData? = nil
                                        for responseJson in responseJsonList {
                                            let tmpData = AnalyzeJson.analyzeAccountJson(account: responseJson)
                                            if tmpData.acct == account {
                                                accountData = tmpData
                                                break
                                            }
                                        }
                                        if let accountData = accountData {
                                            DispatchQueue.main.async {
                                                if accountData.id != nil {
                                                    accountId = accountData.id
                                                }
                                                show(accountData: accountData)
                                            }
                                        }
                                    }
                                } catch { }
                            }
                        }
                    }
            }
        }
    }
    
    @objc func doTootMenu(_ item: NSMenuItem) {
        if item.title == I18n.get("New Toot") {
            if let tlVC = TimeLineViewManager.getLastSelectedTLView() {
                let textField = ((tlVC.parent as? SubViewController)?.tootVC.view as? TootView)?.textField
                MainWindow.window?.makeFirstResponder(textField)
            }
        }
        if item.title == I18n.get("Toot") {
            guard let activeField = NSApplication.shared.keyWindow?.firstResponder as? NSTextView else { return }
            if let tootView = activeField.superview as? TootView {
                for subVC in MainViewController.instance?.subVCList ?? [] {
                    if tootView.superview == subVC.view {
                        subVC.tootVC.tootAction()
                        break
                    }
                }
            }
        }
    }
    
    @objc func doToolMenu(_ item: NSMenuItem) {
        if item.title == I18n.get("Edit Profile") {
        }
    }
    
    @objc func validateMenuItem(_ item: NSMenuItem) -> Bool {
        if item.title == I18n.get("Show All") {
            return true
        }
        else if item.title == I18n.get("Hide StarPterano") {
            return true
        }
        else if item.title == I18n.get("Hide Others") {
            return true
        }
        else if item.title == I18n.get("Undo") {
            guard let activeField = NSApplication.shared.keyWindow?.firstResponder as? NSTextView else { return false }
            return activeField.undoManager?.canUndo ?? false
        }
        else if item.title == I18n.get("Redo") {
            guard let activeField = NSApplication.shared.keyWindow?.firstResponder as? NSTextView else { return false }
            return activeField.undoManager?.canRedo ?? false
        }
        else if item.title == I18n.get("Cut") {
            guard let activeField = NSApplication.shared.keyWindow?.firstResponder as? NSTextView else { return false }
            return activeField.selectedRange().length > 0
        }
        else if item.title == I18n.get("Copy") {
            guard let activeField = NSApplication.shared.keyWindow?.firstResponder as? NSTextView else { return false }
            return activeField.selectedRange().length > 0
        }
        else if item.title == I18n.get("Paste") {
            return NSPasteboard.general.string(forType: NSPasteboard.PasteboardType.string) != nil
        }
        else if item.title == I18n.get("Select All") {
            return true
        }
        
        return true
    }
}
