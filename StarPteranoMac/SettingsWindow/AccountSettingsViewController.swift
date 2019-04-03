//
//  AccountSettingsViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/26.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class AccountSettingsViewController: NSViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        
        let view = AccountSettingsView()
        self.view = view
        
        view.authButton.action = #selector(authAction)
        view.authButton.target = self
        view.codeEnterButton.action = #selector(codeEnterAction)
        view.codeEnterButton.target = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // マストドン認証
    private var responseJson: [String: AnyObject]?
    @objc func authAction() {
        guard let view = self.view as? AccountSettingsView else { return }
        
        let hostName = (view.hostNameField.stringValue).replacingOccurrences(of: "/ ", with: "")
        if hostName == "" {
            Dialog.show(message: I18n.get("ALERT_INPUT_DOMAIN"), window: SettingsWindow.window)
            return
        }
        
        guard let registerUrl = URL(string: "https://\(hostName)/api/v1/apps") else { return }
        
        let body: [String: String] = ["client_name": "StarPterano Mac",
                                      "redirect_uris": "urn:ietf:wg:oauth:2.0:oob",
                                      "scopes": "read write follow"]
        
        // クライアント認証POST
        try? MastodonRequest.firstPost(url: registerUrl, body: body) { (data, response, error) in
            if let data = data {
                do {
                    self.responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject]
                    
                    DispatchQueue.main.async {
                        // Safariでログイン
                        self.login(hostName: hostName)
                        
                        // 認証コード入力フィールドを表示する
                        view.showInputCodeField()
                    }
                } catch {
                }
            } else if let error = error {
                Dialog.show(message: I18n.get("REQUEST_FAILED_CHECK_DOMAIN"), window: SettingsWindow.window)
                print(error)
            }
        }
    }
    
    // デフォルトブラウザでのログイン
    private func login(hostName: String) {
        guard let clientId = responseJson?["client_id"] as? String else { return }
        var paramBase = ""
        paramBase += "client_id=\(clientId)&"
        paramBase += "response_type=code&"
        paramBase += "redirect_uri=urn:ietf:wg:oauth:2.0:oob&"
        paramBase += "scope=read write follow"
        
        let params = paramBase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        let loginUrl = URL(string: "https://\(hostName)/oauth/authorize?\(params)")!
        
        NSWorkspace.shared.open(loginUrl)
    }
    
    // コード入力
    @objc func codeEnterAction() {
        guard let view = self.view as? AccountSettingsView else { return }
        
        if view.inputCodeField.stringValue.count < 10 {
            Dialog.show(message: I18n.get("ALERT_INPUT_CODE_FAILURE"), window: SettingsWindow.window)
            return
        }
        
        // アクセストークンを取得
        let tmpHostName = view.hostNameField.stringValue.replacingOccurrences(of: "/ ", with: "")
        let hostName = String(tmpHostName).lowercased()
        guard let registerUrl = URL(string: "https://\(hostName)/oauth/token") else { return }
        
        guard let clientId = responseJson?["client_id"] as? String else { return }
        guard let clientSecret = responseJson?["client_secret"] as? String else { return }
        let oauthCode = view.inputCodeField.stringValue
        
        let body: [String: String] = [
            "grant_type" : "authorization_code",
            "redirect_uri" : "urn:ietf:wg:oauth:2.0:oob",
            "client_id": "\(clientId)",
            "client_secret": "\(clientSecret)",
            "code": "\(oauthCode)"]
        
        // クライアント認証POST
        try? MastodonRequest.firstPost(url: registerUrl, body: body) { (data, response, error) in
            if let data = data {
                do {
                    let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject]
                    
                    // ホスト名とアクセストークンを保存
                    if let accessToken = responseJson?["access_token"] as? String {
                        var accountList = SettingsData.accountList
                        accountList.append((hostName, accessToken))
                        SettingsData.accountList = accountList
                    }
                    
                    DispatchQueue.main.async {
                        if SettingsData.accountList.count == 1 {
                            // 初回はメイン画面へ移動
                            MainWindow.show()
                        }
                        
                        view.hostNameField.isHidden = false
                        view.authButton.isHidden = false
                        view.inputCodeField.isHidden = true
                        view.codeEnterButton.isHidden = true
                        
                        // avatarやdisplaynameを取得しておく
                        AccountSettingsViewController.getAccountData(view: view)
                        
                        view.accountsView.refresh()
                    }
                } catch {
                }
            } else if let error = error {
                print(error)
            }
        }
    }
    
    // avatarやdisplaynameの情報を取得する
    static func getAccountData(view: AccountSettingsView?) {
        for data in SettingsData.accountList {
            let hostName = data.0
            let accessToken = data.1
            
            guard let url = URL(string: "https://\(hostName)/api/v1/accounts/verify_credentials") else { return }
            
            try? MastodonRequest.get(url: url, accessToken: accessToken, completionHandler: { (data, response, error) in
                if let data = data {
                    do {
                        if let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                            let accountData = AnalyzeJson.analyzeAccountJson(account: responseJson)
                            
                            if let username = accountData.username, SettingsData.accountUsername(accessToken: accessToken) != username {
                                SettingsData.setAccountUsername(accessToken: accessToken, value: username)
                            }
                            if let icon = accountData.avatar_static, SettingsData.accountIconUrl(accessToken: accessToken) != icon {
                                SettingsData.setAccountIconUrl(accessToken: accessToken, value: icon)
                                
                                view?.accountsView.refresh()
                            }
                            if let id = accountData.id {
                                SettingsData.setAccountNumberID(accessToken: accessToken, value: id)
                            }
                            if let locked = accountData.locked {
                                SettingsData.setAccountLocked(accessToken: accessToken, value: locked == 1)
                            }
                        }
                    } catch {
                    }
                }
            })
        }
    }
}

