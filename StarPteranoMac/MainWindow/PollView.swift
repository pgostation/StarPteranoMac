//
//  PollView.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/13.
//  Copyright © 2019 pgostation. All rights reserved.
//

// 投票の内容や結果表示、あるいはボタンを押して投票もできる

import Cocoa

final class PollView: NSView {
    let hostName: String
    let accessToken: String
    private var labels: [NSTextField] = [] // 項目名
    private var voteGraphs: [NSView] = [] // グラフ
    private var voteCountLabels: [NSTextField] = [] // %と投票数の表示
    private var buttons: [NSButton] = [] // 投票ボタン
    private var doneButton = NSButton() // 完了ボタン
    private let totalLabel = NSTextField() // 総投票数を表示
    private let expiredLabel = NSTextField() // 残り時間/締め切り済みを表示
    private let votedLabel = NSTextField() // 投票済みを表示
    private var data: AnalyzeJson.PollData
    
    init(hostName: String, accessToken: String, data: AnalyzeJson.PollData) {
        self.hostName = hostName
        self.accessToken = accessToken
        self.data = data
        
        super.init(frame: CGRect(x: 10,
                                 y: 0,
                                 width: 300,
                                 height: 50 + CGFloat(data.options.count) * 30))
        
        self.addSubview(totalLabel)
        self.addSubview(expiredLabel)
        self.addSubview(votedLabel)
        if data.multiple && data.voted != true {
            self.addSubview(doneButton)
        }
        
        setProperties()
        
        for graph in voteGraphs {
            self.addSubview(graph)
        }
        for label in labels {
            self.addSubview(label)
        }
        for label in voteCountLabels {
            self.addSubview(label)
        }
        
        for button in buttons {
            self.addSubview(button)
            button.target = self
            button.action = #selector(voteAction(_:))
        }
        doneButton.target = self
        doneButton.action = #selector(doneAction)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // プロパティ設定
    private func setProperties() {
        for option in data.options {
            if let vote = option.1 {
                let view = NSView()
                view.wantsLayer = true
                view.layer?.backgroundColor = ThemeColor.contrastColor.withAlphaComponent(0.3).cgColor
                if data.votes_count > 0 {
                    view.frame.size.width = (self.frame.width - 80) * CGFloat(vote) / CGFloat(data.votes_count)
                }
                voteGraphs.append(view)
                
                let label = NSTextField()
                label.stringValue = "\(vote)"
                label.textColor = ThemeColor.contrastColor
                //label.adjustsFontSizeToFitWidth = true
                label.isEditable = false
                label.isSelectable = false
                label.isBordered = false
                label.drawsBackground = false
                voteCountLabels.append(label)
            }
            
            let label = NSTextField()
            label.stringValue = option.0
            label.textColor = ThemeColor.contrastColor
            //label.adjustsFontSizeToFitWidth = true
            label.isEditable = false
            label.isSelectable = false
            label.isBordered = false
            label.drawsBackground = false
            labels.append(label)
            
            let button = NSButton()
            button.title = "+"
            button.isBordered = false
            button.layer?.backgroundColor = NSColor.blue.cgColor
            //button.clipsToBounds = true
            button.layer?.cornerRadius = 8
            buttons.append(button)
            if data.expired == true || data.voted == true {
                button.alphaValue = 0.3
                button.isEnabled = false
            }
        }
        
        totalLabel.stringValue = I18n.get("VOTE_TOTAL:") + "\(data.votes_count)"
        totalLabel.textColor = ThemeColor.contrastColor
        //totalLabel.adjustsFontSizeToFitWidth = true
        totalLabel.isEditable = false
        totalLabel.isSelectable = false
        totalLabel.isBordered = false
        totalLabel.drawsBackground = false
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
            formatter.locale = enUSPosixLocale
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
            return formatter
        }()
        
        if data.expired {
            expiredLabel.stringValue = I18n.get("POLLS_EXPIRED")
        } else if let expires_at = data.expires_at {
            if let date = dateFormatter.date(from: expires_at) {
                let remain = date.timeIntervalSinceNow
                let str: String
                if remain < 60 {
                    str = String(format: I18n.get("DATETIME_%D_SECS_AGO"), Int(remain))
                } else if remain < 60 * 60 {
                    str = String(format: I18n.get("DATETIME_%D_MINS_AGO"), Int(remain / 60))
                } else if remain < 24 * 60 * 60 {
                    str = String(format: I18n.get("DATETIME_%D_HOURS_AGO"), Int(remain / 60 / 60))
                } else {
                    str = String(format: I18n.get("DATETIME_%D_DAYS_AGO"), Int(remain / 60 / 60 / 24))
                }
                expiredLabel.stringValue = I18n.get("EXPIRES_TIME_FOR:") + str
            } else {
                expiredLabel.stringValue = I18n.get("EXPIRES_TIME:") + "\(expires_at)"
            }
        }
        expiredLabel.textColor = ThemeColor.contrastColor
        //expiredLabel.adjustsFontSizeToFitWidth = true
        expiredLabel.isEditable = false
        expiredLabel.isSelectable = false
        expiredLabel.isBordered = false
        expiredLabel.drawsBackground = false
        
        if let voted = data.voted, voted == true {
            votedLabel.stringValue = I18n.get("VOTED_LABEL")
            votedLabel.textColor = ThemeColor.contrastColor
            //votedLabel.adjustsFontSizeToFitWidth = true
        }
        votedLabel.isEditable = false
        votedLabel.isSelectable = false
        votedLabel.isBordered = false
        votedLabel.drawsBackground = false
        
        doneButton.title = I18n.get("BUTTON_VOTE_DONE")
        doneButton.isEnabled = false
        doneButton.isBordered = false
        doneButton.wantsLayer = true
        doneButton.layer?.backgroundColor = NSColor.gray.cgColor
        doneButton.layer?.cornerRadius = 8
        
        if data.voted == true {
            doneButton.isHidden = true
        }
    }
    
