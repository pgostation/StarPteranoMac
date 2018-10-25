//
//  SettingsViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/25.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class SettingsViewController: NSViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        
        self.view = SettingsView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class SettingsView: NSView {
    let segmentControl = NSSegmentedControl(frame: NSRect(x: 10, y: SettingsWindow.contentRect.height - 48, width: SettingsWindow.contentRect.width - 20, height: 40))
    
    init() {
        super.init(frame: SettingsWindow.contentRect)
        
        self.addSubview(segmentControl)
        
        setProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        segmentControl.segmentCount = 6
        segmentControl.setLabel(I18n.get("SETTINGS_ACCOUNT"), forSegment: 0)
        segmentControl.setLabel(I18n.get("SETTINGS_GENERAL"), forSegment: 1)
        segmentControl.setLabel(I18n.get("SETTINGS_UI"), forSegment: 2)
        segmentControl.setLabel(I18n.get("SETTINGS_NOTIFICATIONS"), forSegment: 3)
        segmentControl.setLabel(I18n.get("SETTINGS_SEARCH"), forSegment: 4)
        segmentControl.setLabel(I18n.get("SETTINGS_DETAIL"), forSegment: 5)
        
    }
}
