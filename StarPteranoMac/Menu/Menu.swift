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
        
        // File Menu
        let fileMenuItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        fileMenuItem.target = menuTarget
        do {
            let fileMenu = NSMenu(title: I18n.get("File"))
            
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
        
        // Set Menus to App
        let mainMenu = NSMenu(title: "Main")
        mainMenu.addItem(appMenuItem)
        mainMenu.addItem(fileMenuItem)
        mainMenu.addItem(editMenuItem)
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