    @objc func voteAction(_ sender: NSButton) {
        if sender.layer?.backgroundColor != ThemeColor.cellBgColor.cgColor {
            sender.layer?.backgroundColor = ThemeColor.cellBgColor.cgColor
        } else {
            sender.layer?.backgroundColor = NSColor.blue.cgColor
            return
        }
        
        if !data.multiple {
            voteRequest()
        } else {
            doneButton.isEnabled = true
        }
    }
    
    @objc func doneAction() {
        voteRequest()
        
        doneButton.isHidden = true
    }
    
    private func voteRequest() {
        let url = URL(string: "https://\(hostName)/api/v1/polls/\(data.id)/votes")!
        
        var choiceArray: [String] = []
        
        for (i, button) in self.buttons.enumerated() {
            if button.layer?.backgroundColor == ThemeColor.cellBgColor.cgColor {
                choiceArray.append(data.options[i].0)
            }
        }
        
        if choiceArray.count == 0 { return }
        
        let body: [String: Any] = ["choices": choiceArray]
        
        try? MastodonRequest.post(url: url, accessToken: accessToken, body: body) { [weak self] (data, response, error) in
            if let data = data {
                do {
                    if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] {
                        if let pollData = AnalyzeJson.getPoll(json: responseJson) {
                            self?.data = pollData
                            
                            DispatchQueue.main.async {
                                self?.setProperties()
                            }
                        }
                    }
                } catch { }
            }
        }
    }
    
    override func layout() {
        var top: CGFloat = 5
        
        totalLabel.frame = CGRect(x: 0,
                                  y: top,
                                  width: 60,
                                  height: 30)
        
        expiredLabel.frame = CGRect(x: 65,
                                    y: top,
                                    width: max(0, self.frame.width - 120),
                                    height: 30)
        
        votedLabel.frame = CGRect(x: self.frame.width - 70,
                                  y: top,
                                  width: 55,
                                  height: 30)
        
        doneButton.frame = CGRect(x: self.frame.width - 100,
                                  y: top,
                                  width: 95,
                                  height: 30)
        
        top += 35
        
        for label in labels.reversed() {
            label.frame = CGRect(x: 10,
                                 y: top,
                                 width: self.frame.width - 80,
                                 height: 30)
            top += 30
        }
        
        top = 45
        for graph in voteGraphs.reversed() {
            graph.frame = CGRect(x: 0,
                                 y: top + 5,
                                 width: graph.frame.width,
                                 height: 20)
            top += 30
        }
        
        top = 45
        for label in voteCountLabels.reversed() {
            label.frame = CGRect(x: self.frame.width - 100,
                                 y: top,
                                 width: 50,
                                 height: 30)
            top += 30
        }
        
        top = 45
        for button in buttons.reversed() {
            button.frame = CGRect(x: self.frame.width - 40,
                                  y: top + 1,
                                  width: 28,
                                  height: 28)
            top += 30
        }
    }
}
