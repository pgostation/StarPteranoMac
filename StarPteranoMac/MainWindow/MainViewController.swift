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
            let bar = NSView()
            bar.wantsLayer = true
            bar.layer?.backgroundColor = NSColor.gray.cgColor
            bar.addCursorRect(NSRect(x: 0, y: 0, width: 3, height: MainWindow.window?.frame.size.height ?? 0),
                              cursor: NSCursor.resizeLeftRight)
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
            let width = CGFloat(SettingsData.viewWidth(accessToken: account.1) ?? 32)
            widthList.append(width)
            sum += width
            if width > maxWidth {
                maxWidth = width
                maxIndex = index
            }
        }
        
        // 最も大きい幅の項目の幅を変化させる
        if maxIndex != -1 {
            widthList[maxIndex] = max(32, widthList[maxIndex] + (size.width - sum))
        }
        
        for index in 0..<self.subVCList.count {
            if index >= widthList.count { continue }
            
            var x = size.width * CGFloat(index) / CGFloat(self.subVCList.count)
            if index > 0 {
                x += 3
            }
            subVCList[index].view.frame = NSRect(x: x,
                                                 y: 0,
                                                 width: widthList[index],
                                                 height: size.height - 50 - 20)
            
            barList[index].frame = NSRect(x: subVCList[index].view.frame.maxX,
                                          y: 0,
                                          width: 3,
                                          height: size.height - 50 - 20)
        }
    }
}

private final class SlideBar: NSView {
    var index = -1
    
    override func mouseDown(with event: NSEvent) {
        print("mouseDown")
    }
    
    override func mouseDragged(with event: NSEvent) {
        print("mouseDragged")
    }
}
