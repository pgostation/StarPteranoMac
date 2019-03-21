//
//  FooterViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/15.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class FooterViewController: NSViewController, NSSearchFieldDelegate {
    let hostName: String
    let accessToken: String
    
    init(hostName: String, accessToken: String) {
        self.hostName = hostName
        self.accessToken = accessToken
        
        super.init(nibName: nil, bundle: nil)
        
        let view = FooterView(hostName: hostName, accessToken: accessToken)
        self.view = view
        
        view.searchField.delegate = self
        
        view.refreshButton.target = self
        view.refreshButton.action = #selector(refreshAction)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // ストリーミングランプを更新
    func setLamp(isOn: Bool?, isConnecting: Bool) {
        if let streamingLampView = (view as? FooterView)?.streamingLampView {
            if isOn == true {
                streamingLampView.layer?.backgroundColor = NSColor.green.cgColor
                streamingLampView.toolTip = I18n.get("TOOLTIP_LAMP_STREAMING")
            } else if isConnecting {
                streamingLampView.layer?.backgroundColor = NSColor.yellow.cgColor
                streamingLampView.toolTip = I18n.get("TOOLTIP_LAMP_CONNECTING")
            } else if isOn == false {
                streamingLampView.layer?.backgroundColor = NSColor.red.cgColor
                streamingLampView.toolTip = I18n.get("TOOLTIP_LAMP_DISCONNECTED")
            } else {
                streamingLampView.layer?.backgroundColor = NSColor.clear.cgColor
            }
        }
        
        // 検索フィールドの表示/非表示
        DispatchQueue.main.async {
            if let subVC = self.parent as? SubViewController {
                if subVC.scrollView.documentView is TimeLineView && !(subVC.scrollView.documentView is NotificationTableView) {
                    (self.view as? FooterView)?.searchField.isHidden = false
                } else {
                    (self.view as? FooterView)?.searchField.isHidden = true
                }
            }
        }
        
        (view as? FooterView)?.refresh()
        
        
        if let subVC = self.parent as? SubViewController {
            if let tlView = subVC.scrollView.documentView as? TimeLineView {
                switch tlView.type {
                case .notifications, .notificationMentions, .search:
                    (view as? FooterView)?.refreshButton.isHidden = true
                default:
                    break
                }
            }
        }
    }
    
    // 残りAPIの表示
    func showRemain(remain: Int, maxCount: Int) {
        DispatchQueue.main.async {
            (self.view as? FooterView)?.remainApiLabel.stringValue = "\(remain) / \(maxCount)"
        }
    }
    
    // タイムラインを更新
    @objc func refreshAction() {
        if let subVC = self.parent as? SubViewController {
            if let tlView = subVC.scrollView.documentView as? TimeLineView {
                tlView.refresh()
            }
        }
    }
    
    // 検索開始
    func searchFieldDidStartSearching(_ sender: NSSearchField) {
        ((self.parent as? SubViewController)?.scrollView.documentView as? TimeLineView)?.search(string: sender.stringValue)
    }
    
    // 検索終了
    func searchFieldDidEndSearching(_ sender: NSSearchField) {
        ((self.parent as? SubViewController)?.scrollView.documentView as? TimeLineView)?.search(string: nil)
    }
}

final class FooterView: NSView {
    let hostName: String
    let accessToken: String
    
    let refreshButton = NSButton()
    let streamingLampView = NSView()
    let remainApiLabel = MyTextField()
    let searchField = NSSearchField()
    
    init(hostName: String, accessToken: String) {
        self.hostName = hostName
        self.accessToken = accessToken
        
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 20))
        
        self.addSubview(refreshButton)
        self.addSubview(streamingLampView)
        self.addSubview(remainApiLabel)
        self.addSubview(searchField)
        
        setProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // プロパティ設定
    private func setProperties() {
        streamingLampView.wantsLayer = true
        streamingLampView.layer?.backgroundColor = NSColor.clear.cgColor
        streamingLampView.layer?.cornerRadius = 6
        
        refreshButton.title = "↺"
        refreshButton.isBordered = false
        
        remainApiLabel.font = NSFont.systemFont(ofSize: SettingsData.fontSize - 2)
        remainApiLabel.textColor = NSColor.gray
        remainApiLabel.isBordered = false
        remainApiLabel.isSelectable = false
        remainApiLabel.isEditable = false
        remainApiLabel.drawsBackground = false
        remainApiLabel.toolTip = I18n.get("TOOLTIP_API_REMAIN")
        
        searchField.recentsAutosaveName = accessToken
        searchField.placeholderString = I18n.get("PLACEHOLDER_SEARCH")
        searchField.refusesFirstResponder = true
        
        self.refresh()
    }
    
    // 更新
    func refresh() {
        self.layer?.backgroundColor = ThemeColor.viewBgColor.cgColor
        
        if SettingsData.isStreamingMode && streamingLampView.layer?.backgroundColor != NSColor.clear.cgColor {
            streamingLampView.isHidden = false
            refreshButton.isHidden = true
        } else {
            streamingLampView.isHidden = true
            refreshButton.isHidden = false
        }
        
        streamingLampView.layer?.borderColor = ThemeColor.contrastColor.withAlphaComponent(0.5).cgColor
        streamingLampView.layer?.borderWidth = 2
    }
    
    // レイアウト
    override func layout() {
        guard let superview = self.superview else { return }
        
        self.frame.size.width = superview.frame.width
        
        streamingLampView.frame = NSRect(x: 4,
                                         y: 4,
                                         width: 12,
                                         height: 12)
        
        refreshButton.frame = NSRect(x: 2,
                                     y: 2,
                                     width: 16,
                                     height: 16)
        
        remainApiLabel.frame = NSRect(x: 30,
                                      y: 0,
                                      width: 100,
                                      height: 20)
        
        let fieldWidth = min(self.frame.size.width - 25, 150)
        searchField.frame = NSRect(x: superview.frame.width - fieldWidth - 5,
                                   y: 0,
                                   width: fieldWidth,
                                   height: 20)
    }
}
