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
        view.loadPreviewButton.action = #selector(loadPreviewAction(_:))
        view.loadPreviewButton.target = self
        view.useAnimationButton.action = #selector(useAnimationAction(_:))
        view.useAnimationButton.target = self
        view.useAbsoluteTimeButton.action = #selector(useAbsoluteTimeAction(_:))
        view.useAbsoluteTimeButton.target = self
        view.transparentButton.action = #selector(transparentAction(_:))
        view.transparentButton.target = self
        view.darkmodeButton.action = #selector(darkmodeAction(_:))
        view.darkmodeButton.target = self
        
        view.iconSizeStepper.action = #selector(iconSizeAction(_:))
        view.iconSizeStepper.target = self
        view.fontSizeStepper.action = #selector(fontSizeAction(_:))
        view.fontSizeStepper.target = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func usingColorAction(_ sender: NSButton) {
        SettingsData.useColoring = (sender.state == .on)
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
    
    @objc func transparentAction(_ sender: NSButton) {
        SettingsData.isTransparentWindow = (sender.state == .on)
    }
    
    @objc func darkmodeAction(_ sender: NSButton) {
        SettingsData.forceDarkMode = (sender.state == .on)
        
        MainViewController.refreshAllTimeLineViews()
    }
    
    @objc func iconSizeAction(_ sender: NSStepper) {
        SettingsData.iconSize = min(200, max(1, CGFloat(sender.integerValue)))
        
        guard let view = self.view as? UISettingsView else { return }
        view.setProperties()
        view.needsLayout = true
        
        MainViewController.refreshAllTimeLineViews()
    }
    
    @objc func fontSizeAction(_ sender: NSStepper) {
        SettingsData.fontSize = min(100, max(1, CGFloat(sender.integerValue)))
        
        guard let view = self.view as? UISettingsView else { return }
        view.setProperties()
        view.needsLayout = true
        
        MainViewController.refreshAllTimeLineViews()
    }
}

final class UISettingsView: NSView {
    let usingColorButton = NSButton()
    let loadPreviewButton = NSButton()
    let useAnimationButton = NSButton()
    let useAbsoluteTimeButton = NSButton()
    let transparentButton = NSButton()
    let darkmodeButton = NSButton()
    
    let iconSizeStepper = NSStepper()
    let iconSizeLabel = CATextLayer()
    let fontSizeStepper = NSStepper()
    let fontSizeLabel = CATextLayer()
    
    init() {
        super.init(frame: SettingsWindow.contentRect)
        
        self.wantsLayer = true
        
        self.addSubview(usingColorButton)
        self.addSubview(loadPreviewButton)
        self.addSubview(useAnimationButton)
        self.addSubview(useAbsoluteTimeButton)
        self.addSubview(transparentButton)
        self.addSubview(darkmodeButton)
        
        self.addSubview(iconSizeStepper)
        self.layer?.addSublayer(iconSizeLabel)
        self.addSubview(fontSizeStepper)
        self.layer?.addSublayer(fontSizeLabel)
        
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
        
        loadPreviewButton.title = I18n.get("BUTTON_LOAD_PREVIEW")
        setCheckboxStyle(button: loadPreviewButton)
        loadPreviewButton.state = SettingsData.isLoadPreviewImage ? .on : .off
        
        useAnimationButton.title = I18n.get("BUTTON_USE_ANIMATION")
        setCheckboxStyle(button: useAnimationButton)
        useAnimationButton.state = SettingsData.useAnimation ? .on : .off
        
        useAbsoluteTimeButton.title = I18n.get("BUTTON_ABSOLUTE_TIME")
        setCheckboxStyle(button: useAbsoluteTimeButton)
        useAbsoluteTimeButton.state = SettingsData.useAbsoluteTime ? .on : .off
        
        transparentButton.title = I18n.get("BUTTON_TRANSPARENT_WINDOW")
        setCheckboxStyle(button: transparentButton)
        transparentButton.state = SettingsData.isTransparentWindow ? .on : .off
        
        darkmodeButton.title = I18n.get("BUTTON_FORCE_DARKMODE")
        setCheckboxStyle(button: darkmodeButton)
        darkmodeButton.state = SettingsData.forceDarkMode ? .on : .off
        
        iconSizeStepper.integerValue = Int(SettingsData.iconSize)
        iconSizeStepper.maxValue = 999
        
        iconSizeLabel.string = I18n.get("LABEL_ICONSIZE") + ": " + "\(Int(SettingsData.iconSize))"
        iconSizeLabel.fontSize = 12
        iconSizeLabel.contentsScale = (NSScreen.main?.backingScaleFactor)!
        iconSizeLabel.foregroundColor = NSColor.black.cgColor
        
        fontSizeStepper.integerValue = Int(SettingsData.fontSize)
        fontSizeStepper.maxValue = 999
        
        fontSizeLabel.string = I18n.get("LABEL_FONTSIZE") + ": " + "\(Int(SettingsData.fontSize))"
        fontSizeLabel.fontSize = 12
        fontSizeLabel.contentsScale = (NSScreen.main?.backingScaleFactor)!
        fontSizeLabel.foregroundColor = NSColor.black.cgColor
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
        
        loadPreviewButton.frame = NSRect(x: 30,
                                         y: SettingsWindow.contentRect.height - 100,
                                         width: 200,
                                         height: 20)
        
        useAnimationButton.frame = NSRect(x: 30,
                                          y: SettingsWindow.contentRect.height - 150,
                                          width: 200,
                                          height: 20)
        
        useAbsoluteTimeButton.frame = NSRect(x: 30,
                                             y: SettingsWindow.contentRect.height - 200,
                                             width: 200,
                                             height: 20)
        
        transparentButton.frame = NSRect(x: 30,
                                         y: SettingsWindow.contentRect.height - 250,
                                         width: 200,
                                         height: 20)
        
        darkmodeButton.frame = NSRect(x: 30,
                                      y: SettingsWindow.contentRect.height - 300,
                                      width: 200,
                                      height: 20)
        
        let labelSize = iconSizeLabel.preferredFrameSize()
        iconSizeLabel.frame = NSRect(x: 250,
                                     y: SettingsWindow.contentRect.height - 50,
                                     width: labelSize.width,
                                     height: 20)
        
        iconSizeStepper.frame = NSRect(x: iconSizeLabel.frame.maxX + 5,
                                       y: SettingsWindow.contentRect.height - 50,
                                       width: 20,
                                       height: 30)
        
        let fontLabelSize = fontSizeLabel.preferredFrameSize()
        fontSizeLabel.frame = NSRect(x: 250,
                                     y: SettingsWindow.contentRect.height - 100,
                                     width: fontLabelSize.width,
                                     height: 20)
        
        fontSizeStepper.frame = NSRect(x: fontSizeLabel.frame.maxX + 5,
                                       y: SettingsWindow.contentRect.height - 100,
                                       width: 20,
                                       height: 30)
    }
}

