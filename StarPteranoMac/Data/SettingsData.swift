//
//  Settings.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/24.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class SettingsData {
    private static let defaults = UserDefaults(suiteName: "Settings")!
    
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        formatter.locale = enUSPosixLocale
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return formatter
    }()
    
    // 接続が確認されたアカウントの情報を保持
    static var accountList: [(String, String)] {
        get {
            var list: [(String, String)] = []
            let array = defaults.array(forKey: "accountList")
            
            for str in array as? [String] ?? [] {
                let items = str.split(separator: ",")
                if items.count < 2 { continue }
                list.append((String(items[0]), String(items[1])))
            }
            
            return list
        }
        set(newValue) {
            var array: [String] = []
            
            for data in newValue {
                array.append(data.0 + "," + data.1)
            }
            
            defaults.set(array, forKey: "accountList")
            defaults.synchronize()
        }
    }
    
    // アカウントの名前を保持
    static func accountUsername(accessToken: String) -> String? {
        return defaults.string(forKey: "accountUsername_\(accessToken)")
    }
    static func setAccountUsername(accessToken: String, value: String) {
        defaults.set(value, forKey: "accountUsername_\(accessToken)")
    }
    
    // アカウントのアイコンのURL文字列を保持
    static func accountIconUrl(accessToken: String) -> String? {
        return defaults.string(forKey: "accountIconUrl_\(accessToken)")
    }
    static func setAccountIconUrl(accessToken: String, value: String) {
        defaults.set(value, forKey: "accountIconUrl_\(accessToken)")
    }
    
    // アカウントの数値IDを保持
    static func accountNumberID(accessToken: String) -> String? {
        return defaults.string(forKey: "accountNumberID_\(accessToken)")
    }
    static func setAccountNumberID(accessToken: String, value: String) {
        defaults.set(value, forKey: "accountNumberID_\(accessToken)")
    }
    
    // アカウントのisLockedを保持
    static func accountLocked(accessToken: String) -> Bool {
        return defaults.string(forKey: "isLocked_\(accessToken)") == "ON"
    }
    static func setAccountLocked(accessToken: String, value: Bool) {
        if value {
            defaults.set("ON", forKey: "isLocked_\(accessToken)")
        } else {
            defaults.removeObject(forKey: "isLocked_\(accessToken)")
        }
    }
    
    // メインウィンドウの位置、大きさ
    static var mainWindowFrame: NSRect? {
        get {
            let str = defaults.object(forKey: "mainWindowFrame") as? String
            let array = str?.split(separator: ",")
            if let array = array, array.count == 4 {
                let x = NumberFormatter().number(from: String(array[0])) as? CGFloat ?? 0
                let y = NumberFormatter().number(from: String(array[1])) as? CGFloat ?? 0
                let width = NumberFormatter().number(from: String(array[2])) as? CGFloat ?? 100
                let height = NumberFormatter().number(from: String(array[3])) as? CGFloat ?? 100
                return NSRect(x: x, y: y, width: max(100, width), height: max(100, height))
            }
            return nil
        }
        set(newValue) {
            if let newValue = newValue {
                let str = "\(newValue.origin.x),\(newValue.origin.y),\(newValue.width),\(newValue.height)"
                defaults.set(str, forKey: "mainWindowFrame")
            }
        }
    }
    
    // 各アカウント別のビューの幅
    static func viewWidth(accessToken: String) -> Float? {
        return defaults.float(forKey: "viewWidth_\(accessToken)")
    }
    static func setViewWidth(accessToken: String, width: Float) {
        defaults.set(width, forKey: "viewWidth_\(accessToken)")
    }
    
    // 設定ウィンドウの位置
    static var settingsWindowOrigin: CGPoint? {
        get {
            let str = defaults.object(forKey: "settingsWindowOrigin") as? String
            let array = str?.split(separator: ",")
            if let array = array, array.count == 2 {
                let x = NumberFormatter().number(from: String(array[0])) as? CGFloat ?? 0
                let y = NumberFormatter().number(from: String(array[1])) as? CGFloat ?? 0
                return CGPoint(x: x, y: y)
            }
            return nil
        }
        set(newValue) {
            if let newValue = newValue {
                let str = "\(newValue.x),\(newValue.y)"
                defaults.set(str, forKey: "settingsWindowOrigin")
            }
        }
    }
    
    // 各アカウントでのタイムライン表示モードを保持
    enum TLMode: String {
        case home = "Home"
        case local = "Local"
        case homeLocal = "HomeLocal"
        case federation = "Federation" // 連合TL
        case list = "List"
        case notifications = "Notifications"
        case dm = "DM"
        case favorites = "Favorites"
        case mentions = "Mentions"
        case users = "Users"
        case search = "Search"
    }
    static func tlMode(key: String) -> [TLMode] {
        if let string = defaults.string(forKey: "tlMode_\(key)") {
            let array = string.split(separator: ",")
            
            var list: [TLMode] = []
            for str in array {
                list.append(TLMode(rawValue: String(str)) ?? .home)
            }
            return list
        }
        return [.home]
    }
    static func setTlMode(key: String, modes: [TLMode]) {
        var string = ""
        for mode in modes {
            if string != "" {
                string += ","
            }
            string += mode.rawValue
        }
        defaults.set(string, forKey: "tlMode_\(key)")
    }
    
    // 各アカウントで優先表示するリストIDを保持
    static func selectedListId(accessToken: String?, index: Int) -> String? {
        guard let accessToken = accessToken else { return nil }
        return defaults.string(forKey: "selectedListId_\(accessToken)_\(index)")
    }
    static func selectListId(accessToken: String?, index: Int, listId: String?) {
        guard let accessToken = accessToken else { return }
        guard let listId = listId else { return }
        
        defaults.set(listId, forKey: "selectedListId_\(accessToken)_\(index)")
    }
    
    // 各アカウントでの最新の既読通知日時を保持
    static func newestNotifyDate(accessToken: String?) -> Date? {
        guard let accessToken = accessToken else { return nil }
        let dateStr = defaults.string(forKey: "newestNotifyDate_\(accessToken)")
        if let dateStr = dateStr {
            return dateFormatter.date(from: dateStr)
        }
        return nil
    }
    static func newestNotifyDate(accessToken: String?, date: Date?) {
        guard let accessToken = accessToken else { return }
        guard let date = date else { return }
        let dateStr = dateFormatter.string(from: date)
        defaults.set(dateStr, forKey: "newestNotifyDate_\(accessToken)")
    }
    
    // タップで詳細に移動
    static var tapDetailMode: Bool {
        get {
            if let string = defaults.string(forKey: "tapDetailMode") {
                return (string == "ON")
            }
            return false
        }
        set(newValue) {
            if newValue {
                defaults.set("ON", forKey: "tapDetailMode")
            } else {
                defaults.removeObject(forKey: "tapDetailMode")
            }
        }
    }
    
    // ミニビューかどうか
    enum MiniView: String {
        case superMini = "superMini"
        case miniView = "miniView"
        case normal = "normal"
        case full = "full"
    }
    private static var _isMiniView: MiniView?
    static var isMiniView: MiniView {
        get {
            if let cache = self._isMiniView {
                return cache
            }
            if let string = defaults.string(forKey: "isMiniView") {
                self._isMiniView = MiniView(rawValue: string) ?? MiniView.normal
                return self._isMiniView!
            }
            self._isMiniView = MiniView.normal
            return MiniView.normal
        }
        set(newValue) {
            self._isMiniView = newValue
            if newValue != MiniView.normal {
                defaults.set(newValue.rawValue, forKey: "isMiniView")
            } else {
                defaults.removeObject(forKey: "isMiniView")
            }
        }
    }
    
    // ダークモードかどうか
    static var isDarkMode: Bool {
        get {
            if let string = defaults.string(forKey: "isDarkMode") {
                return (string == "ON")
            }
            return false
        }
        set(newValue) {
            if newValue {
                defaults.set("ON", forKey: "isDarkMode")
            } else {
                defaults.removeObject(forKey: "isDarkMode")
            }
            
            ThemeColor.change()
        }
    }
    
    // 基準フォントサイズ
    private static var _fontSize: CGFloat?
    static var fontSize: CGFloat {
        get {
            if let cache = self._fontSize {
                return cache
            }
            let value = defaults.double(forKey: "fontSize")
            if value > 0 {
                self._fontSize = CGFloat(value)
                return CGFloat(value)
            }
            self._fontSize = 16
            return 16
        }
        set(newValue) {
            self._fontSize = newValue
            defaults.set(newValue, forKey: "fontSize")
        }
    }
    
    // デフォルトの保護モード
    enum ProtectMode: String {
        case publicMode = "public"
        case unlisted = "unlisted"
        case privateMode = "private"
        case direct = "direct"
    }
    static var protectMode: ProtectMode {
        get {
            if let value = ProtectMode(rawValue: defaults.string(forKey: "protectMode") ?? "") {
                return value
            }
            return ProtectMode.publicMode
        }
        set(newValue) {
            defaults.set(newValue.rawValue, forKey: "protectMode")
        }
    }
    
    // ストリーミングを使用するかどうか
    static var isStreamingMode: Bool {
        get {
            if let string = defaults.string(forKey: "isStreamingMode") {
                return (string == "ON")
            }
            return true
        }
        set(newValue) {
            if newValue {
                defaults.removeObject(forKey: "isStreamingMode")
            } else {
                defaults.set("OFF", forKey: "isStreamingMode")
            }
        }
    }
    
    // アカウント名タップでアイコンタップと同じ処理をするかどうか
    static var isNameTappable: Bool {
        get {
            if let string = defaults.string(forKey: "isNameTappable") {
                return (string == "ON")
            }
            return true
        }
        set(newValue) {
            if newValue {
                defaults.removeObject(forKey: "isNameTappable")
            } else {
                defaults.set("OFF", forKey: "isNameTappable")
            }
        }
    }
    
    // 基準アイコンサイズ
    private static var _iconSize: CGFloat?
    static var iconSize: CGFloat {
        get {
            if let cache = self._iconSize {
                return cache
            }
            let value = defaults.double(forKey: "iconSize")
            if value > 0 {
                self._iconSize = CGFloat(value)
                return CGFloat(value)
            }
            let defaultSize: CGFloat = 38
            self._iconSize = defaultSize
            return defaultSize
        }
        set(newValue) {
            self._iconSize = newValue
            defaults.set(newValue, forKey: "iconSize")
        }
    }
    
    // セルのカラー化を行うかどうか
    private static var _useColoring: Bool?
    static var useColoring: Bool {
        get {
            if let cache = self._useColoring {
                return cache
            }
            if let string = defaults.string(forKey: "useColoring") {
                let value = (string == "ON")
                self._useColoring = value
                return value
            }
            self._useColoring = true
            return true
        }
        set(newValue) {
            self._useColoring = newValue
            
            if newValue {
                defaults.removeObject(forKey: "useColoring")
            } else {
                defaults.set("OFF", forKey: "useColoring")
            }
            
            ThemeColor.change()
        }
    }
    
    // GIFアニメーションを行うかどうか
    private static var _useAnimation: Bool?
    static var useAnimation: Bool {
        get {
            if let cache = self._useAnimation {
                return cache
            }
            if let string = defaults.string(forKey: "useAnimation") {
                let value = (string == "ON")
                self._useAnimation = value
                return value
            }
            self._useAnimation = true
            return true
        }
        set(newValue) {
            self._useAnimation = newValue
            if newValue {
                defaults.removeObject(forKey: "useAnimation")
            } else {
                defaults.set("OFF", forKey: "useAnimation")
            }
        }
    }
    
    // 連合ボタンを表示
    static var showFTLButton: Bool {
        get {
            if let string = defaults.string(forKey: "showFTLButton") {
                return (string == "ON")
            }
            return false
        }
        set(newValue) {
            if newValue {
                defaults.set("ON", forKey: "showFTLButton")
            } else {
                defaults.removeObject(forKey: "showFTLButton")
            }
        }
    }
    
    // リストボタンを表示
    static var showListButton: Bool {
        get {
            if let string = defaults.string(forKey: "showListButton") {
                return (string == "ON")
            }
            return false
        }
        set(newValue) {
            if newValue {
                defaults.set("ON", forKey: "showListButton")
            } else {
                defaults.removeObject(forKey: "showListButton")
            }
        }
    }
    
    // 絵文字キーボードサイズ
    static var emojiKeyboardHeight: CGFloat {
        get {
            let value = defaults.double(forKey: "emojiKeyboardHeight")
            if value > 0 {
                return CGFloat(value)
            }
            let defaultSize: CGFloat = 250
            return defaultSize
        }
        set(newValue) {
            defaults.set(newValue, forKey: "emojiKeyboardHeight")
        }
    }
}
