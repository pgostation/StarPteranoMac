//
//  ColorSettingsViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/09.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class ColorSettingsViewController: NSViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        
        let view = ColorSettingsView()
        self.view = view
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ColorSettingsView: NSView {
    private let scrollView = NSScrollView()
    private let mainView = NSView()
    
    private let useColorButton = NSButton()
    private let resetButton = NSButton()
    
    private let viewBgColor: ColorEditView
    private let contrastColor: ColorEditView
    private let cellBgColor: ColorEditView
    
    private let messageColor: ColorEditView
    private let idColor: ColorEditView
    private let dateColor: ColorEditView
    private let linkTextColor: ColorEditView
    private let nameColor: ColorEditView
    
    private let detailButtonsColor: ColorEditView
    private let detailButtonsHiliteColor: ColorEditView
    
    private let selectedBgColor: ColorEditView
    private let mentionedMeBgColor: ColorEditView
    private let sameAccountBgColor: ColorEditView
    private let mentionedBgColor: ColorEditView
    private let mentionedSameBgColor: ColorEditView
    private let toMentionBgColor: ColorEditView
    
    private let directBar: ColorEditView
    private let privateBar: ColorEditView
    private let unlistedBar: ColorEditView
    
    private lazy var colorEditViews: [ColorEditView] = [
        viewBgColor,
        contrastColor,
        cellBgColor,
        messageColor,
        idColor,
        dateColor,
        linkTextColor,
        nameColor,
        detailButtonsColor,
        detailButtonsHiliteColor,
        selectedBgColor,
        mentionedMeBgColor,
        sameAccountBgColor,
        mentionedBgColor,
        mentionedSameBgColor,
        toMentionBgColor,
        directBar,
        privateBar,
        unlistedBar,
        ]
    private let labels: [String] = [
        "viewBgColor",
        "contrastColor",
        "cellBgColor",
        "messageColor",
        "idColor",
        "dateColor",
        "linkTextColor",
        "nameColor",
        "detailButtonsColor",
        "detailButtonsHiliteColor",
        "selectedBgColor",
        "mentionedMeBgColor",
        "sameAccountBgColor",
        "mentionedBgColor",
        "mentionedSameBgColor",
        "toMentionBgColor",
        "directBar",
        "privateBar",
        "unlistedBar",
        ]
    
    init() {
        self.viewBgColor = ColorEditView(color: CustomColor.viewBgColor) { color in
            CustomColor.viewBgColor = color
        }
        self.contrastColor = ColorEditView(color: CustomColor.contrastColor) { color in
            CustomColor.contrastColor = color
        }
        self.cellBgColor = ColorEditView(color: CustomColor.cellBgColor) { color in
            CustomColor.cellBgColor = color
        }
        
        self.messageColor = ColorEditView(color: CustomColor.messageColor) { color in
            CustomColor.messageColor = color
        }
        self.idColor = ColorEditView(color: CustomColor.idColor) { color in
            CustomColor.idColor = color
        }
        self.dateColor = ColorEditView(color: CustomColor.dateColor) { color in
            CustomColor.dateColor = color
        }
        self.linkTextColor = ColorEditView(color: CustomColor.linkTextColor) { color in
            CustomColor.linkTextColor = color
        }
        self.nameColor = ColorEditView(color: CustomColor.nameColor) { color in
            CustomColor.nameColor = color
        }
        
        self.detailButtonsColor = ColorEditView(color: CustomColor.detailButtonsColor) { color in
            CustomColor.detailButtonsColor = color
        }
        self.detailButtonsHiliteColor = ColorEditView(color: CustomColor.detailButtonsHiliteColor) { color in
            CustomColor.detailButtonsHiliteColor = color
        }
        
        self.selectedBgColor = ColorEditView(color: CustomColor.selectedBgColor) { color in
            CustomColor.selectedBgColor = color
        }
        self.mentionedMeBgColor = ColorEditView(color: CustomColor.mentionedMeBgColor) { color in
            CustomColor.mentionedMeBgColor = color
        }
        self.sameAccountBgColor = ColorEditView(color: CustomColor.sameAccountBgColor) { color in
            CustomColor.sameAccountBgColor = color
        }
        self.mentionedBgColor = ColorEditView(color: CustomColor.mentionedBgColor) { color in
            CustomColor.mentionedBgColor = color
        }
        self.mentionedSameBgColor = ColorEditView(color: CustomColor.mentionedSameBgColor) { color in
            CustomColor.mentionedSameBgColor = color
        }
        self.toMentionBgColor = ColorEditView(color: CustomColor.toMentionBgColor) { color in
            CustomColor.toMentionBgColor = color
        }
        
        self.directBar = ColorEditView(color: CustomColor.directBar) { color in
            CustomColor.directBar = color
        }
        self.privateBar = ColorEditView(color: CustomColor.privateBar) { color in
            CustomColor.privateBar = color
        }
        self.unlistedBar = ColorEditView(color: CustomColor.unlistedBar) { color in
            CustomColor.unlistedBar = color
        }
        
        super.init(frame: SettingsWindow.contentRect)
        
        self.addSubview(useColorButton)
        self.addSubview(resetButton)
        self.addSubview(scrollView)
        scrollView.documentView = mainView
        
        setProperties()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            let top = CGFloat(self.colorEditViews.count) * 30 + 10
            self.scrollView.documentView?.scroll(NSPoint(x: 0, y: top - 1))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        useColorButton.title = I18n.get("SETTINGS_COLOR_USE_CUSTOM")
        useColorButton.setButtonType(NSButton.ButtonType.switch)
        useColorButton.state = CustomColor.useCustomColor ? .on : .off
        
        useColorButton.target = self
        useColorButton.action = #selector(useColorAction)
        
        resetButton.title = I18n.get("SETTINGS_COLOR_RESET")
        resetButton.bezelStyle = .regularSquare
        
        resetButton.target = self
        resetButton.action = #selector(resetAction)
        
        var top = CGFloat(colorEditViews.count) * 30 + 10
        
        for colorEditView in colorEditViews {
            self.mainView.addSubview(colorEditView)
            
            top -= 30
            
            colorEditView.frame = NSRect(x: 210,
                                 y: top,
                                 width: 300,
                                 height: 30)
        }
        
        top = CGFloat(colorEditViews.count) * 30 + 10
        for str in labels {
            let label = NSTextField()
            label.stringValue = I18n.get(str)
            label.isBezeled = false
            label.isEditable = false
            label.isSelectable = false
            label.drawsBackground = false
            
            self.mainView.addSubview(label)
            
            top -= 30
            
            label.frame = NSRect(x: 10,
                                 y: top,
                                 width: 200,
                                 height: 20)
        }
    }
    
    @objc func useColorAction() {
        CustomColor.useCustomColor = (useColorButton.state == .on)
    }
    
    @objc func resetAction() {
        CustomColor.reset()
        
        SettingsViewController.instance?.colorAction()
    }
    
    override func layout() {
        let viewWidth = SettingsWindow.contentRect.width - SettingsViewController.width
        
        self.frame = NSRect(x: SettingsViewController.width,
                            y: 0,
                            width: viewWidth,
                            height: SettingsWindow.contentRect.height)
        
        useColorButton.frame = NSRect(x: 20,
                                      y: SettingsWindow.contentRect.height - 30,
                                      width: 200,
                                      height: 20)
        
        resetButton.frame = NSRect(x: 230,
                                   y: SettingsWindow.contentRect.height - 30,
                                   width: 80,
                                   height: 20)
        
        scrollView.frame = NSRect(x: 0,
                                  y: 0,
                                  width: viewWidth,
                                  height: SettingsWindow.contentRect.height - 30)
        
        mainView.frame = NSRect(x: 0,
                                y: 0,
                                width: viewWidth,
                                height: CGFloat(colorEditViews.count) * 30 + 10)
    }
}

