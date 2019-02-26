//
//  TootViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class TootViewController: NSViewController, NSTextViewDelegate {
    private static var instances: [String: TootViewController] = [:]
    let hostName: String
    let accessToken: String
    
    init(hostName: String, accessToken: String) {
        self.hostName = hostName
        self.accessToken = accessToken
        
        super.init(nibName: nil, bundle: nil)
        
        TootViewController.instances[accessToken] = self
        
        let view = TootView()
        self.view = view
        
        view.target = self
        
        // メッセージフィールドのデリゲートを設定
        view.textField.delegate = self
        view.spoilerTextField.delegate = self
        
        // 入力バー部分のボタン
        view.imagesButton.target = self
        view.imagesButton.action = #selector(addImageAction)
        view.imagesCountButton.target = self
        view.imagesCountButton.action = #selector(showImagesAction)
        view.protectButton.target = self
        view.protectButton.action = #selector(protectAction)
        view.cwButton.target = self
        view.cwButton.action = #selector(cwAction)
        //view.scheduledButton.target = self
        //view.scheduledButton.action = #selector(scheduleAction)
        view.emojiButton.target = self
        view.emojiButton.action = #selector(emojiAction)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func get(accessToken: String?) -> TootViewController? {
        guard let accessToken = accessToken else { return nil }
        
        return instances[accessToken]
    }
    
    // トゥートする
    @objc func tootAction() {
        guard let view = self.view as? TootView else { return }
        
        // 通常テキスト
        let attributedText = view.textField.attributedString()
        
        let text = DecodeToot.encodeEmoji(attributedText: attributedText, textStorage: NSTextStorage(attributedString: attributedText), isToot: true)
        
        // 保護テキスト
        let spoilerText: String?
        if view.spoilerTextField.isHidden {
            spoilerText = nil
        } else {
            spoilerText = DecodeToot.encodeEmoji(attributedText: view.spoilerTextField.attributedString(), textStorage: NSTextStorage(attributedString: view.spoilerTextField.attributedString()), isToot: true)
        }
        
        // 投稿するものがない
        if attributedText.length == 0 && spoilerText == nil && view.imageCheckView.urls.count == 0 { return }
        
        // 公開範囲
        let visibility = view.protectMode.rawValue
        let nsfw = (!view.spoilerTextField.isHidden) || view.imageCheckView.nsfwSw.state == .on
        
        // 投稿内容を空にする
        view.textField.string = ""
        view.spoilerTextField.string = ""
        view.textCountLabel.stringValue = ""
        TootView.inReplyToId = nil
        TootView.scheduledDate = nil
        
        if view.imageCheckView.urls.count > 0 {
            let imageCheckView = view.imageCheckView
            view.imageCheckView.urls = []
            view.imageCheckView.closeAction()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                // 画像をアップロードしてから投稿
                let group = DispatchGroup()
                
                var idList: [String] = []
                for url in imageCheckView.urls {
                    group.enter()
                    let lowUrlStr = url.absoluteString.lowercased()
                    if lowUrlStr.contains(".mp4") || lowUrlStr.contains(".m4v") || lowUrlStr.contains(".mov") {
                        // 動画
                        ImageUpload.upload(movieUrl: url, hostName: self.hostName, accessToken: self.accessToken, callback: { json in
                            if let json = json {
                                if let id = json["id"] as? String {
                                    idList.append(id)
                                }
                                group.leave()
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    group.leave()
                                }
                            }
                        })
                    } else {
                        // 静止画
                        ImageUpload.upload(httpMethod: "POST", imageUrl: url, count: imageCheckView.urls.count,  hostName: self.hostName, accessToken: self.accessToken, callback: { json in
                            if let json = json {
                                if let id = json["id"] as? String {
                                    idList.append(id)
                                }
                                group.leave()
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    group.leave()
                                }
                            }
                        })
                    }
                }
                
                // 画像を全てアップロードし終わったら投稿
                group.notify(queue: DispatchQueue.main) {
                    let addJson: [String: Any] = ["media_ids": idList]
                    self.toot(text: text, spoilerText: spoilerText, nsfw: nsfw, visibility: visibility, addJson: addJson)
                }
            }
        } else {
            // テキストだけなのですぐに投稿
            toot(text: text, spoilerText: spoilerText, nsfw: nsfw, visibility: visibility, addJson: [:])
        }
    }
    
    private func toot(text: String, spoilerText: String?, nsfw: Bool, visibility: String, addJson: [String: Any]) {
        let url = URL(string: "https://\(hostName)/api/v1/statuses")!
        
        var bodyJson: [String: Any] = [
            "status": text,
            "visibility": visibility,
            ]
        if let spoilerText = spoilerText {
            bodyJson.updateValue(spoilerText, forKey: "spoiler_text")
        }
        if nsfw {
            bodyJson.updateValue(1, forKey: "sensitive")
        }
        if let inReplyToId = TootView.inReplyToId {
            bodyJson.updateValue(inReplyToId, forKey: "in_reply_to_id")
        }
        for data in addJson {
            bodyJson.updateValue(data.value, forKey: data.key)
        }
        if let scheduledDate = TootView.scheduledDate {
            let dateFormatter: DateFormatter = {
                let formatter = DateFormatter()
                let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
                formatter.locale = enUSPosixLocale
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
                return formatter
            }()
            let str = dateFormatter.string(from: scheduledDate)
            bodyJson.updateValue(str, forKey: "scheduled_at")
        }
        
        try? MastodonRequest.post(url: url, accessToken: accessToken, body: bodyJson) { (data, response, error) in
            if let error = error {
                Dialog.show(message: I18n.get("ALERT_SEND_TOOT_FAILURE") + "\n" + error.localizedDescription)
            } else {
                if let response = response as? HTTPURLResponse {
                    if response.statusCode == 200 {
                        // 最近使用したハッシュタグに追加
                        do {
                            if let responseJson = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any] {
                                var acct = ""
                                let contentData = AnalyzeJson.analyzeJson(view: nil, model: nil, json: responseJson, acct: &acct)
                                for dict in contentData.tags ?? [[:]] {
                                    if let tag = dict["name"] {
                                        SettingsData.addRecentHashtag(key: tag, accessToken: self.accessToken)
                                    }
                                }
                            }
                        } catch {}
                    } else {
                        Dialog.show(message: I18n.get("ALERT_SEND_TOOT_FAILURE") + "\nHTTP status \(response.statusCode)")
                    }
                }
            }
        }
    }
    
    // 添付画像を追加する
    @objc func addImageAction() {
        guard let view = self.view as? TootView else { return }
        
        if view.imageCheckView.urls.count >= 4 {
            Dialog.show(message: I18n.get("ALERT_IMAGE_COUNT_MAX"))
            return
        }
        
        // ファイル選択
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false // 複数ファイルの選択を許すか
        openPanel.canChooseDirectories = false // ディレクトリを選択できるか
        openPanel.canCreateDirectories = false // ディレクトリを作成できるか
        openPanel.canChooseFiles = true // ファイルを選択できるか
        openPanel.allowedFileTypes = NSImage.imageTypes // 選択できるファイル種別
        openPanel.begin { (result) -> Void in
            if result.rawValue == NSFileHandlingPanelOKButton { // ファイルを選択したか(OKを押したか)
                guard let url = openPanel.url else { return }
                
                view.imageCheckView.add(imageUrl: url)
                
                for i in 1...3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 * Double(i)) {
                        view.refresh()
                    }
                }
            }
        }
    }
    
    // 添付画像を確認、削除する
    @objc func showImagesAction() {
        guard let view = self.view as? TootView else { return }
        
        for subVC in MainViewController.instance?.subVCList ?? [] {
            if accessToken == subVC.tootVC.accessToken {
                if let view = subVC.view.viewWithTag(7624) {
                    // 隠す
                    view.removeFromSuperview()
                } else {
                    // 表示する
                    subVC.view.addSubview(view.imageCheckView)
                    
                    view.imageCheckView.needsLayout = true
                    subVC.view.needsLayout = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        subVC.view.needsLayout = true
                    }
                }
            }
        }
    }
    
    // 公開範囲を設定する
    @objc func protectAction() {
        guard let view = self.view as? TootView else { return }
        
        SettingsSelectProtectMode.showActionSheet(hostName: hostName, accessToken: accessToken, fromView: view.protectButton) { (mode) in
            
            view.protectMode = mode
            view.refresh()
        }
    }
    
    // センシティブなトゥートにする
    @objc func cwAction() {
        guard let view = self.view as? TootView else { return }
        
        view.spoilerTextField.isHidden = !view.spoilerTextField.isHidden
        view.needsLayout = true
        
        if view.spoilerTextField.isHidden {
            view.textField.becomeFirstResponder()
        } else {
            view.spoilerTextField.becomeFirstResponder()
        }
    }
    
    // カスタム絵文字キーボードを表示する
    @objc func emojiAction() {
        for subVC in MainViewController.instance?.subVCList ?? [] {
            if accessToken == subVC.tootVC.accessToken {
                if let view = subVC.view.viewWithTag(3948) {
                    view.removeFromSuperview()
                } else {
                    // このビューの入力フィールドをファーストレスポンダにする
                    if NSApplication.shared.keyWindow?.firstResponder == (self.view as? TootView)?.spoilerTextField {
                        // なにもしない
                    } else {
                        NSApplication.shared.keyWindow?.makeFirstResponder((self.view as? TootView)?.textField)
                    }
                    
                    // 絵文字キーボードを表示する
                    let emojiView = EmojiView(hostName: hostName, accessToken: accessToken)
                    subVC.view.addSubview(emojiView)
                    
                    subVC.view.needsLayout = true
                }
            }
        }
    }
}
