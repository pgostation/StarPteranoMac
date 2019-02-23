//
//  ThemeColor.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class ThemeColor {
    // 基本の背景色
    static var viewBgColor = NSColor.white
    static var contrastColor = NSColor.white
    static var cellBgColor = NSColor.white
    static var separatorColor = NSColor.white
    
    // トゥートの文字の色
    static var messageColor = NSColor.white
    static var nameColor = NSColor.white
    static var idColor = NSColor.white
    static var dateColor = NSColor.white
    static var linkTextColor = NSColor.blue
    
    // 各種ボタンの色
    static var detailButtonsColor = NSColor.white
    static var detailButtonsHiliteColor = NSColor.white
    static var mainButtonsBgColor = NSColor.white
    static var mainButtonsTitleColor = NSColor.white
    static var buttonBorderColor = NSColor.white
    static var opaqueButtonsBgColor = NSColor.white
    
    // セル選択色
    static var selectedBgColor = NSColor(red: 0.78, green: 1.0, blue: 0.78, alpha: 1)
    static var mentionedMeBgColor = NSColor(red: 0.82, green: 0.98, blue: 0.82, alpha: 1)
    static var sameAccountBgColor = NSColor(red: 0.86, green: 0.96, blue: 0.86, alpha: 1)
    static var mentionedBgColor = NSColor(red: 1.0, green: 0.93, blue: 0.82, alpha: 1)
    static var mentionedSameBgColor = NSColor(red: 0.94, green: 0.91, blue: 0.86, alpha: 1)
    static var toMentionBgColor = NSColor(red: 0.85, green: 0.90, blue: 1.00, alpha: 1)
    
    // DM、プライベート警告バー
    static var directBar = NSColor.white
    static var privateBar = NSColor.white
    static var unlistedBar = NSColor.white
    
    static func change() {
        if SettingsData.isDarkMode {
            // ダークモード
            viewBgColor = NSColor.black
            contrastColor = NSColor.white
            cellBgColor = NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
            separatorColor = NSColor.darkGray
            
            if SettingsData.isTransparentWindow {
                messageColor = NSColor(red: 1, green: 1, blue: 1, alpha: 1)
                idColor = NSColor(red: 1, green: 1, blue: 1, alpha: 1)
                dateColor = NSColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1)
                linkTextColor = NSColor(red: 0.3, green: 0.7, blue: 1, alpha: 1)
                nameColor = NSColor(red: 0.5, green: 1, blue: 0.3, alpha: 1)
            } else {
                messageColor = NSColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1)
                idColor = NSColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1)
                dateColor = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
                linkTextColor = NSColor(red: 0.3, green: 0.5, blue: 1, alpha: 1)
                nameColor = NSColor(red: 0.5, green: 0.8, blue: 0.3, alpha: 1)
            }
            
            detailButtonsColor = NSColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
            detailButtonsHiliteColor = NSColor(red: 0.5, green: 1.0, blue: 0.6, alpha: 1)
            mainButtonsBgColor = NSColor(red: 0.20, green: 0.25, blue: 0.0, alpha: 0.4)
            mainButtonsTitleColor = NSColor(red: 0.7, green: 1.0, blue: 0.1, alpha: 1)
            buttonBorderColor = NSColor(red: 0.7, green: 1.0, blue: 0.1, alpha: 0.8)
            opaqueButtonsBgColor = NSColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
            
            selectedBgColor = NSColor(red: 0.20, green: 0.25, blue: 0.00, alpha: 1)
            mentionedMeBgColor = NSColor(red: 0.16, green: 0.20, blue: 0.03, alpha: 1)
            sameAccountBgColor = NSColor(red: 0.12, green: 0.16, blue: 0.06, alpha: 1)
            mentionedBgColor = NSColor(red: 0.3, green: 0.20, blue: 0.12, alpha: 1)
            mentionedSameBgColor = NSColor(red: 0.24, green: 0.20, blue: 0.16, alpha: 1)
            toMentionBgColor = NSColor(red: 0.15, green: 0.20, blue: 0.30, alpha: 1)
            
            directBar = NSColor(red: 0.6, green: 0, blue: 0, alpha: 1)
            privateBar = NSColor(red: 0.4, green: 0.4, blue: 0, alpha: 1)
            unlistedBar = NSColor(red: 0.0, green: 0.2, blue: 0.6, alpha: 1)
        } else {
            // 通常モード
            viewBgColor = NSColor.white
            contrastColor = NSColor.black
            cellBgColor = NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
            separatorColor = NSColor.lightGray
            
            messageColor = NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
            nameColor = NSColor(red: 0.3, green: 0.7, blue: 0.1, alpha: 1)
            idColor = NSColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1)
            dateColor = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
            linkTextColor = NSColor.blue
            
            detailButtonsColor = NSColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
            detailButtonsHiliteColor = NSColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1)
            mainButtonsBgColor = NSColor(red: 0.88, green: 1.0, blue: 0.68, alpha: 0.4)
            mainButtonsTitleColor = NSColor(red: 0.2, green: 0.4, blue: 0.0, alpha: 1)
            buttonBorderColor = NSColor(red: 0.2, green: 0.4, blue: 0.0, alpha: 0.8)
            opaqueButtonsBgColor = NSColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)
            
            selectedBgColor = NSColor(red: 0.88, green: 1.0, blue: 0.68, alpha: 1)
            mentionedMeBgColor = NSColor(red: 0.90, green: 0.98, blue: 0.75, alpha: 1)
            sameAccountBgColor = NSColor(red: 0.92, green: 0.96, blue: 0.82, alpha: 1)
            mentionedBgColor = NSColor(red: 1.0, green: 0.93, blue: 0.82, alpha: 1)
            mentionedSameBgColor = NSColor(red: 0.94, green: 0.91, blue: 0.86, alpha: 1)
            toMentionBgColor = NSColor(red: 0.85, green: 0.90, blue: 1.00, alpha: 1)
            
            directBar = NSColor(red: 1, green: 0, blue: 0, alpha: 1)
            privateBar = NSColor(red: 1, green: 1, blue: 0, alpha: 1)
            unlistedBar = NSColor(red: 0, green: 0.7, blue: 0.9, alpha: 1)
        }
        
        if !SettingsData.useColoring {
            selectedBgColor = cellBgColor
            mentionedMeBgColor = cellBgColor
            sameAccountBgColor = cellBgColor
            mentionedBgColor = cellBgColor
            mentionedSameBgColor = cellBgColor
            toMentionBgColor = cellBgColor
        }
    }
}
