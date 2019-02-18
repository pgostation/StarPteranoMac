//
//  TimeLineViewCell.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa
import APNGKit
import AVFoundation
import AVKit

final class TimeLineViewCell: NSView {
    static var showMoreList: [String] = []
    
    var id = "" // トゥートのID
    var reblog_id: String? = nil
    
    // 基本ビュー
    let lineLayer = CALayer()
    var iconView: NSImageView?
    let nameLabel = MyTextField()
    let idLabel = MyTextField()
    let dateLabel = MyTextField()
    var messageView: NSView?
    
    //追加ビュー
    var continueView: NSTextField? // 長すぎるトゥートで、続きがあることを表示
    var boostView: NSTextField? // 誰がboostしたかを表示
    var imageViews: [NSImageView] = [] // 添付画像を表示
    var imageParentViews: [NSView] = []
    var movieLayers: [AVPlayerLayer] = []
    var looper: Any? //AVPlayerLooper?
    var showMoreButton: NSButton? // もっと見る
    var spolerTextLabel: NSTextView?
    var detailDateLabel: NSTextField?
    var DMBarLeft: NSView?
    var DMBarRight: NSView?
    var cardView: CardView?
    
    // 詳細ビュー
    var showDetail = false
    var replyButton: NSButton?
    var repliedLabel: NSTextField?
    var boostButton: NSButton?
    var boostedLabel: NSTextField?
    var favoriteButton: NSButton?
    var favoritedLabel: NSTextField?
    var detailButton: NSPopUpButton?
    var applicationLabel: NSTextField?
    
    // お気に入りした人やブーストした人の名前表示
    var rebologerLabels: [NSTextField] = []
    var rebologerList: [String]?
    var favoriterLabels: [NSTextField] = []
    var favoriterList: [String]?
    
    weak var tableView: TimeLineView?
    var indexPath: Int?
    var date: Date
    var timer: Timer?
    var accountId: String?
    var accountData: AnalyzeJson.AccountData?
    var contentData: String = ""
    var urlStr: String = ""
    var mentionsList: [AnalyzeJson.MentionData]?
    var isMiniView = SettingsData.MiniView.normal
    var imageUrls: [String] = []
    var originalUrls: [String] = []
    var imageTypes: [String] = []
    var previewUrls: [String] = []
    var visibility: String?
    
    var isFaved = false
    var isBoosted = false
    
    // セルの初期化
    init() {
        self.date = Date()
        
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        
        self.wantsLayer = true
        
        // 固定プロパティは初期化時に設定
        //self.clipsToBounds = true
        self.layer?.backgroundColor = ThemeColor.cellBgColor.cgColor
        //self.isOpaque = true
        //self.selectionStyle = .none
        
        self.nameLabel.textColor = ThemeColor.nameColor
        self.nameLabel.font = NSFont.boldSystemFont(ofSize: SettingsData.fontSize)
        self.nameLabel.backgroundColor = ThemeColor.cellBgColor
        self.nameLabel.isBordered = false
        self.nameLabel.isEditable = false
        //self.nameLabel.isOpaque = true
        
        self.idLabel.textColor = ThemeColor.idColor
        self.idLabel.font = NSFont.systemFont(ofSize: SettingsData.fontSize - 2)
        self.idLabel.backgroundColor = ThemeColor.cellBgColor
        self.idLabel.isBordered = false
        self.idLabel.isEditable = false
        //self.idLabel.isOpaque = true
        
        self.dateLabel.textColor = ThemeColor.dateColor
        self.dateLabel.font = NSFont.systemFont(ofSize: SettingsData.fontSize - 2)
        self.dateLabel.alignment = .right
        self.dateLabel.backgroundColor = ThemeColor.cellBgColor
        //self.dateLabel.adjustsFontSizeToFitWidth = true
        //self.dateLabel.isOpaque = true
        self.dateLabel.isBordered = false
        self.dateLabel.isEditable = false
        
        self.lineLayer.backgroundColor = ThemeColor.separatorColor.cgColor
        self.lineLayer.isOpaque = true
        
        // addする
        self.addSubview(self.idLabel)
        self.addSubview(self.dateLabel)
        self.addSubview(self.nameLabel)
        self.layer?.addSublayer(self.lineLayer)
        
        if SettingsData.isNameTappable {
            // アカウント名のタップジェスチャー
            //let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAccountAction))
            //self.nameLabel.addGestureRecognizer(tapGesture)
            //self.nameLabel.isUserInteractionEnabled = true
        }
        
        LeakCounter.add("TimeLineViewCell")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        LeakCounter.sub("TimeLineViewCell")
    }
    