final class AccountSettingsView: NSView {
    let hostNameField = MyTextField()
    let authButton = NSButton()
    let inputCodeField = MyTextField()
    let codeEnterButton = NSButton()
    let accountsView = AccountsView()
    
    init() {
        super.init(frame: SettingsWindow.contentRect)
        
        self.addSubview(hostNameField)
        self.addSubview(authButton)
        self.addSubview(inputCodeField)
        self.addSubview(codeEnterButton)
        self.addSubview(accountsView)
        
        setProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        hostNameField.placeholderString = I18n.get("PLACEHOLDER_INPUT_DOMAIN")
        
        authButton.title = I18n.get("BUTTON_MASTODON_OAUTH")
        authButton.bezelStyle = .roundRect
        
        inputCodeField.placeholderString = I18n.get("PLACEHOLDER_INPUT_CODE")
        inputCodeField.isHidden = true
        
        codeEnterButton.title = I18n.get("BUTTON_ENTER_CODE")
        codeEnterButton.bezelStyle = .roundRect
        codeEnterButton.isHidden = true
    }
    
    func showInputCodeField() {
        DispatchQueue.main.async {
            self.hostNameField.isHidden = true
            self.authButton.isHidden = true
            self.inputCodeField.isHidden = false
            self.codeEnterButton.isHidden = false
            
            self.inputCodeField.stringValue = ""
        }
    }
    
    override func layout() {
        let viewWidth = SettingsWindow.contentRect.width - SettingsViewController.width
        
        self.frame = NSRect(x: SettingsViewController.width,
                            y: 0,
                            width: viewWidth,
                            height: SettingsWindow.contentRect.height)
        
        hostNameField.frame = NSRect(x: 50,
                                     y: SettingsWindow.contentRect.height - 50,
                                     width: 250,
                                     height: 25)
        
        authButton.frame = NSRect(x: 310,
                                  y: SettingsWindow.contentRect.height - 53,
                                  width: 150,
                                  height: 30)
        
        inputCodeField.frame = NSRect(x: 50,
                                      y: SettingsWindow.contentRect.height - 50,
                                      width: 250,
                                      height: 25)
        
        codeEnterButton.frame = NSRect(x: 310,
                                       y: SettingsWindow.contentRect.height - 53,
                                       width: 150,
                                       height: 30)
        
        accountsView.frame = NSRect(x: 0,
                                    y: 0,
                                    width: viewWidth,
                                    height: SettingsWindow.contentRect.height - 50)
    }
}

final class AccountsView: NSScrollView {
    private var accountViews: [AccountView] = []
    
