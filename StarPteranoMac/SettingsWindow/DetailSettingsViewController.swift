//
//  DetailSettingsViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/23.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class DetailSettingsViewController: NSViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        
        let view = DetailSettingsView()
        self.view = view
        
        view.licenseButton.target = self
        view.licenseButton.action = #selector(licenseAction)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func licenseAction() {
        guard let path = Bundle.main.path(forResource: "License", ofType: "text") else { return }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return }
        guard let licenseStr = String(data: data, encoding: String.Encoding.utf8) else { return }
        
        let textView = NSTextView()
        textView.string = licenseStr
        textView.frame = NSRect(x: 0, y: 0, width: 600, height: 500)
        textView.sizeToFit()
        
        let scrollView = NSScrollView()
        scrollView.frame = NSRect(x: 0, y: 0, width: 600, height: 500)
        scrollView.documentView = textView
        
        Dialog.showWithView(message: "", okName: "OK", view: scrollView)
    }
}

final class DetailSettingsView: NSView {
    let licenseButton = NSButton()
    
    init() {
        super.init(frame: SettingsWindow.contentRect)
        
        self.addSubview(licenseButton)
        
        setProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        func setButtonStyle(button: NSButton) {
            button.bezelStyle = .regularSquare
        }
        
        licenseButton.title = I18n.get("BUTTON_LICENSE")
        setButtonStyle(button: licenseButton)
    }
    
    override func layout() {
        let viewWidth = SettingsWindow.contentRect.width - SettingsViewController.width
        
        self.frame = NSRect(x: SettingsViewController.width,
                            y: 0,
                            width: viewWidth,
                            height: SettingsWindow.contentRect.height)
        
        licenseButton.frame = NSRect(x: 30,
                                     y: SettingsWindow.contentRect.height - 50,
                                     width: 200,
                                     height: 30)
    }
}

