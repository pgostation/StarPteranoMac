//
//  Menu.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/23.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

class Menu: NSObject, NSMenuDelegate {
    private static var menuTarget = Menu()
    
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
                let menuItem = NSMenuItem(title: I18n.get("Preferences…"), action: #selector(doAppMenu(_:)), keyEquivalent: "")
                menuItem.target = menuTarget
                appMenu.addItem(menuItem)
            }
            appMenu.addItem(NSMenuItem.separator())
            do {
                let menuItem1 = NSMenuItem(title: I18n.get("Hide StarPterano"), action: #selector(doAppMenu(_:)), keyEquivalent: "h")
                menuItem1.target = menuTarget
                appMenu.addItem(menuItem1)
                
                let menuItem2 = NSMenuItem(title: I18n.get("Hide Others"), action: #selector(doAppMenu(_:)), keyEquivalent: "^h")
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
        
        // Set Menus to App
        let mainMenu = NSMenu(title: "Main")
        mainMenu.addItem(appMenuItem)
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
    }
}
