//
//  Settings.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/24.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class SettingsData {
    private static let defaults = UserDefaults(suiteName: "StarPteranoMac_Settings")!
    
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
    
    // インスタンスのversionを保持
    static func instanceVersion(hostName: String) -> Double {
        return defaults.double(forKey: "instanceVersion_\(hostName)")
    }
    static func setInstanceVersion(hostName: String, value: Double) {
        defaults.set(value, forKey: "instanceVersion_\(hostName)")
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
        return [.home, .homeLocal, .mentions, .notifications, .dm, .favorites]
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
        defaults.synchronize()
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
    
    // 最初のアプリ起動か？
    static var firstExec: Bool {
        get {
            if defaults.string(forKey: "firstExec") != nil {
                return false
            }
            
            defaults.set("ON", forKey: "firstExec")
            return true
        }
    }
    
    // 強制ダークモード
    static var forceDarkMode: Bool {
        get {
            if let string = defaults.string(forKey: "forceDarkMode") {
                return (string == "ON")
            }
            return false
        }
        set(newValue) {
            if newValue {
                defaults.set("ON", forKey: "forceDarkMode")
            } else {
                defaults.removeObject(forKey: "forceDarkMode")
            }
            
            ThemeColor.change()
        }
    }
    
    // ダークモードかどうか
    static var isDarkMode: Bool {
        get {
            if forceDarkMode {
                return true
            }
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
            self._fontSize = 14
            return 14
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
    
    // プレビュー画像を読み込むかどうか
    static var isLoadPreviewImage: Bool {
        get {
            if let string = defaults.string(forKey: "isLoadPreviewImage") {
                return (string == "ON")
            }
            return true
        }
        set(newValue) {
            if newValue {
                defaults.removeObject(forKey: "isLoadPreviewImage")
            } else {
                defaults.set("OFF", forKey: "isLoadPreviewImage")
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
            let defaultSize: CGFloat = 42
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
    
    // カスタム絵文字アニメーションを行うかどうか
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
    
    // 絶対時間表示
    static var useAbsoluteTime: Bool {
        get {
            if let string = defaults.string(forKey: "useAbsoluteTime") {
                return (string == "ON")
            }
            return false
        }
        set(newValue) {
            if newValue {
                defaults.set("ON", forKey: "useAbsoluteTime")
            } else {
                defaults.removeObject(forKey: "useAbsoluteTime")
            }
        }
    }
    
    // ウィンドウを透明化
    private static var _isTransparentWindow: Bool?
    static var isTransparentWindow: Bool {
        get {
            if let cache = self._isTransparentWindow {
                return cache
            }
            if let string = defaults.string(forKey: "isTransparentWindow") {
                let result = (string == "ON")
                self._isTransparentWindow = result
                return result
            }
            self._isTransparentWindow = false
            return false
        }
        set(newValue) {
            if newValue != isTransparentWindow {
                DispatchQueue.main.async {
                    MainWindow.window?.close()
                    DispatchQueue.main.async {
                        MainWindow.show()
                    }
                }
            }
            self._isTransparentWindow = newValue
            
            if newValue {
                defaults.set("ON", forKey: "isTransparentWindow")
            } else {
                defaults.removeObject(forKey: "isTransparentWindow")
            }
            
            ThemeColor.change()
        }
    }
    
    // デフォルトでNSFWを有効にするか
    static var defaultNSFW: Bool {
        get {
            if let string = defaults.string(forKey: "defaultNSFW") {
                let value = (string == "ON")
                return value
            }
            return false
        }
        set(newValue) {
            if newValue {
                defaults.set("ON", forKey: "defaultNSFW")
            } else {
                defaults.removeObject(forKey: "defaultNSFW")
            }
        }
    }
    
    // メンション通知を有効にするかどうか
    static var notifyMentions: Bool {
        get {
            if let string = defaults.string(forKey: "notifyMentions") {
                let value = (string == "ON")
                return value
            }
            return true
        }
        set(newValue) {
            if newValue {
                defaults.removeObject(forKey: "notifyMentions")
            } else {
                defaults.set("OFF", forKey: "notifyMentions")
            }
        }
    }
    
    // お気に入り通知を有効にするかどうか
    static var notifyFavorites: Bool {
        get {
            if let string = defaults.string(forKey: "notifyFavorites") {
                let value = (string == "ON")
                return value
            }
            return true
        }
        set(newValue) {
            if newValue {
                defaults.removeObject(forKey: "notifyFavorites")
            } else {
                defaults.set("OFF", forKey: "notifyFavorites")
            }
        }
    }
    
    // ブースト通知を有効にするかどうか
    static var notifyBoosts: Bool {
        get {
            if let string = defaults.string(forKey: "notifyBoosts") {
                let value = (string == "ON")
                return value
            }
            return true
        }
        set(newValue) {
            if newValue {
                defaults.removeObject(forKey: "notifyBoosts")
            } else {
                defaults.set("OFF", forKey: "notifyBoosts")
            }
        }
    }
    
    // フォロー通知を有効にするかどうか
    static var notifyFollows: Bool {
        get {
            if let string = defaults.string(forKey: "notifyFollows") {
                let value = (string == "ON")
                return value
            }
            return true
        }
        set(newValue) {
            if newValue {
                defaults.removeObject(forKey: "notifyFollows")
            } else {
                defaults.set("OFF", forKey: "notifyFollows")
            }
        }
    }
    
    // 画像ファイルのストレージキャッシュを使うかどうか (ただし、APNGと動画は常にキャッシュする)
    static var useStorageCache: Bool {
        get {
            if let string = defaults.string(forKey: "useStorageCache") {
                let value = (string == "ON")
                return value
            }
            return false
        }
        set(newValue) {
            if newValue {
                defaults.set("ON", forKey: "useStorageCache")
            } else {
                defaults.removeObject(forKey: "useStorageCache")
            }
        }
    }
    
    // 画像ファイルのRAMキャッシュの数
    static var ramCacheCount: Int {
        get {
            let value = defaults.integer(forKey: "ramCacheCount")
            if value > 0 {
                return value
            }
            return 200
        }
        set(newValue) {
            if newValue > 0 {
                defaults.set(newValue, forKey: "ramCacheCount")
            } else {
                defaults.removeObject(forKey: "ramCacheCount")
            }
        }
    }
    
    // プレビュー画像の高さ
    static var previewHeight: CGFloat {
        get {
            let value = defaults.integer(forKey: "previewHeight")
            if value > 0 {
                return CGFloat(value)
            }
            return 90
        }
        set(newValue) {
            let intValue = Int(newValue)
            if intValue > 0 && intValue != 90 {
                defaults.set(intValue, forKey: "previewHeight")
            } else {
                defaults.removeObject(forKey: "previewHeight")
            }
        }
    }
    
    // 最近使った絵文字に追加
    static func addRecentEmoji(key: String, accessToken: String) {
        var list = recentEmojiList(accessToken: accessToken)
        if list.count > 0 && list[0] == key { return }
        if let index = list.firstIndex(of: key) {
            list.remove(at: index)
        }
        list.insert(key, at: 0)
        
        // 16を超えたら削除
        if list.count > 16 {
            list.remove(at: 16)
        }
        
        let str = list.joined(separator: "\n")
        
        defaults.set(str, forKey: "recentEmojiList_" + (accessToken))
    }
    
    // 最近使った絵文字を取得
    static func recentEmojiList(accessToken: String) -> [String] {
        let str = defaults.string(forKey: "recentEmojiList_" + (accessToken))
        
        let tmpArray = (str ?? "").split(separator: "\n")
        var array: [String] = []
        for substr in tmpArray {
            array.append(String(substr))
        }
        
        return array
    }
    
    // 最近使ったハッシュタグに追加
    static func addRecentHashtag(key: String, accessToken: String) {
        var list = recentHashtagList(accessToken: accessToken)
        if list.count > 0 && list[0] == key { return }
        if let index = list.firstIndex(of: key) {
            list.remove(at: index)
        }
        list.insert(key, at: 0)
        
        if list.count > 24 {
            list.remove(at: 24)
        }
        
        let str = list.joined(separator: "\n")
        
        defaults.set(str, forKey: "recentHashtagList_" + (accessToken))
    }
    
    // 最近使ったハッシュタグを取得
    static func recentHashtagList(accessToken: String) -> [String] {
        let str = defaults.string(forKey: "recentHashtagList_" + (accessToken))
        
        let tmpArray = (str ?? "").split(separator: "\n")
        var array: [String] = []
        for substr in tmpArray {
            array.append(String(substr))
        }
        
        return array
    }
    
    // 最近メンションしたアカウントに追加
    static func addRecentMention(key: String, accessToken: String) {
        var list = recentMentionList(accessToken: accessToken)
        if list.count > 0 && list[0] == key { return }
        if let index = list.firstIndex(of: key) {
            list.remove(at: index)
        }
        list.insert(key, at: 0)
        
        if list.count > 16 {
            list.remove(at: 16)
        }
        
        let str = list.joined(separator: "\n")
        
        defaults.set(str, forKey: "recentMentionList_" + (accessToken))
    }
    
    // 最近メンションしたアカウントを取得
    static func recentMentionList(accessToken: String) -> [String] {
        let str = defaults.string(forKey: "recentMentionList_" + (accessToken))
        
        let tmpArray = (str ?? "").split(separator: "\n")
        var array: [String] = []
        for substr in tmpArray {
            array.append(String(substr))
        }
        
        return array
    }
    
    // フォロー、フォロワーの情報をたまにチェックする
    static func checkFFAccounts(hostName: String, accessToken: String) {
        // 1週間以内にチェックしていたら、何もしない
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
            
            if let lastDateStr = defaults.string(forKey: "checkFFDate_\(accessToken)") {
                if let date = dateFormatter.date(from: lastDateStr), date.timeIntervalSinceNow >= -7 * 86400 {
                    return
                }
            }
            
            defaults.set(dateFormatter.string(from: Date()), forKey: "checkFFDate_\(accessToken)")
        }
        
        // フォローイングの情報をチェック
        checkFollowing(hostName: hostName, accessToken: accessToken, sinceId: nil)
    }
    
    // フォローイングの情報をチェック
    private static func checkFollowing(hostName: String, accessToken: String, sinceId: String?) {
        var sinceIdStr = ""
        if let sinceId = sinceId {
            sinceIdStr = "?since_id=\(sinceId)"
        }
        
        guard let url = URL(string: "https://\(hostName)/api/v1/accounts/\(SettingsData.accountNumberID(accessToken: accessToken) ?? "")/following" + sinceIdStr) else { return }
        
        try? MastodonRequest.get(url: url, accessToken: accessToken) { (data, response, error) in
            guard let data = data else { return }
            
            do {
                guard let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Array<AnyObject> else { return }
                
                DispatchQueue.global().async {
                    var lastId: Int? = nil
                    
                    for json in responseJson {
                        if let accountJson = json as? [String: Any] {
                            let accountData = AnalyzeJson.analyzeAccountJson(account: accountJson)
                            SettingsData.addFollowingList(accessToken: accessToken, id: accountData.acct)
                            
                            if let numId = Int(accountData.id ?? "") {
                                if let lastNumId = lastId {
                                    if numId > lastNumId {
                                        lastId = numId
                                    }
                                } else {
                                    lastId = numId
                                }
                            }
                        }
                    }
                    
                    if let lastId = lastId {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            checkFollowing(hostName: hostName, accessToken: accessToken, sinceId: "\(lastId)")
                        }
                    }
                }
                
            } catch { }
        }
    }
    
    // フォロー中リストデータに追加
    private static let followingDefaults = UserDefaults(suiteName: "StarPteranoMac_FollowingList")!
    static func addFollowingList(accessToken: String, id: String?) {
        guard let id = id else { return }
        
        var list = followingList(accessToken: accessToken)
        if list.count > 0 && list[0] == id { return }
        if let index = list.firstIndex(of: id) {
            list.remove(at: index)
        }
        list.insert(id, at: 0)
        
        let str = list.joined(separator: "\n")
        
        followingDefaults.set(str, forKey: "followingList_\(accessToken)")
    }
    
    // フォロー中リストデータを取得
    static func followingList(accessToken: String) -> [String] {
        let str = followingDefaults.string(forKey: "followingList_" + (accessToken))
        
        let tmpArray = (str ?? "").split(separator: "\n")
        var array: [String] = []
        for substr in tmpArray {
            array.append(String(substr))
        }
        
        return array
    }
}
