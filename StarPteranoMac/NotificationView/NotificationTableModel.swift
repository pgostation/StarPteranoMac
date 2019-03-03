//
//  NotificationTableModel.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/02.
//  Copyright © 2019 pgostation. All rights reserved.
//

// 通知画面に表示する内容

import Cocoa

final class NotificationTableModel: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    var useAutopagerize = true
    private var list: [AnalyzeJson.NotificationData] = []
    weak var viewController: NotificationViewController?
    
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
            for data in addList {
                for index in 0..<list.count {
                    guard let c1 = list[index].created_at else { continue }
                    guard let c2 = data.created_at else { continue }
                    
                    if c2 >= c1 {
                        if c2 == c1 && data.account?.acct == list[index].account?.acct {
                            // 同じ内容なので追加しない
                            break
                        }
                        
                        // 途中(か最初)に追加
                        list.insert(data, at: index)
                        break
                    }
                    
                    // 最後に追加
                    if index == list.count - 1 {
                        list.append(data)
                    }
                }
            }
        }
    }
    
    func getLastId() -> String? {
        return self.list.last?.id
    }
    
    func getNewestCreatedAt() -> String? {
        return self.list.first?.created_at
    }
    
    // セルの数
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.list.count + 1 // 一番下に余白をつけるため1加える
    }
    
    // セルの正確な高さ
    private let dummyLabel = NSTextView()
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if row >= list.count {
            if self.useAutopagerize && self.list.count > 0 {
                // Autopagerize
                self.viewController?.add()
            }
            
            return 150
        }
        
        let data = list[row]
        if data.type == "follow" {
            return 15 + SettingsData.fontSize * 2
        } else {
            if let status = data.status {
                let attibutedText = DecodeToot.decodeContentFast(content: status.content, emojis: status.emojis) {
                }
                self.dummyLabel.textStorage?.setAttributedString(attibutedText.0)
                self.dummyLabel.font = NSFont.systemFont(ofSize: SettingsData.fontSize - 2)
                self.dummyLabel.frame.size.width = tableView.bounds.width - 65
                self.dummyLabel.sizeToFit()
                
                let height: CGFloat
                if data.type == "mention" {
                    // 返信とお気に入りボタンの分
                    height = self.dummyLabel.frame.height + SettingsData.fontSize * 2 + 20 + 45
                } else {
                    height = self.dummyLabel.frame.height + SettingsData.fontSize * 2 + 20 + 8
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
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if row >= list.count {
            let cell = NSView(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
            cell.layer?.backgroundColor = ThemeColor.cellBgColor.cgColor
            return cell
        }
        
        let cell = NotificationTableCell()
        
        let data = list[row]
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
