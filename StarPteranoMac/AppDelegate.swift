//
//  AppDelegate.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/22.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        Menu.makeMainMenus()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

// メニューを作成する
// アカウント登録がなければ設定ウィンドウのアカウントViewControllerを開く
// アカウント登録があればMainViewControllerを開く
//   MainViewControllerはタブ的だが、複数のViewControllerを同時に表示するだけ

// TwUIあたりを使うか、CALayer中心にビューを構築するのが良さそう

// キーボードショートカット


