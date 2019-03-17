//
//  FilterSettingsViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/17.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class FilterSettingsViewController: NSViewController, NSTabViewDelegate {
    init() {
        super.init(nibName: nil, bundle: nil)
        
        let view = FilterSettingsView()
        self.view = view
        
        view.tabView.delegate = self
        
        self.tabView(view.tabView, didSelect: view.tabView.tabViewItems.first)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        self.children.first?.view.removeFromSuperview()
        self.children.first?.removeFromParent()
        
        if let identifier = tabView.selectedTabViewItem?.identifier {
            switch identifier as? String {
            case "FILTER_TAB_ACCOUNT":
                let vc = FilterAccountViewController()
                self.addChild(vc)
                self.view.addSubview(vc.view)
            case "FILTER_TAB_KEYWORD":
                let vc = FilterKeywordViewController()
                self.addChild(vc)
                self.view.addSubview(vc.view)
            case "FILTER_TAB_REGEXP":
                let vc = FilterRegExpViewController()
                self.addChild(vc)
                self.view.addSubview(vc.view)
            default:
                break
            }
        }
    }
}

final class FilterSettingsView: NSView {
    static let contentRect = NSRect(x: 0,
                                    y: 0,
                                    width: SettingsWindow.contentRect.width - SettingsViewController.width,
                                    height: SettingsWindow.contentRect.height - 30)
    
    let tabView = NSTabView()
    
    init() {
        super.init(frame: SettingsWindow.contentRect)
        
        self.addSubview(tabView)
        
        setProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        let items = ["FILTER_TAB_ACCOUNT", "FILTER_TAB_KEYWORD", "FILTER_TAB_REGEXP"]
        for item in items {
            let tabItem = NSTabViewItem(identifier: item)
            tabItem.label = I18n.get(item)
            tabView.addTabViewItem(tabItem)
        }
    }
    
    override func layout() {
        let viewWidth = SettingsWindow.contentRect.width - SettingsViewController.width
        
        self.frame = NSRect(x: SettingsViewController.width,
                            y: 0,
                            width: viewWidth,
                            height: SettingsWindow.contentRect.height)
        
        tabView.frame = NSRect(x: viewWidth / 2 - 400 / 2,
                               y: SettingsWindow.contentRect.height - 30,
                               width: 400,
                               height: 25)
    }
}
