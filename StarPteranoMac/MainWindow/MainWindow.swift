//
//  MainWindow.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class MainWindow: NSWindow {
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
                                    defer: true)
        window.styleMask.insert(NSWindow.StyleMask.titled)
        window.styleMask.insert(NSWindow.StyleMask.miniaturizable)
        window.styleMask.insert(NSWindow.StyleMask.resizable)
        
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
                message += "\n\n一番上が入力エリアです。command + returnキーで投稿できます。"
                Dialog.show(message: message)
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
        self.orderOut(self)
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
