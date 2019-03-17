//
//  AppDelegate.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/22.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

    //@IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 通知対応
        NSUserNotificationCenter.default.delegate = self
        
        // iTunesを監視
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(trackChanged(_:)), name: Notification.Name("com.apple.iTunes.playerInfo"), object: nil)
        
        // メニューを作成する
        Menu.makeMainMenus()
        
        showWindow()
    }
    
    @objc func trackChanged(_ notification: Notification) {
        iTunesInfo.set(notification: notification)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        showWindow()
        
        TimeLineViewCell.appActiveDate = Date()
    }
    
    private func showWindow() {
        if SettingsData.accountList.count == 0 {
            // アカウント登録がなければ設定ウィンドウのアカウントViewControllerを開く
            SettingsWindow.show()
        } else {
            // アカウント登録があればMainViewControllerを開く
            MainWindow.show()
        }
    }
    
    // 通知
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        //let info = notification.userInfo
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
}