private class ColorEditView: NSView {
    private let colorView = NSView()
    private let redSlider = NSSlider()
    private let greenSlider = NSSlider()
    private let blueSlider = NSSlider()
    private let callback: (NSColor)->Void
    
    init(color: NSColor, callback: @escaping (NSColor)->Void) {
        self.callback = callback
        
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        
        self.redSlider.maxValue = 1
        self.redSlider.minValue = 0
        self.redSlider.doubleValue = Double(color.redComponent)
        self.redSlider.wantsLayer = true
        self.redSlider.layer?.backgroundColor = NSColor.red.withAlphaComponent(0.3).cgColor
        self.redSlider.target = self
        self.redSlider.action = #selector(change)
        
        self.greenSlider.maxValue = 1
        self.greenSlider.minValue = 0
        self.greenSlider.doubleValue = Double(color.greenComponent)
        self.greenSlider.wantsLayer = true
        self.greenSlider.layer?.backgroundColor = NSColor.green.withAlphaComponent(0.3).cgColor
        self.greenSlider.target = self
        self.greenSlider.action = #selector(change)
        
        self.blueSlider.maxValue = 1
        self.blueSlider.minValue = 0
        self.blueSlider.doubleValue = Double(color.blueComponent)
        self.blueSlider.wantsLayer = true
        self.blueSlider.layer?.backgroundColor = NSColor.blue.withAlphaComponent(0.3).cgColor
        self.blueSlider.target = self
        self.blueSlider.action = #selector(change)
        
        self.colorView.wantsLayer = true
        self.colorView.layer?.backgroundColor = color.cgColor
        
        self.addSubview(colorView)
        self.addSubview(redSlider)
        self.addSubview(greenSlider)
        self.addSubview(blueSlider)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func change() {
        let color = NSColor(red: CGFloat(self.redSlider.doubleValue),
                            green: CGFloat(self.greenSlider.doubleValue),
                            blue: CGFloat(self.blueSlider.doubleValue),
                            alpha: 1)
        
        callback(color)
        
        self.colorView.layer?.backgroundColor = color.cgColor
    }
    
    override func layout() {
        self.colorView.frame = NSRect(x: 0,
                                      y: 0,
                                      width: 25,
                                      height: 20)
        
        self.redSlider.frame = NSRect(x: 30,
                                      y: 0,
                                      width: 80,
                                      height: 20)
        
        self.greenSlider.frame = NSRect(x: 120,
                                        y: 0,
                                        width: 80,
                                        height: 20)
        
        self.blueSlider.frame = NSRect(x: 210,
                                       y: 0,
                                       width: 80,
                                       height: 20)
    }
}
