//
//  SettingsViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/25.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class SettingsViewController: NSViewController {
    static weak var instance: SettingsViewController?
    static let width: CGFloat = 128
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        let view = SettingsView()
        self.view = view
        
        view.accountButton.action = #selector(accountAction)
        view.generalButton.action = #selector(generalAction)
        view.uiButton.action = #selector(uiAction)
        view.notifyButton.action = #selector(notifyAction)
        view.searchButton.action = #selector(searchAction)
        view.colorButton.action = #selector(colorAction)
        view.detailButton.action = #selector(detailAction)
        view.filter0Button.action = #selector(filter0Action)
        view.filter1Button.action = #selector(filter1Action)
        view.filter2Button.action = #selector(filter2Action)
        view.filter3Button.action = #selector(filter3Action)
        
        SettingsViewController.instance = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func accountAction() {
        guard let view = self.view as? SettingsView else { return }
        DispatchQueue.main.async {
            view.clearHighlight()
            view.accountButton.highlight(true)
        }
        
        self.children.first?.view.removeFromSuperview()
        self.children.first?.removeFromParent()
        
        let vc = AccountSettingsViewController()
        self.addChild(vc)
        self.view.addSubview(vc.view)
    }
    
    @objc func generalAction() {
        guard let view = self.view as? SettingsView else { return }
        DispatchQueue.main.async {
            view.clearHighlight()
            view.generalButton.highlight(true)
        }
        
        self.children.first?.view.removeFromSuperview()
        self.children.first?.removeFromParent()
        
        let vc = GeneralSettingsViewController()
        self.addChild(vc)
        self.view.addSubview(vc.view)
    }
    
    @objc func uiAction() {
        guard let view = self.view as? SettingsView else { return }
        DispatchQueue.main.async {
            view.clearHighlight()
            view.uiButton.highlight(true)
        }
        
        self.children.first?.view.removeFromSuperview()
        self.children.first?.removeFromParent()
        
        let vc = UISettingsViewController()
        self.addChild(vc)
        self.view.addSubview(vc.view)
    }
    
    @objc func notifyAction() {
        guard let view = self.view as? SettingsView else { return }
        DispatchQueue.main.async {
            view.clearHighlight()
            view.notifyButton.highlight(true)
        }
        
        self.children.first?.view.removeFromSuperview()
        self.children.first?.removeFromParent()
        
        let vc = NotifySettingsViewController()
        self.addChild(vc)
        self.view.addSubview(vc.view)
    }
    
    @objc func filter0Action() {
        filterAction(index: 0)
        DispatchQueue.main.async {
            guard let view = self.view as? SettingsView else { return }
            view.filter0Button.highlight(true)
        }
    }
    
    @objc func filter1Action() {
        filterAction(index: 1)
        DispatchQueue.main.async {
            guard let view = self.view as? SettingsView else { return }
            view.filter1Button.highlight(true)
        }
    }
    
    @objc func filter2Action() {
        filterAction(index: 2)
        DispatchQueue.main.async {
            guard let view = self.view as? SettingsView else { return }
            view.filter2Button.highlight(true)
        }
    }
    
    @objc func filter3Action() {
        filterAction(index: 3)
        DispatchQueue.main.async {
            guard let view = self.view as? SettingsView else { return }
            view.filter3Button.highlight(true)
        }
    }
    
    private func filterAction(index: Int) {
        guard let view = self.view as? SettingsView else { return }
        DispatchQueue.main.async {
            view.clearHighlight()
        }
        
        self.children.first?.view.removeFromSuperview()
        self.children.first?.removeFromParent()
        
        let vc = FilterSettingsViewController(index: index)
        self.addChild(vc)
        self.view.addSubview(vc.view)
    }
    
    @objc func searchAction() {
        guard let view = self.view as? SettingsView else { return }
        DispatchQueue.main.async {
            view.clearHighlight()
            view.searchButton.highlight(true)
        }
        
        self.children.first?.view.removeFromSuperview()
        self.children.first?.removeFromParent()
        
        let vc = SearchSettingsViewController()
        self.addChild(vc)
        self.view.addSubview(vc.view)
    }
    
    @objc func colorAction() {
        guard let view = self.view as? SettingsView else { return }
        DispatchQueue.main.async {
            view.clearHighlight()
            view.colorButton.highlight(true)
        }
        
        self.children.first?.view.removeFromSuperview()
        self.children.first?.removeFromParent()
        
        let vc = ColorSettingsViewController()
        self.addChild(vc)
        self.view.addSubview(vc.view)
    }
    
    @objc func detailAction() {
        guard let view = self.view as? SettingsView else { return }
        DispatchQueue.main.async {
            view.clearHighlight()
            view.detailButton.highlight(true)
        }
        
        self.children.first?.view.removeFromSuperview()
        self.children.first?.removeFromParent()
        
        let vc = DetailSettingsViewController()
        self.addChild(vc)
        self.view.addSubview(vc.view)
    }
}

private class SettingsView: NSView {
    private let backView = CALayer()
    let accountButton = NSButton()
    let generalButton = NSButton()
    let uiButton = NSButton()
    let notifyButton = NSButton()
    let searchButton = NSButton()
    let colorButton = NSButton()
    let detailButton = NSButton()
    let filter0Button = NSButton()
    let filter1Button = NSButton()
    let filter2Button = NSButton()
    let filter3Button = NSButton()
    