    // 再利用前に呼ばれる
    override func prepareForReuse() {
        self.id = ""
        self.tableView = nil
        self.showDetail = false
        while let apngView = self.messageView?.viewWithTag(5555) as? APNGImageView {
            apngView.stopAnimating()
            apngView.removeFromSuperview()
        }
        self.messageView?.removeFromSuperview()
        self.messageView = nil
        self.continueView?.removeFromSuperview()
        self.continueView = nil
        self.boostView?.removeFromSuperview()
        self.boostView = nil
        self.showMoreButton?.removeFromSuperview()
        self.showMoreButton = nil
        self.spolerTextLabel?.removeFromSuperview()
        self.spolerTextLabel = nil
        self.detailDateLabel?.removeFromSuperview()
        self.detailDateLabel = nil
        self.DMBarLeft?.removeFromSuperview()
        self.DMBarLeft = nil
        self.DMBarRight?.removeFromSuperview()
        self.DMBarRight = nil
        for label in self.rebologerLabels {
            label.removeFromSuperview()
        }
        self.rebologerLabels = []
        self.rebologerList = nil
        for label in self.favoriterLabels {
            label.removeFromSuperview()
        }
        self.favoriterLabels = []
        self.favoriterList = nil
        for imageView in self.imageViews {
            imageView.removeFromSuperview()
        }
        self.imageViews = []
        for imageParentView in self.imageParentViews {
            imageParentView.removeFromSuperview()
        }
        self.imageParentViews = []
        for playerLayer in self.movieLayers {
            playerLayer.player?.pause()
            playerLayer.removeFromSuperlayer()
        }
        self.movieLayers = []
        self.looper = nil
        if self.replyButton != nil {
            self.replyButton?.removeFromSuperview()
            self.repliedLabel?.removeFromSuperview()
            self.boostButton?.removeFromSuperview()
            self.boostedLabel?.removeFromSuperview()
            self.favoriteButton?.removeFromSuperview()
            self.favoritedLabel?.removeFromSuperview()
            self.detailButton?.removeFromSuperview()
            self.applicationLabel?.removeFromSuperview()
        }
        self.iconView?.removeFromSuperview()
        self.iconView?.image = nil
        for gesture in self.iconView?.gestureRecognizers ?? [] {
            self.iconView?.removeGestureRecognizer(gesture)
        }
        self.iconView = nil
        
        self.cardView?.removeFromSuperview()
        self.cardView = nil
        
        // フォントサイズと色を指定
        self.nameLabel.textColor = ThemeColor.nameColor
        self.nameLabel.font = NSFont.boldSystemFont(ofSize: SettingsData.fontSize)
        
        self.idLabel.textColor = ThemeColor.idColor
        self.idLabel.font = NSFont.systemFont(ofSize: SettingsData.fontSize - 2)
        
        self.dateLabel.textColor = ThemeColor.dateColor
        self.dateLabel.font = NSFont.systemFont(ofSize: SettingsData.fontSize - 2)
        
        self.lineLayer.backgroundColor = ThemeColor.separatorColor.cgColor
    }
    
    // アイコンをタップした時の処理
    private static var doubleTapFlag = false
    @objc func tapAccountAction() {
        if TimeLineViewCell.doubleTapFlag { return }
        TimeLineViewCell.doubleTapFlag = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            TimeLineViewCell.doubleTapFlag = false
        }
        
