//
//  MainWindow.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class MainWindow: NSWindow {
    static var windowController = NSWindowController()
    static weak var window: MainWindow?
    
    private override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        if SettingsData.isTransparentWindow {
            self.backgroundColor = ThemeColor.viewBgColor.withAlphaComponent(0.5)
            self.titlebarAppearsTransparent = true
            self.isOpaque = false
        }
        
        AccountSettingsViewController.getAccountData(view: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.moved),
                                               name: NSWindow.didMoveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.moved),
                                               name: NSWindow.didResizeNotification, object: nil)
    }
    
    static func show() {
        if self.window != nil {
            self.window?.setIsVisible(true)
            setFrame()
            return
        }
        
        ThemeColor.change()
        
        let window = MainWindow(contentRect: NSRect(x: 0, y: 0, width: 0, height: 0),
                                    styleMask: NSWindow.StyleMask.closable,
                                    backing: NSWindow.BackingStoreType.buffered,
                                    defer: false)
        window.styleMask.insert(NSWindow.StyleMask.titled)
        window.styleMask.insert(NSWindow.StyleMask.miniaturizable)
        window.styleMask.insert(NSWindow.StyleMask.resizable)
        
        MainWindow.windowController.window = window
        
        if #available(OSX 10.12, *) {
            window.tabbingMode = .disallowed
        }
        window.title = I18n.get("APPLICATION_NAME")
        
        self.window = window
        setFrame()
        window.makeKeyAndOrderFront(window)
        
        DispatchQueue.main.async {
            let vc = MainViewController()
            window.contentViewController = vc
            window.contentView = vc.view
        }
        
        // 初回起動時は説明を表示
        if SettingsData.firstExec {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                var message = ""
                message += "星プテラノを起動していただきありがとうございます。"
                message += "\n\n一番上の部分が入力エリアです。command + returnキーで投稿できます。"
                Dialog.show(message: message)
            }
        }
        
        // 自動更新タイマーを設定
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            timerAction()
            setTimer()
        }
    }
    
    // 自動更新タイマーを設定
    private static var refreshTimer: Timer?
    private static func setTimer() {
        refreshTimer = Timer.scheduledTimer(timeInterval: 5 * 60, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
    }
    
    // 自動更新を実施
    @objc static func timerAction() {
        if window?.isVisible != true { return }
        
        var delay: Double = 0
        
        // 全てのカラムを更新する
        for subVC in MainViewController.instance?.subVCList ?? [] {
            // 全てのタブを更新する
            for tabItem in subVC.tabView.items {
                let identifier = (tabItem.identifier as? String) ?? ""
                guard let mode = SettingsData.TLMode(rawValue: identifier) else { continue }
                
                // ViewControllerが無ければ作る
                let vc = SubViewController.getViewController(hostName: subVC.hostName, accessToken: subVC.accessToken, mode: mode)
                
                // 更新処理
                if let vc = vc as? NotificationViewController {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        vc.add(isRefresh: true)
                    }
                } else if let view = vc.view as? TimeLineView {
                    if view.streamingObject?.isConnected == true { continue } // ストリーミング中は無視
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        view.refresh()
                    }
                }
                
                delay += 2 // 一気に更新すると重くなるので、2秒の間隔を空けて更新
            }
        }
    }
    
    private static func setFrame() {
        if let frame = SettingsData.mainWindowFrame {
            self.window?.setFrame(frame, display: true)
        } else {
            let frame = NSRect(x: 0, y: 0, width: min(800, (NSScreen.main?.visibleFrame.width ?? 1600) / 2), height: (NSScreen.main?.visibleFrame.height ?? 400))
            self.window?.setFrame(frame, display: true)
        }
    }
    
    override func close() {
        if MainWindow.windowController.window != nil {
            MainWindow.windowController.window = nil
            MainWindow.windowController.close()
            super.close()
        }
        MainWindow.windowController = NSWindowController()
    }
    
    @objc func moved() {
        if self.frame.width > 0 {
            SettingsData.mainWindowFrame = self.frame
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if let tlVC = TimeLineViewManager.getLastSelectedTLView() {
            switch event.keyCode {
            case 123: // left arrow
                if event.modifierFlags.contains(.command) {
                    // 左タブに移動
                    for subVC in MainViewController.instance?.subVCList ?? [] {
                        if subVC.tabView.bold {
                            subVC.tabView.selectLeft()
                            return
                        }
                    }
                }
                else if event.modifierFlags.contains(.shift) {
                    // 左カラムに移動
                    let subVCList = MainViewController.instance?.subVCList ?? []
                    for (index, subVC) in subVCList.enumerated() {
                        if subVC.tabView.bold {
                            if index > 0 {
                                subVCList[index - 1].tabCoverView.mouseDown(with: NSEvent())
                            } else {
                                subVCList[subVCList.count - 1].tabCoverView.mouseDown(with: NSEvent())
                            }
                            break
                        }
                    }
                }
            case 124: // right arrow
                if event.modifierFlags.contains(.command) {
                    // 右タブに移動
                    for subVC in MainViewController.instance?.subVCList ?? [] {
                        if subVC.tabView.bold {
                            subVC.tabView.selectRight()
                            return
                        }
                    }
                }
                else if event.modifierFlags.contains(.shift) {
                    // 右カラムに移動
                    let subVCList = MainViewController.instance?.subVCList ?? []
                    for (index, subVC) in subVCList.enumerated() {
                        if subVC.tabView.bold {
                            if index < subVCList.count - 1 {
                                subVCList[index + 1].tabCoverView.mouseDown(with: NSEvent())
                            } else {
                                subVCList[0].tabCoverView.mouseDown(with: NSEvent())
                            }
                            break
                        }
                    }
                }
            case 13: // w
                // サブビューを閉じる
                if let lastVC = tlVC.parent?.children.last as? SubTimeLineViewController {
                    lastVC.closeAction()
                }
            default:
                break
            }
            
            if let lastVC = tlVC.parent?.children.last as? SubTimeLineViewController {
                // 会話ビューなどを開いている場合
                if let tlVC = lastVC.children.first as? TimeLineViewController {
                    if let tlView = tlVC.view as? TimeLineView {
                        tlView.myKeyDown(keyCode: event.keyCode, modifierFlags: event.modifierFlags)
                    }
                }
            } else if let tlView = tlVC.view as? TimeLineView {
                // タイムライン
                tlView.myKeyDown(keyCode: event.keyCode, modifierFlags: event.modifierFlags)
            }
        }
    }
}
