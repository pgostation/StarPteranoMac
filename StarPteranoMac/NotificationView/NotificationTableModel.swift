//
//  NotificationTableModel.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/02.
//  Copyright © 2019 pgostation. All rights reserved.
//

// 通知画面に表示する内容

import Cocoa

final class NotificationTableModel: TimeLineViewModel {
    var useAutopagerize = true
    private var list: [AnalyzeJson.NotificationData] = []
    private var filteredList: [AnalyzeJson.NotificationData] = []
    weak var notificationViewController: NotificationViewController?
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func change(addList: [AnalyzeJson.NotificationData]) {
        if list.count == 0 {
            list = addList
        } else {
            list += addList
        }
    }
    
    func getLastId() -> String? {
        return self.list.last?.id
    }
    
    func getNewestCreatedAt() -> String? {
        return self.list.first?.created_at
    }
    
    // セルの数
    override func numberOfRows(in tableView: NSTableView) -> Int {
        let selectedSegmentIndex = (tableView as? NotificationTableView)?.segmentControl.selectedSegment ?? 0
        
        self.filteredList = getFilteredList(list: self.list, selectedSegmentIndex: selectedSegmentIndex)
        
        return self.filteredList.count + 1 // 一番下に余白をつけるため1加える
    }
    
    private func getFilteredList(list: [AnalyzeJson.NotificationData], selectedSegmentIndex: Int) -> [AnalyzeJson.NotificationData] {
        var filteredList: [AnalyzeJson.NotificationData] = []
        
        for data in list {
            switch selectedSegmentIndex {
            case 0:
                filteredList.append(data)
            case 1:
                if data.type == "mention" {
                    filteredList.append(data)
                }
            case 2:
                if data.type == "follow" {
                    filteredList.append(data)
                }
            case 3:
                if data.type == "favourite" {
                    filteredList.append(data)
                }
            case 4:
                if data.type == "reblog" {
                    filteredList.append(data)
                }
            default:
                filteredList.append(data)
            }
        }
        
        return filteredList
    }
    
    // セルの正確な高さ
    private let dummyLabel = NSTextView()
    override func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if row >= filteredList.count {
            if self.useAutopagerize && self.filteredList.count > 0 {
                // Autopagerize
                self.notificationViewController?.addOld()
            }
            
            return 150
        }
        
        let data = filteredList[row]
        if data.type == "follow" {
            return 15 + SettingsData.fontSize * 2
        } else {
            if let status = data.status {
                let attibutedText = DecodeToot.decodeContentFast(content: status.content, emojis: status.emojis) {
                }
                self.dummyLabel.textStorage?.setAttributedString(attibutedText.0)
                self.dummyLabel.font = NSFont.systemFont(ofSize: SettingsData.fontSize - 2)
                self.dummyLabel.frame.size.width = tableView.bounds.width - 55
                self.dummyLabel.sizeToFit()
                
                let height: CGFloat
                if data.type == "mention" {
                    // 返信とお気に入りボタンの分
                    height = self.dummyLabel.frame.height + SettingsData.fontSize * 2 + 20 + 40
                } else {
                    height = self.dummyLabel.frame.height + SettingsData.fontSize * 2 + 20
                }
                
                // 画像がある場合
                if let mediaCount = data.status?.mediaData?.count, mediaCount > 0 {
                    return height + CGFloat(mediaCount) * 65
                }
                
                return height
            }
            return SettingsData.fontSize * 2
        }
    }
    
    // セルの中身を設定して返す
    override func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if row >= filteredList.count {
            let cell = NSView(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
            cell.layer?.backgroundColor = ThemeColor.cellBgColor.cgColor
            return cell
        }
        
        let cell = NotificationTableCell()
        
        let data = filteredList[row]
        let account = data.account
        let id = data.id ?? ""
        
        cell.id = id
        cell.accountId = account?.id
        cell.accountData = account
        cell.statusId = data.status?.id
        cell.visibility = data.status?.visibility
        
        cell.tableView = tableView as? NotificationTableView
        
        ImageCache.image(urlStr: account?.avatar_static, isTemp: false, isSmall: true) { (image, localUrl) in
            if cell.id == id {
                cell.iconView.image = image
            }
        }
        
        cell.nameLabel.attributedStringValue = DecodeToot.decodeName(name: account?.display_name ?? "", emojis: account?.emojis, textField: cell.nameLabel, callback: {
            if cell.id == id {
                cell.nameLabel.attributedStringValue = DecodeToot.decodeName(name: account?.display_name ?? "", emojis: account?.emojis, textField: cell.nameLabel, callback: nil)
                cell.needsLayout = true
            }
        })
        cell.nameLabel.sizeToFit()
        
        cell.idLabel.stringValue = account?.acct ?? ""
        cell.idLabel.sizeToFit()
        
        cell.replyButton.isHidden = true
        cell.favoriteButton.isHidden = true
        switch data.type {
        case "mention":
            cell.notificationLabel.stringValue = I18n.get("NOTIFICATION_MENTION")
            cell.replyButton.isHidden = false
            cell.favoriteButton.isHidden = false
            let attributedTitle = NSMutableAttributedString(string: cell.favoriteButton.title)
            attributedTitle.addAttributes([NSAttributedString.Key.foregroundColor: (data.status?.favourited == 1 ? ThemeColor.detailButtonsHiliteColor : ThemeColor.detailButtonsColor)],
                                          range: NSRange(location: 0, length: attributedTitle.length))
            cell.favoriteButton.attributedTitle = attributedTitle
            cell.isFaved = (data.status?.favourited == 1)
        case "reblog":
            cell.notificationLabel.stringValue = I18n.get("NOTIFICATION_BOOST")
        case "favourite":
            cell.notificationLabel.stringValue = I18n.get("NOTIFICATION_FAV")
        case "follow":
            cell.notificationLabel.stringValue = I18n.get("NOTIFICATION_FOLLOW")
        default:
            cell.notificationLabel.stringValue = ""
        }
        
        if let created_at = data.created_at {
            let date = DecodeToot.decodeTime(text: created_at)
            cell.date = date
            cell.refreshDate()
        }
        
        if let status = data.status {
            let attibutedText = DecodeToot.decodeContentFast(content: status.content, emojis: status.emojis) {
                if cell.id == id {
                    let attibutedText = DecodeToot.decodeContentFast(content: status.content, emojis: status.emojis) {}
                    cell.statusLabel.textStorage?.setAttributedString(attibutedText.0)
                    cell.statusLabel.textColor = ThemeColor.idColor
                }
            }
            cell.statusLabel.textStorage?.setAttributedString(attibutedText.0)
            cell.statusLabel.textColor = ThemeColor.idColor
        }
        
        for imageView in cell.imageViews {
            imageView.image = nil
        }
        // 画像がある場合
        if let mediaCount = data.status?.mediaData?.count, mediaCount > 0 {
            for i in 0..<mediaCount {
                let mediaData = (data.status?.mediaData?[i])!
                ImageCache.image(urlStr: mediaData.preview_url, isTemp: true, isSmall: false) { (image, localUrl) in
                    cell.imageViews[i].image = image
                    cell.imageViews[i].imageScaling = .scaleProportionallyUpOrDown
                    cell.needsLayout = true
                }
            }
        }
        
        return cell
    }
}