        if let accountId = self.accountId {
            if let timelineView = self.superview as? TimeLineView {
                if timelineView.option == accountId {
                    return
                }
            }
            
            let accountTimeLineViewController = TimeLineViewController(hostName: tableView?.hostName ?? "", accessToken: tableView?.accessToken ?? "", type: TimeLineViewController.TimeLineType.user, option: accountId)
            if let timelineView = accountTimeLineViewController.view as? TimeLineView, let accountData = self.accountData {
                timelineView.accountList.updateValue(accountData, forKey: accountId)
            }
            tableView?.vc?.addChild(accountTimeLineViewController)
            tableView?.addSubview(accountTimeLineViewController.view)
            accountTimeLineViewController.view.frame = CGRect(x: self.frame.width,
                                                              y: 0,
                                                              width: self.frame.width,
                                                              height: tableView?.frame.height ?? 0)
            
            let animation = NSViewAnimation(duration: 0.3, animationCurve: NSAnimation.Curve.easeIn)
            let frame = accountTimeLineViewController.view.frame
            let animationDict: [NSViewAnimation.Key: Any] = [
                NSViewAnimation.Key.target: self,
                NSViewAnimation.Key.startFrame: frame,
                NSViewAnimation.Key.endFrame: NSRect(x: 0, y: frame.minY, width: frame.width, height: frame.height)]
            animation.viewAnimations = [animationDict]
            animation.start()
        }
    }
    
    // アイコンを長押しした時の処理
    @objc func pressAccountAction(_ gesture: NSGestureRecognizer?) {
        if let gesture = gesture, gesture.state != .began { return }
        
        // @IDを入力する
        DispatchQueue.main.async {
            if let vc = TootViewController.get(accessToken: self.tableView?.accessToken), let view = vc.view as? TootView {
                let text = view.textField.string
                if text.count > 0 {
                    let spaceString = text.last == " " ? "" : " "
                    view.textField.string = text + spaceString + "@\(self.idLabel.stringValue) "
                } else {
                    view.textField.string = "@\(self.idLabel.stringValue) "
                }
            }
        }
    }
    
    // リプライボタンをタップした時の処理
    @objc func replyAction() {
        if let vc = TootViewController.get(accessToken: tableView?.accessToken), let view = vc.view as? TootView, view.textField.string.count > 0 {
            Dialog.show(message: I18n.get("ALERT_TEXT_EXISTS"))
        } else {
            // 返信先を設定
            TootView.inReplyToId = self.id
            
            // 公開範囲を低い方に合わせる
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // 公開範囲設定を変更
                if let visibility = self.visibility {
                    guard let view = TootViewController.get(accessToken: self.tableView?.accessToken)?.view as? TootView else { return }
                    
                    var mode = self.lowerVisibility(m1: SettingsData.ProtectMode(rawValue: visibility),
                                                    m2: SettingsData.protectMode)
                    if mode == SettingsData.ProtectMode.publicMode {
                        mode = SettingsData.ProtectMode.unlisted // inreplytoではLTLに流さない
                    }
                    view.protectMode = mode
                    view.refresh()
                }
            }
            
            // @IDを入力する
            DispatchQueue.main.async {
                if let vc = TootViewController.get(accessToken: self.tableView?.accessToken), let view = vc.view as? TootView {
                    view.textField.string = "@\(self.idLabel.stringValue) "
                }
            }
        }
    }
    
    // 低い方の公開範囲を返す
    private func lowerVisibility(m1: SettingsData.ProtectMode?, m2: SettingsData.ProtectMode) -> SettingsData.ProtectMode {
        guard let m1 = m1 else { return m2 }
        
        let v1: Int
        switch m1 {
        case .direct:
            v1 = 0
        case .privateMode:
            v1 = 1
        case .unlisted:
            v1 = 2
        case .publicMode:
            v1 = 3
        }
        
        let v2: Int
        switch m2 {
        case .direct:
            v2 = 0
        case .privateMode:
            v2 = 1
        case .unlisted:
            v2 = 2
        case .publicMode:
            v2 = 3
        }
        
        let v = min(v1, v2)
        
        switch v {
        case 0:
            return .direct
        case 1:
            return .privateMode
        case 2:
            return .unlisted
        case 3:
            return .publicMode
        default:
            return .publicMode
        }
    }
    
    // ブーストボタンをタップした時の処理
    @objc func boostAction() {
        self.boostButton?.isHidden = true
        
        tableView?.boostAction(id: self.reblog_id ?? self.id, isBoosted: self.isBoosted)
    }
    
    // お気に入りボタンをタップした時の処理
    @objc func favoriteAction() {
        self.favoriteButton?.isHidden = true
        
        tableView?.favoriteAction(id: self.reblog_id ?? self.id, isFaved: self.isFaved)
    }
    
    // 「・・・」ボタンをタップした時の処理
    @objc func setDetailButton(_ popUp: NSPopUpButton) {
        let menu = NSMenu()
        popUp.menu = menu
        
        // 選択解除
        let deselectItem = NSMenuItem(title: I18n.get("ACTION_DESELECT"),
                                      action: #selector(deselectAction),
                                      keyEquivalent: "")
        deselectItem.target = self
        menu.addItem(deselectItem)
        
        if self.accountId == SettingsData.accountNumberID(accessToken: tableView?.accessToken ?? "") {
            // トゥートを削除
            let deleteItem = NSMenuItem(title: I18n.get("ACTION_DELETE_TOOT"),
                                          action: #selector(deleteAction),
                                          keyEquivalent: "")
            deleteItem.target = self
            menu.addItem(deleteItem)
        }
        
        // 通報する
        let reportItem = NSMenuItem(title: I18n.get("ACTION_REPORT_TOOT"),
                                      action: #selector(reportAction),
                                      keyEquivalent: "")
        reportItem.target = self
        menu.addItem(reportItem)
        
        // ペーストボードにコピー
        let copyItem = NSMenuItem(title: I18n.get("ACTION_COPY_TOOT"),
                                    action: #selector(copyAction),
                                    keyEquivalent: "")
        copyItem.target = self
        menu.addItem(copyItem)
        
        // ブラウザで開く
        let browserItem = NSMenuItem(title: I18n.get("ACTION_OPEN_WITH_BROWSER"),
                                  action: #selector(browserAction),
                                  keyEquivalent: "")
        browserItem.target = self
        menu.addItem(browserItem)
        
        /*
         // 生データを表示
         alertController.addAction(UIAlertAction(
         title: "生データを表示",
         style: UIAlertActionStyle.default,
         handler: { _ in
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
         Dialog.show(message: self.contentData)
         }
         }))*/
    }
    
    // 選択解除
    @objc func deselectAction() {
        self.tableView?.model.clearSelection()
        self.tableView?.reloadData()
    }
    
    // トゥートを削除
    @objc func deleteAction() {
        guard let url = URL(string: "https://\(tableView?.hostName ?? "")/api/v1/statuses/\(self.id)") else { return }
        try? MastodonRequest.delete(url: url, accessToken: tableView?.accessToken ?? "", completionHandler: { (data, response, error) in
            if let error = error {
                Dialog.show(message: I18n.get("ALERT_DELETE_TOOT_FAILURE") + "\n " + error.localizedDescription)
            }
        })
    }
    
    @objc func reportAction() {
        /*
        Dialog.showWithTextInput(
            message: I18n.get("ALERT_INPUT_REPORT_REASON"),
            okName: I18n.get("BUTTON_REPORT"),
            cancelName: I18n.get("BUTTON_CANCEL"),
            defaultText: nil,
            callback: { textField, result in
                if !result { return }
                
                if textField.stringValue == nil || textField.text!.count == 0 {
                    Dialog.show(message: I18n.get("ALERT_REASON_IS_NIL"))
                    return
                }
                
                guard let hostName = SettingsData.hostName else { return }
                
                let url = URL(string: "https://\(hostName)/api/v1/reports")!
                
                let bodyDict = ["account_id": accountId,
                                "status_ids": id,
                                "comment": textField.text!]
                
                try? MastodonRequest.post(url: url, body: bodyDict) { (data, response, error) in
                    if let error = error {
                        Dialog.show(message: I18n.get("ALERT_REPORT_TOOT_FAILURE") + "\n" + error.localizedDescription)
                    } else {
                        if let response = response as? HTTPURLResponse {
                            if response.statusCode == 200 {
                                //
                            } else {
                                Dialog.show(message: I18n.get("ALERT_REPORT_TOOT_FAILURE") + "\nHTTP status \(response.statusCode)")
                            }
                        }
                    }
                }
        }) */
    }
    
    @objc func copyAction() {
        let spoilerText: String
        if let attrtext = self.spolerTextLabel?.attributedString() {
            spoilerText = DecodeToot.encodeEmoji(attributedText: attrtext, textStorage: NSTextStorage(attributedString: attrtext))
        } else {
            spoilerText = ""
        }
        
        let text: String
        if let label = self.messageView as? NSTextField {
            let attrtext = label.attributedStringValue
            text = DecodeToot.encodeEmoji(attributedText: attrtext, textStorage: NSTextStorage(attributedString: attrtext))
        } else if let textView = self.messageView as? NSTextView, let attrtext = textView.textStorage?.attributedSubstring(from: NSMakeRange(0, textView.textStorage?.length ?? 0)) {
            text = DecodeToot.encodeEmoji(attributedText: attrtext, textStorage: textView.textStorage!)
        } else {
            text = ""
        }
        
        let finalText: String
        if spoilerText != "" && text != "" {
            finalText = spoilerText + "\n" + text
        } else if spoilerText != "" {
            finalText = spoilerText
        } else {
            finalText = text
        }
        
        NSPasteboard.general.setString(finalText, forType: NSPasteboard.PasteboardType.string)
    }
    
    @objc func browserAction() {
        guard let url = URL(string: self.urlStr) else { return }
        NSWorkspace.shared.open(url)
    }
    
    // もっと見る
    @objc func showMoreAction(forceShow: Bool = true) {
        if !forceShow && TimeLineViewCell.showMoreList.contains(self.id) {
            // やっぱり隠す
            for (index, data) in TimeLineViewCell.showMoreList.enumerated() {
                if data == self.id {
                    TimeLineViewCell.showMoreList.remove(at: index)
                    break
                }
            }
            if self.spolerTextLabel?.textStorage?.string != "" {
                self.messageView?.isHidden = true
            }
            for imageView in self.imageViews {
                imageView.isHidden = true
            }
            self.showMoreButton?.title = I18n.get("BUTTON_SHOW_MORE")
            return
        }
        
        self.messageView?.isHidden = false
        for imageView in self.imageViews {
            imageView.isHidden = false
        }
        
        self.showMoreButton?.title = I18n.get("BUTTON_HIDE_REDO")
        
        if !TimeLineViewCell.showMoreList.contains(self.id) && self.id != "" {
            TimeLineViewCell.showMoreList.append(self.id)
        }
    }
    
    // 画像をタップ
    @objc func imageTapAction(_ sender: NSView) {
        for (index, imageView) in self.imageViews.enumerated() {
            if imageView == sender.superview?.subviews.first {
                if imageTypes[index] == "unknown" {
                    // 分からんので内蔵ブラウザで開く
                    guard let url = URL(string: originalUrls[index]) else { return }
                    NSWorkspace.shared.open(url)
                } else if imageTypes[index] == "video" || imageTypes[index] == "gifv" {
                    // 動画
                    MovieCache.movie(urlStr: imageUrls[index]) { [weak self] player, queuePlayer, looper in
                        DispatchQueue.main.async {
                            //waitIndicator.removeFromSuperview()
                            
                            if let player = player {
                                let viewController = MyPlayerViewController()
                                viewController.player = player
                                ImageWindow(contentViewController: viewController).show()
                                player.play()
                            } else {
                                if #available(OSX 10.12, *) {
                                    if let queuePlayer = queuePlayer as? AVQueuePlayer, let looper = looper as? AVPlayerLooper {
                                        let viewController = MyPlayerViewController()
                                        viewController.player = queuePlayer
                                        self?.looper = looper
                                        ImageWindow(contentViewController: viewController).show()
                                        queuePlayer.play()
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // 静止画
                    let vc = ImageViewController(imagesUrls: self.imageUrls, previewUrls: self.previewUrls, index: index, smallImage: imageView.image)
                    ImageWindow(contentViewController: vc).show()
                }
            }
        }
    }
    
    // 日時表示を更新
    func refreshDate() {
        let diffTime = Int(Date().timeIntervalSince(self.date))
        if diffTime <= 0 {
            self.dateLabel.stringValue = I18n.get("DATETIME_NOW")
        }
        else if diffTime < 60 {
            self.dateLabel.stringValue = String(format: I18n.get("DATETIME_%D_SECS_AGO"), diffTime)
        }
        else if diffTime / 60 < 60 {
            self.dateLabel.stringValue = String(format: I18n.get("DATETIME_%D_MINS_AGO"), diffTime / 60)
        }
        else if diffTime / 3600 < 24 {
            if diffTime / 3600 < 10 && diffTime % 3600 >= 1800 {
                self.dateLabel.stringValue = String(format: I18n.get("DATETIME_%D_HOURS_HALF_AGO"), diffTime / 3600)
            } else {
                self.dateLabel.stringValue = String(format: I18n.get("DATETIME_%D_HOURS_AGO"), diffTime / 3600)
            }
        }
        else if diffTime / 86400 < 365 {
            self.dateLabel.stringValue = String(format: I18n.get("DATETIME_%D_DAYS_AGO"), diffTime / 86400)
        }
        else {
            self.dateLabel.stringValue = String(format: I18n.get("DATETIME_%D_YEARS_AGO"), diffTime / 86400 / 365)
        }
        
        // タイマーでN秒ごとに時刻を更新
        let interval: TimeInterval
        if Date().timeIntervalSince(self.date) < 60 {
            interval = 5
        } else if Date().timeIntervalSince(self.date) < 600 {
            interval = 15
        } else {
            interval = 60
        }
        
        self.timer?.invalidate()
        if #available(OSX 10.12, *) {
            DispatchQueue.main.async { [weak self] in
                self?.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { [weak self] timer in
                    if self?.superview == nil {
                        timer.invalidate()
                        return
                    }
                    
                    self?.refreshDate()
                })
            }
        }
    }
    
    // セル内のレイアウト
    override func layout() {
        if let superview = self.tableView?.superview, self.frame.width != superview.frame.width {
            self.frame.size.width = superview.frame.width
        }
        let screenBounds = self.frame
        let height = screenBounds.height
        let isDetailMode = !SettingsData.tapDetailMode && self.showDetail
        let isMiniView = isDetailMode ? .normal : self.isMiniView
        let iconSize = isMiniView != .normal ? SettingsData.iconSize - 4 : SettingsData.iconSize
        
        if isDetailMode {
            self.nameLabel.isHidden = false
            self.idLabel.isHidden = false
        }
        
        self.lineLayer.frame = CGRect(x: 0,
                                      y: 0,
                                      width: screenBounds.width,
                                      height: 1 / (NSScreen.main?.backingScaleFactor ?? 1))
        
        self.iconView?.frame = CGRect(x: 6,
                                      y: height - (isMiniView == .superMini ? 12 - iconSize / 2 : (isMiniView != .normal ? 6 : 10)) - iconSize,
                                      width: iconSize,
                                      height: iconSize)
        
        let nameLeft = iconSize + 10
        self.nameLabel.frame = CGRect(x: nameLeft,
                                      y: height - (isMiniView != .normal ? 2 : 6) - (SettingsData.fontSize + 6),
                                      width: min(self.nameLabel.frame.width, screenBounds.width - nameLeft - 50),
                                      height: SettingsData.fontSize + 9)
        
        let idWidth: CGFloat
        if self.detailDateLabel != nil {
            idWidth = screenBounds.width - (self.nameLabel.frame.width + nameLeft)
        } else {
            idWidth = screenBounds.width - (self.nameLabel.frame.width + nameLeft + 45 + 5)
        }
        self.idLabel.frame = CGRect(x: nameLeft + self.nameLabel.frame.width + 5,
                                    y: height - (isMiniView != .normal ? 3 : 6) - (SettingsData.fontSize + 2),
                                    width: idWidth,
                                    height: SettingsData.fontSize + 2)
        
        self.dateLabel.frame = CGRect(x: screenBounds.width - 50,
                                      y: height - (isMiniView != .normal ? 3 : 6) - (SettingsData.fontSize + 2),
                                      width: 45,
                                      height: SettingsData.fontSize + 2)
        
        self.detailDateLabel?.frame = CGRect(x: 50,
                                             y: height - 22 - 18,
                                             width: screenBounds.width - 55,
                                             height: 18)
        
        self.spolerTextLabel?.frame = CGRect(x: nameLeft,
                                             y: height - (isMiniView == .superMini ? 2 : self.detailDateLabel?.frame.minY ?? SettingsData.fontSize + 8) - (self.spolerTextLabel?.frame.height ?? 0),
                                             width: self.spolerTextLabel?.frame.width ?? 0,
                                             height: self.spolerTextLabel?.frame.height ?? 0)
        
        if let messageView = self.messageView as? NSTextField {
            let y: CGFloat
            if isMiniView == .superMini {
                y = 0
            } else if let spolerTextLabel = self.spolerTextLabel {
                y = spolerTextLabel.frame.minY + 20
            } else {
                y = self.detailDateLabel?.frame.minY ?? ((isMiniView != .normal ? 1 : 8) + SettingsData.fontSize)
            }
            messageView.frame = CGRect(x: nameLeft,
                                       y: height - y - messageView.frame.height,
                                       width: min(screenBounds.width - SettingsData.iconSize - 10, messageView.frame.width),
                                       height: messageView.frame.height)
        } else if let messageView = self.messageView as? NSTextView {
            let y: CGFloat
            if isMiniView == .superMini {
                y = -0
            } else if let spolerTextLabel = self.spolerTextLabel {
                y = spolerTextLabel.frame.minY + 20
            } else {
                y = self.detailDateLabel?.frame.minY ?? ((isMiniView != .normal ? 4 : 12) + SettingsData.fontSize)
            }
            messageView.frame = CGRect(x: nameLeft,
                                       y: height - y - messageView.frame.height,
                                       width: min(screenBounds.width - SettingsData.iconSize - 10, messageView.frame.width),
                                       height: messageView.frame.height)
        }
        
        self.continueView?.frame = CGRect(x: screenBounds.width / 2 - 40 / 2,
                                          y: ((self.messageView?.frame.minY ?? 0) - 6) - 18,
                                          width: 40,
                                          height: 18)
        
        let imageHeight = isDetailMode ? (self.frame.width - 80 + 10) : 90
        let imagesOffset = CGFloat(self.imageViews.count) * imageHeight
        self.boostView?.frame = CGRect(x: nameLeft - 12,
                                       y: ((self.messageView?.frame.minY ?? height) + 8 - imagesOffset) - 24,
                                       width: screenBounds.width - 56,
                                       height: 24)
        
        if let showMoreButton = self.showMoreButton {
            showMoreButton.frame = CGRect(x: 100,
                                          y: (self.spolerTextLabel?.frame.minY ?? self.messageView?.frame.minY ?? height - 20) - 20,
                                          width: screenBounds.width - 160,
                                          height: 20)
        }
        
        self.DMBarLeft?.frame = CGRect(x: 0, y: 0, width: 5, height: 800)
        
        self.DMBarRight?.frame = CGRect(x: screenBounds.width - 5, y: 0, width: 5, height: 800)
        
        var imageTop: CGFloat = (self.messageView?.frame.minY ?? self.showMoreButton?.frame.minY ?? height - 20) - 10
        for imageParentView in self.imageParentViews {
            guard let imageView = imageParentView.subviews.first as? NSImageView else { continue }
            if isDetailMode, let image = imageView.image {
                let maxSize: CGFloat = min(400, self.frame.width - 80)
                var imageWidth: CGFloat = 0
                var imageHeight: CGFloat = isDetailMode ? maxSize : 80
                let size = image.size
                let rate = imageHeight / max(1, size.height)
                imageWidth = size.width * rate
                if imageWidth > maxSize {
                    imageWidth = maxSize
                    let newRate = imageWidth / max(1, size.width)
                    imageHeight = size.height * newRate
                }
                imageParentView.frame = CGRect(x: nameLeft,
                                               y: (imageTop) - imageHeight,
                                               width: imageWidth,
                                               height: imageHeight)
                imageView.imageScaling = .scaleProportionallyUpOrDown
                imageView.frame = CGRect(x: 0,
                                         y: 0,
                                         width: imageWidth,
                                         height: imageHeight)
                imageTop = (imageTop) - imageHeight - 10
            } else if let image = imageView.image {
                let imageParentWidth: CGFloat = min(300, screenBounds.width - 80)
                let imageParentHeight: CGFloat = 80
                imageParentView.frame = CGRect(x: nameLeft,
                                         y: (imageTop) - imageParentHeight,
                                         width: imageParentWidth,
                                         height: imageParentHeight)
                
                let size = image.size
                let rate1 = imageParentHeight / max(1, size.height)
                let rate2 = imageParentWidth / max(1, size.width)
                var rate = max(rate1, rate2)
                if max(rate * size.width, rate * size.height) > 2000 { // あまりビューのサイズを大きくするとまずかろう
                    rate *= 2000 / max(rate * size.width, rate * size.height)
                }
                imageView.imageScaling = .scaleProportionallyUpOrDown
                imageView.layer?.contentsGravity = CALayerContentsGravity.resizeAspectFill
                imageView.frame = CGRect(x: imageParentWidth / 2 - (rate * size.width) / 2,
                                         y: imageParentHeight / 2 - (rate * size.height) / 2,
                                         width: rate * size.width,
                                         height: rate * size.height)
                imageTop = (imageTop) - imageHeight - 8
            } else {
                let imageWidth: CGFloat = min(300, screenBounds.width - 80)
                let imageHeight: CGFloat = 80
                imageParentView.frame = CGRect(x: nameLeft,
                                               y: (imageTop) - imageHeight,
                                               width: imageWidth,
                                               height: imageHeight)
                imageView.frame = CGRect(x: 0,
                                         y: 0,
                                         width: imageWidth,
                                         height: imageHeight)
                imageTop = (imageTop) - imageHeight - 8
            }
        }
        
        if self.replyButton != nil {
            var top: CGFloat = self.boostView?.frame.minY ?? self.imageViews.last?.frame.minY ?? ((self.messageView?.frame.minY ?? height - 0) + 8 + imagesOffset)
            
            if let cardView = self.cardView, !cardView.isHidden {
                cardView.frame.origin.y = top - 200
                cardView.frame.origin.x = 10
                cardView.frame.size.width =  self.frame.width - 20
                cardView.layout()
                
                top = cardView.frame.minY - 5
            }
            
            self.replyButton?.frame = CGRect(x: 50,
                                             y: (top - 3) - 40,
                                             width: 30,
                                             height: 30)
            
            self.repliedLabel?.frame = CGRect(x: 80,
                                              y: (top - 10) - 30,
                                              width: 20,
                                              height: 20)
            
            self.boostButton?.frame = CGRect(x: 110,
                                             y: (top - 3) - 40,
                                             width: 30,
                                             height: 30)
            
            self.boostedLabel?.frame = CGRect(x: 140,
                                              y: (top - 10) - 30,
                                              width: 20,
                                              height: 20)
            
            self.favoriteButton?.frame = CGRect(x: 170,
                                                y: (top - 3) - 40,
                                                width: 30,
                                                height: 30)
            
            self.favoritedLabel?.frame = CGRect(x: 200,
                                                y: (top - 10) - 30,
                                                width: 20,
                                                height: 20)
            
            self.detailButton?.frame = CGRect(x: 230,
                                              y: top - 50,
                                              width: 80,
                                              height: 40)
            
            if let applicationLabel = self.applicationLabel {
                applicationLabel.frame = CGRect(x: screenBounds.width - applicationLabel.frame.width - 2,
                                                  y: (top - 5) - 20,
                                                  width: applicationLabel.frame.width,
                                                  height: 20)
            }
            
            top -= 48
            for label in self.rebologerLabels {
                label.frame = CGRect(x: 50,
                                     y: top - SettingsData.fontSize,
                                     width: screenBounds.width - 50,
                                     height: SettingsData.fontSize)
                
                top -= SettingsData.fontSize + 4
            }
            
            for label in self.favoriterLabels {
                label.frame = CGRect(x: 50,
                                     y: top - SettingsData.fontSize,
                                     width: screenBounds.width - 50,
                                     height: SettingsData.fontSize)
                
                top -= SettingsData.fontSize + 4
            }
        } else {
            if let cardView = self.cardView {
                let top = self.boostView?.frame.minY ?? self.imageViews.last?.frame.minY ?? ((self.messageView?.frame.minY ?? 0) - 8 + imagesOffset)
                cardView.frame.origin.y = top - 200
                cardView.frame.origin.x = 10
                cardView.frame.size.width =  self.frame.width - 20
                cardView.layout()
            }
        }
    }
}