    init() {
        super.init(frame: SettingsWindow.contentRect)
        
        self.drawsBackground = false
        
        refresh()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func refresh() {
        DispatchQueue.main.async {
            let accountList = SettingsData.accountList
            
            for view in self.accountViews {
                view.removeFromSuperview()
            }
            self.accountViews = []
            
            for account in accountList {
                let view = AccountView(account: account)
                self.accountViews.append(view)
                self.addSubview(view)
                
                view.deleteButton.target = self
                view.deleteButton.action = #selector(self.deleteAction(_:))
                view.upperButton.target = self
                view.upperButton.action = #selector(self.upperAction(_:))
                
                if self.accountViews.count == 1 {
                    view.upperButton.isEnabled = false
                }
            }
            
            self.needsLayout = true
        }
    }
    
    @objc func deleteAction(_ sender: NSButton) {
        guard let view = sender.superview as? AccountView else { return }
        
        for (index, account) in SettingsData.accountList.enumerated() {
            if account.0 == view.hostName && account.1 == view.accessToken {
                SettingsData.accountList.remove(at: index)
                break
            }
        }
        
        refresh()
        
        MainWindow.window?.close()
    }
    
    @objc func upperAction(_ sender: NSButton) {
        guard let view = sender.superview as? AccountView else { return }
        
        for (index, account) in SettingsData.accountList.enumerated() {
            if account.0 == view.hostName && account.1 == view.accessToken {
                SettingsData.accountList.remove(at: index)
                SettingsData.accountList.insert(account, at: index - 1)
                break
            }
        }
        
        refresh()
        
        MainWindow.window?.close()
    }
    
    override func layout() {
        let height: CGFloat = 50
        
        for (index, view) in accountViews.reversed().enumerated() {
            view.frame = NSRect(x: 50,
                                y: CGFloat(accountViews.count - index) * height,
                                width: self.frame.width - 100,
                                height: height)
        }
        
        self.documentView?.frame.size = CGSize(width: self.frame.width, height: CGFloat(accountViews.count) * height)
    }
}

private final class AccountView: NSView {
    private let iconView = MyImageView()
    private let hostLabel = CATextLayer()
    private let idLabel = CATextLayer()
    let deleteButton = NSButton()
    let upperButton = NSButton()
    let hostName: String
    let accessToken: String
    
    init(account: (String, String)) {
        self.hostName = account.0
        self.accessToken = account.1
        
        super.init(frame: SettingsWindow.contentRect)
        
        self.wantsLayer = true
        
        self.addSubview(iconView)
        self.layer?.addSublayer(hostLabel)
        self.layer?.addSublayer(idLabel)
        self.addSubview(deleteButton)
        self.addSubview(upperButton)
        
        setProperties(account: account)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties(account: (String, String)?) {
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        self.layer?.cornerRadius = 6
        
        hostLabel.foregroundColor = NSColor.textColor.cgColor
        
        idLabel.foregroundColor = NSColor.textColor.withAlphaComponent(0.8).cgColor
        
        guard let account = account else { return }
        
        hostLabel.string = account.0
        hostLabel.fontSize = 14
        hostLabel.contentsScale = NSScreen.main?.backingScaleFactor ?? 1
        
        idLabel.string = SettingsData.accountUsername(accessToken: account.1)
        idLabel.fontSize = 14
        idLabel.contentsScale = NSScreen.main?.backingScaleFactor ?? 1
        
        deleteButton.title = I18n.get("BUTTON_DELETE")
        deleteButton.bezelStyle = .roundRect
        
        upperButton.title = "▲"
        upperButton.bezelStyle = .roundRect
        
        if let imageUrl = SettingsData.accountIconUrl(accessToken: account.1) {
            ImageCache.image(urlStr: imageUrl, isTemp: false, isSmall: true) { [weak self] image, url in
                self?.iconView.image = image
            }
        }
    }
    
    override func updateLayer() {
        setProperties(account: nil)
    }
    
    override func layout() {
        self.iconView.frame = NSRect(x: 10,
                                     y: 5,
                                     width: 40,
                                     height: 40)
        
        self.hostLabel.frame = NSRect(x: 55,
                                      y: 25,
                                      width: 250,
                                      height: 20)
        
        self.idLabel.frame = NSRect(x: 55,
                                    y: 5,
                                    width: 250,
                                    height: 20)
        
        self.deleteButton.frame = NSRect(x: 260,
                                         y: 10,
                                         width: 70,
                                         height: 30)
        
        self.upperButton.frame = NSRect(x: 350,
                                        y: 15,
                                        width: 30,
                                        height: 20)
    }
}
