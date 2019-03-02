//
//  MainViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class MainViewController: NSViewController {
    static weak var instance: MainViewController?
    var subVCList: [SubViewController] = []
    private var barList: [NSView] = []
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        MainViewController.instance = self
        
        self.view = MainView()
        self.view.needsLayout = true
        self.view.frame.size = MainWindow.window?.frame.size ?? NSSize(width: 0, height: 0)
        
        for account in SettingsData.accountList {
            let subVC = SubViewController(hostName: account.0, accessToken: account.1)
            self.subVCList.append(subVC)
            self.view.addSubview(subVC.view)
            self.addChild(subVC)
            
            subVC.view.needsLayout = true
            
            // 仕切り
            let bar = SlideBar()
            bar.accessToken = account.1
            bar.wantsLayer = true
            if SettingsData.isTransparentWindow {
                bar.layer?.backgroundColor = NSColor.gray.withAlphaComponent(0.4).cgColor
            } else {
                bar.layer?.backgroundColor = NSColor.gray.cgColor
            }
            barList.append(bar)
            self.view.addSubview(bar)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func refreshAllTimeLineViews() {
        for subVC in instance?.subVCList ?? [] {
            if let view = subVC.scrollView.documentView as? TimeLineView {
                view.reloadData()
            }
            if let tabView = subVC.view.viewWithTag(5823) as? PgoTabView {
                tabView.refresh()
            }
            if let tootView = subVC.tootVC.view as? TootView {
                tootView.refresh()
            }
        }
    }
    
    override func viewDidLayout() {
        guard let size = MainWindow.window?.frame.size else { return }
        
        var sum: CGFloat = 0
        var widthList: [CGFloat] = []
        var maxIndex = -1
        var maxWidth: CGFloat = -1
        for (index, account) in SettingsData.accountList.enumerated() {
            let width = max(48, CGFloat(SettingsData.viewWidth(accessToken: account.1) ?? 0))
            widthList.append(width)
            sum += width
            if width > maxWidth {
                maxWidth = width
                maxIndex = index
            }
        }
        
        do {
            // 選択中のカラムの幅を変化させる
            var selectedIndex = -1
            var lastDate = Date(timeIntervalSince1970: 0)
            for (index, subVC) in self.subVCList.enumerated() {
                if let timelineView = subVC.scrollView.documentView as? TimeLineView {
                    if timelineView.selectedDate > lastDate {
                        selectedIndex = index
                        lastDate = timelineView.selectedDate
                    }
                }
            }
            
            if selectedIndex != -1 {
                widthList[selectedIndex] = max(48, widthList[selectedIndex] + (size.width - sum))
            } else {
                // 最も大きい幅の項目の幅を変化させる
                if maxIndex != -1 {
                    widthList[maxIndex] = max(48, widthList[maxIndex] + (size.width - sum))
                }
            }
        }
        
        for (index, account) in SettingsData.accountList.enumerated() {
            SettingsData.setViewWidth(accessToken: account.1, width: Float(widthList[index]))
        }
        
        var right: CGFloat = 0
        for index in 0..<self.subVCList.count {
            if index >= widthList.count { continue }
            
            subVCList[index].view.frame = NSRect(x: right,
                                                 y: 0,
                                                 width: widthList[index] - ((index == self.subVCList.count - 1) ? 0 : 3),
                                                 height: size.height)
            
            barList[index].frame = NSRect(x: subVCList[index].view.frame.maxX,
                                          y: 0,
                                          width: 3,
                                          height: size.height)
            
            right = barList[index].frame.maxX
        }
    }
    
    // テキスト入力フィールドからフォーカスを外す
    func quickResignFirstResponder() {
        MainWindow.window?.makeFirstResponder(nil)
    }
    
    // タブバーの太字を全て解除
    func unboldAll() {
        for subVC in self.subVCList {
            (subVC.view.viewWithTag(5823) as? PgoTabView)?.bold = false
        }
    }
}

class MainView: NSView {
    override func updateLayer() {
        super.updateLayer()
        
        func isDarkmode() -> Bool {
            if #available(OSX 10.14, *) {
                let basicAppearance = self.effectiveAppearance.bestMatch(from: [NSAppearance.Name.aqua, NSAppearance.Name.darkAqua])
                return basicAppearance == NSAppearance.Name.darkAqua
            } else {
                return false
            }
        }
        let newDarkMode = isDarkmode()
        if SettingsData.isDarkMode != newDarkMode {
            SettingsData.isDarkMode = newDarkMode
            
            MainViewController.refreshAllTimeLineViews()
        }
    }
}

private final class SlideBar: NSView {
    var index = -1
    var accessToken = ""
    private var timer: Timer?
    
    override func mouseDragged(with event: NSEvent) {
        let width = SettingsData.viewWidth(accessToken: accessToken) ?? 0
        SettingsData.setViewWidth(accessToken: accessToken, width: width + Float(event.deltaX))
        
        var flag = false
        for account in SettingsData.accountList {
            if flag {
                let width = SettingsData.viewWidth(accessToken: account.1) ?? 0
                SettingsData.setViewWidth(accessToken: account.1, width: width - Float(event.deltaX))
                break
            }
            if account.1 == accessToken {
                flag = true
            }
        }
        
        self.superview?.needsLayout = true
        
        // 0.3秒後に全ビューのレイアウトを更新
        self.timer?.invalidate()
        if #available(OSX 10.12, *) {
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] timer in
                MainViewController.refreshAllTimeLineViews()
                self?.timer = nil
            }
        }
    }
    
    override func resetCursorRects() {
        discardCursorRects()
        addCursorRect(self.bounds, cursor: NSCursor.resizeLeftRight)
    }
}
