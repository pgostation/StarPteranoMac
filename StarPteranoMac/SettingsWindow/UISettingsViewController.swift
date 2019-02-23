//
//  UISettingsViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/23.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class UISettingsViewController: NSViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        
        let view = UISettingsView()
        self.view = view
        
        view.usingColorButton.action = #selector(usingColorAction(_:))
        view.usingColorButton.target = self
        view.iconSizeStepper.action = #selector(iconSizeAction(_:))
        view.iconSizeStepper.target = self
        view.loadPreviewButton.action = #selector(loadPreviewAction(_:))
        view.loadPreviewButton.target = self
        view.useAnimationButton.action = #selector(useAnimationAction(_:))
        view.useAnimationButton.target = self
        view.useAbsoluteTimeButton.action = #selector(useAbsoluteTimeAction(_:))
        view.useAbsoluteTimeButton.target = self
        view.favDialogButton.action = #selector(favDialogAction(_:))
        view.favDialogButton.target = self
        view.transparentButton.action = #selector(transparentAction(_:))
        view.transparentButton.target = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func usingColorAction(_ sender: NSButton) {
        SettingsData.useColoring = (sender.state == .on)
    }
    
    @objc func iconSizeAction(_ sender: NSStepper) {
        SettingsData.iconSize = CGFloat(sender.integerValue)
        
        guard let view = self.view as? UISettingsView else { return }
        view.setProperties()
    }
    
    @objc func loadPreviewAction(_ sender: NSButton) {
        SettingsData.isLoadPreviewImage = (sender.state == .on)
    }
    
    @objc func useAnimationAction(_ sender: NSButton) {
        SettingsData.useAnimation = (sender.state == .on)
    }
    
    @objc func useAbsoluteTimeAction(_ sender: NSButton) {
        SettingsData.useAbsoluteTime = (sender.state == .on)
    }
    
    @objc func favDialogAction(_ sender: NSButton) {
        SettingsData.showFavDialog = (sender.state == .on)
    }
    
    @objc func transparentAction(_ sender: NSButton) {
        SettingsData.isTransparentWindow = (sender.state == .on)
    }
}

final class UISettingsView: NSView {
    let usingColorButton = NSButton()
    let iconSizeStepper = NSStepper()
    let iconSizeLabel = CATextLayer()
    let loadPreviewButton = NSButton()
    let useAnimationButton = NSButton()
    let useAbsoluteTimeButton = NSButton()
    let favDialogButton = NSButton()
    let transparentButton = NSButton()
    
    init() {
        super.init(frame: SettingsWindow.contentRect)
        
        self.wantsLayer = true
        
        self.addSubview(usingColorButton)
        self.addSubview(iconSizeStepper)
        self.layer?.addSublayer(iconSizeLabel)
        self.addSubview(loadPreviewButton)
        self.addSubview(useAnimationButton)
        self.addSubview(useAbsoluteTimeButton)
        self.addSubview(favDialogButton)
        self.addSubview(transparentButton)
        
        setProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setProperties() {
        func setCheckboxStyle(button: NSButton) {
            button.setButtonType(NSButton.ButtonType.switch)
        }
        
        usingColorButton.title = I18n.get("BUTTON_USING_COLOR")
        setCheckboxStyle(button: usingColorButton)
        usingColorButton.state = SettingsData.useColoring ? .on : .off
        
        iconSizeStepper.integerValue = Int(SettingsData.iconSize)
        
        iconSizeLabel.string = I18n.get("LABEL_ICONSIZE") + ": " + "\(Int(SettingsData.iconSize))"
        iconSizeLabel.fontSize = 12
        iconSizeLabel.contentsScale = (NSScreen.main?.backingScaleFactor)!
        iconSizeLabel.foregroundColor = NSColor.black.cgColor
        
        loadPreviewButton.title = I18n.get("BUTTON_LOAD_PREVIEW")
        setCheckboxStyle(button: loadPreviewButton)
        loadPreviewButton.state = SettingsData.isLoadPreviewImage ? .on : .off
        
        useAnimationButton.title = I18n.get("BUTTON_USE_ANIMATION")
        setCheckboxStyle(button: useAnimationButton)
        useAnimationButton.state = SettingsData.useAnimation ? .on : .off
        
        useAbsoluteTimeButton.title = I18n.get("BUTTON_ABSOLUTE_TIME")
        setCheckboxStyle(button: useAbsoluteTimeButton)
        useAbsoluteTimeButton.state = SettingsData.useAbsoluteTime ? .on : .off
        
        favDialogButton.title = I18n.get("BUTTON_FAVORITE_DIALOG")
        setCheckboxStyle(button: favDialogButton)
        favDialogButton.state = SettingsData.showFavDialog ? .on : .off
        
        transparentButton.title = I18n.get("BUTTON_TRANSPARENT_WINDOW")
        setCheckboxStyle(button: transparentButton)
        transparentButton.state = SettingsData.isTransparentWindow ? .on : .off
    }
    
    override func layout() {
        let viewWidth = SettingsWindow.contentRect.width - SettingsViewController.width
        
        self.frame = NSRect(x: SettingsViewController.width,
                            y: 0,
                            width: viewWidth,
                            height: SettingsWindow.contentRect.height)
        
        usingColorButton.frame = NSRect(x: 30,
                                        y: SettingsWindow.contentRect.height - 50,
                                        width: 200,
                                        height: 20)
        
        let labelSize = iconSizeLabel.preferredFrameSize()
        iconSizeLabel.frame = NSRect(x: 30,
                                       y: SettingsWindow.contentRect.height - 100,
                                       width: labelSize.width,
                                       height: 20)
        
        iconSizeStepper.frame = NSRect(x: iconSizeLabel.frame.maxX + 5,
                                       y: SettingsWindow.contentRect.height - 100,
                                       width: 20,
                                       height: 30)
        
        loadPreviewButton.frame = NSRect(x: 30,
                                         y: SettingsWindow.contentRect.height - 150,
                                         width: 200,
                                         height: 20)
        
        useAnimationButton.frame = NSRect(x: 30,
                                          y: SettingsWindow.contentRect.height - 200,
                                          width: 200,
                                          height: 20)
        
        useAbsoluteTimeButton.frame = NSRect(x: 30,
                                             y: SettingsWindow.contentRect.height - 250,
                                             width: 200,
                                             height: 20)
        
        favDialogButton.frame = NSRect(x: 30,
                                       y: SettingsWindow.contentRect.height - 300,
                                       width: 200,
                                       height: 20)
        
        transparentButton.frame = NSRect(x: 30,
                                         y: SettingsWindow.contentRect.height - 350,
                                         width: 200,
                                         height: 20)
    }
}

