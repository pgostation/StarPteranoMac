//
//  CustomColor.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/09.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class CustomColor {
    private static let userDefaults = UserDefaults(suiteName: "StarPteranoMac_CustomColor")
    
    static var useCustomColor: Bool {
        get {
            return userDefaults?.bool(forKey: "useCustomColor") ?? false
        }
        set {
            userDefaults?.set(newValue, forKey: "useCustomColor")
            
            ThemeColor.change()
        }
    }
    
    static func reset() {
        let dict = userDefaults?.dictionaryRepresentation()
        for (key, _) in dict ?? [:] {
            if key == "useCustomColor" { continue }
            userDefaults?.removeObject(forKey: key)
        }
    }
    
    static var viewBgColor: NSColor {
        get {
            return color(name: "viewBgColor", color: ThemeColor.viewBgColor)
        }
        set {
            set(name: "viewBgColor", color: newValue)
        }
    }
    
    static var contrastColor: NSColor {
        get {
            return color(name: "contrastColor", color: ThemeColor.contrastColor)
        }
        set {
            set(name: "contrastColor", color: newValue)
        }
    }
    
    static var cellBgColor: NSColor {
        get {
            return color(name: "cellBgColor", color: ThemeColor.cellBgColor)
        }
        set {
            set(name: "cellBgColor", color: newValue)
        }
    }
    
    static var messageColor: NSColor {
        get {
            return color(name: "messageColor", color: ThemeColor.messageColor)
        }
        set {
            set(name: "messageColor", color: newValue)
        }
    }
    
    static var nameColor: NSColor {
        get {
            return color(name: "nameColor", color: ThemeColor.nameColor)
        }
        set {
            set(name: "nameColor", color: newValue)
        }
    }
    
    static var idColor: NSColor {
        get {
            return color(name: "idColor", color: ThemeColor.idColor)
        }
        set {
            set(name: "idColor", color: newValue)
        }
    }
    
    static var dateColor: NSColor {
        get {
            return color(name: "dateColor", color: ThemeColor.dateColor)
        }
        set {
            set(name: "dateColor", color: newValue)
        }
    }
    
    static var linkTextColor: NSColor {
        get {
            return color(name: "linkTextColor", color: ThemeColor.linkTextColor)
        }
        set {
            set(name: "linkTextColor", color: newValue)
        }
    }
    
    static var detailButtonsColor: NSColor {
        get {
            return color(name: "detailButtonsColor", color: ThemeColor.detailButtonsColor)
        }
        set {
            set(name: "detailButtonsColor", color: newValue)
        }
    }
    
    static var detailButtonsHiliteColor: NSColor {
        get {
            return color(name: "detailButtonsHiliteColor", color: ThemeColor.detailButtonsHiliteColor)
        }
        set {
            set(name: "detailButtonsHiliteColor", color: newValue)
        }
    }
    
    static var selectedBgColor: NSColor {
        get {
            return color(name: "selectedBgColor", color: ThemeColor.selectedBgColor)
        }
        set {
            set(name: "selectedBgColor", color: newValue)
        }
    }
    
    static var mentionedMeBgColor: NSColor {
        get {
            return color(name: "mentionedMeBgColor", color: ThemeColor.mentionedMeBgColor)
        }
        set {
            set(name: "mentionedMeBgColor", color: newValue)
        }
    }
    
    static var sameAccountBgColor: NSColor {
        get {
            return color(name: "sameAccountBgColor", color: ThemeColor.sameAccountBgColor)
        }
        set {
            set(name: "sameAccountBgColor", color: newValue)
        }
    }
    
    static var mentionedBgColor: NSColor {
        get {
            return color(name: "mentionedBgColor", color: ThemeColor.mentionedBgColor)
        }
        set {
            set(name: "mentionedBgColor", color: newValue)
        }
    }
    
    static var mentionedSameBgColor: NSColor {
        get {
            return color(name: "mentionedSameBgColor", color: ThemeColor.mentionedSameBgColor)
        }
        set {
            set(name: "mentionedSameBgColor", color: newValue)
        }
    }
    
    static var toMentionBgColor: NSColor {
        get {
            return color(name: "toMentionBgColor", color: ThemeColor.toMentionBgColor)
        }
        set {
            set(name: "toMentionBgColor", color: newValue)
        }
    }
    
    static var directBar: NSColor {
        get {
            return color(name: "directBar", color: ThemeColor.directBar)
        }
        set {
            set(name: "directBar", color: newValue)
        }
    }
    
    static var privateBar: NSColor {
        get {
            return color(name: "privateBar", color: ThemeColor.privateBar)
        }
        set {
            set(name: "privateBar", color: newValue)
        }
    }
    
    static var unlistedBar: NSColor {
        get {
            return color(name: "unlistedBar", color: ThemeColor.unlistedBar)
        }
        set {
            set(name: "unlistedBar", color: newValue)
        }
    }
    
    private static func color(name: String, color: NSColor) -> NSColor {
        let color2 = color.usingColorSpace(NSColorSpace.deviceRGB) ?? color
        
        var r = CGFloat(userDefaults?.double(forKey: "\(name).r") ?? 0)
        if r == 0 {
            color2.getRed(&r, green: nil, blue: nil, alpha: nil)
        }
        
        var g = CGFloat(userDefaults?.double(forKey: "\(name).g") ?? 0)
        if g == 0 {
            color2.getRed(nil, green: &g, blue: nil, alpha: nil)
        }
        
        var b = CGFloat(userDefaults?.double(forKey: "\(name).b") ?? 0)
        if b == 0 {
            color2.getRed(nil, green: nil, blue: &b, alpha: nil)
        }
        
        return NSColor(red: r, green: g, blue: b, alpha: 1)
    }
    
    private static func set(name: String, color: NSColor) {
        userDefaults?.set(Double(color.redComponent), forKey: "\(name).r")
        userDefaults?.set(Double(color.greenComponent), forKey: "\(name).g")
        userDefaults?.set(Double(color.blueComponent), forKey: "\(name).b")
        
        ThemeColor.change()
    }
}