    init() {
        super.init(frame: SettingsWindow.contentRect)
        
        self.wantsLayer = true
        
        self.layer?.addSublayer(backView)
        self.addSubview(accountButton)
        self.addSubview(generalButton)
        self.addSubview(uiButton)
        self.addSubview(notifyButton)
        self.addSubview(searchButton)
        self.addSubview(colorButton)
        self.addSubview(detailButton)
        self.addSubview(filter0Button)
        self.addSubview(filter1Button)
        self.addSubview(filter2Button)
        self.addSubview(filter3Button)
        
        setProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        backView.backgroundColor = NSColor.white.cgColor
        
        func setButtonStyle(button: NSButton) {
            button.bezelStyle = .shadowlessSquare
            button.showsBorderOnlyWhileMouseInside = true
        }
        
        accountButton.title = I18n.get("SETTINGS_ACCOUNT")
        setButtonStyle(button: accountButton)
        accountButton.highlight(true)
        
        generalButton.title = I18n.get("SETTINGS_GENERAL")
        setButtonStyle(button: generalButton)
        
        uiButton.title = I18n.get("SETTINGS_UI")
        setButtonStyle(button: uiButton)
        
        notifyButton.title = I18n.get("SETTINGS_NOTIFICATIONS")
        setButtonStyle(button: notifyButton)
        
        searchButton.title = I18n.get("SETTINGS_SEARCH")
        setButtonStyle(button: searchButton)
        
        colorButton.title = I18n.get("SETTINGS_COLOR")
        setButtonStyle(button: colorButton)
        
        detailButton.title = I18n.get("SETTINGS_DETAIL")
        setButtonStyle(button: detailButton)
        
        filter0Button.title = I18n.get("SETTINGS_FILTER") + "1\n" + (SettingsData.filterName(index: 0) ?? "").prefix(6)
        setButtonStyle(button: filter0Button)
        
        filter1Button.title = I18n.get("SETTINGS_FILTER") + "2\n" + (SettingsData.filterName(index: 1) ?? "").prefix(6)
        setButtonStyle(button: filter1Button)
        
        filter2Button.title = I18n.get("SETTINGS_FILTER") + "3\n" + (SettingsData.filterName(index: 2) ?? "").prefix(6)
        setButtonStyle(button: filter2Button)
        
        filter3Button.title = I18n.get("SETTINGS_FILTER") + "4\n" + (SettingsData.filterName(index: 3) ?? "").prefix(6)
        setButtonStyle(button: filter3Button)
    }
    
    func clearHighlight() {
        accountButton.highlight(false)
        generalButton.highlight(false)
        uiButton.highlight(false)
        notifyButton.highlight(false)
        searchButton.highlight(false)
        colorButton.highlight(false)
        detailButton.highlight(false)
        filter0Button.highlight(false)
        filter1Button.highlight(false)
        filter2Button.highlight(false)
        filter3Button.highlight(false)
    }
    
    override func layout() {
        let height: CGFloat = 35
        
        backView.frame = NSRect(x: 0,
                                y: 0,
                                width: SettingsViewController.width,
                                height: SettingsWindow.contentRect.height)
        
        accountButton.frame = NSRect(x: 0,
                                     y: SettingsWindow.contentRect.height - height,
                                     width: SettingsViewController.width,
                                     height: height)
        
        generalButton.frame = NSRect(x: 0,
                                     y: SettingsWindow.contentRect.height - height * 2,
                                     width: SettingsViewController.width,
                                     height: height)
        
        uiButton.frame = NSRect(x: 0,
                                y: SettingsWindow.contentRect.height - height * 3,
                                width: SettingsViewController.width,
                                height: height)
        
        notifyButton.frame = NSRect(x: 0,
                                    y: SettingsWindow.contentRect.height - height * 4,
                                    width: SettingsViewController.width,
                                    height: height)
        
        /*searchButton.frame = NSRect(x: 0,
                                    y: SettingsWindow.contentRect.height - height * 5,
                                    width: SettingsViewController.width,
                                    height: height)*/
        
        colorButton.frame = NSRect(x: 0,
                                   y: SettingsWindow.contentRect.height - height * 5,
                                   width: SettingsViewController.width,
                                   height: height)
        
        detailButton.frame = NSRect(x: 0,
                                    y: SettingsWindow.contentRect.height - height * 6,
                                    width: SettingsViewController.width,
                                    height: height)
        
        filter0Button.frame = NSRect(x: 0,
                                     y: SettingsWindow.contentRect.height - height * 7,
                                     width: SettingsViewController.width,
                                     height: height)
        
        filter1Button.frame = NSRect(x: 0,
                                     y: SettingsWindow.contentRect.height - height * 8,
                                     width: SettingsViewController.width,
                                     height: height)
        
        filter2Button.frame = NSRect(x: 0,
                                     y: SettingsWindow.contentRect.height - height * 9,
                                     width: SettingsViewController.width,
                                     height: height)
        
        filter3Button.frame = NSRect(x: 0,
                                     y: SettingsWindow.contentRect.height - height * 10,
                                     width: SettingsViewController.width,
                                     height: height)
    }
}
