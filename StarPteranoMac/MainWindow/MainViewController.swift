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
    var timelineList: [String: TimeLineViewController] = [:]
    private var subVCList: [SubViewController] = []
    private var barList: [NSView] = []
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        self.view = NSView()
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
            bar.layer?.backgroundColor = NSColor.gray.cgColor
            barList.append(bar)
            self.view.addSubview(bar)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        // 最も大きい幅の項目の幅を変化させる
        if maxIndex != -1 {
            widthList[maxIndex] = max(48, widthList[maxIndex] + (size.width - sum))
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
                                                 height: size.height - 50 - 20)
            
            barList[index].frame = NSRect(x: subVCList[index].view.frame.maxX,
                                          y: 0,
                                          width: 3,
                                          height: size.height - 50 - 20)
            
            right = barList[index].frame.maxX
        }
    }
}

private final class SlideBar: NSView {
    var index = -1
    var accessToken = ""
    
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
    }
    
    override func resetCursorRects() {
        discardCursorRects()
        addCursorRect(self.bounds, cursor: NSCursor.resizeLeftRight)
    }
}
