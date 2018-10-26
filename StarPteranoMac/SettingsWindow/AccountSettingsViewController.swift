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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func authAction() {
        auth()
    }
    
    // マストドン認証
    private var responseJson: [String: AnyObject]?
    private func auth() {
        guard let view = self.view as? AccountSettingsView else { return }
        
        let hostName = (view.hostNameField.stringValue).replacingOccurrences(of: "/ ", with: "")
        if hostName == "" {
            Dialog.show(message: I18n.get("ALERT_INPUT_DOMAIN"), window: SettingsWindow.window)
            return
        }
        
        print("#### " + "https://\(hostName)/api/v1/apps")
        guard let registerUrl = URL(string: "https://\(hostName)/api/v1/apps") else { return }
        
        let body: [String: String] = ["client_name": "StarPterano Mac",
                                      "redirect_uris": "urn:ietf:wg:oauth:2.0:oob",
                                      "scopes": "read write follow"]
        
        // クライアント認証POST
        try? MastodonRequest.firstPost(url: registerUrl, body: body) { (data, response, error) in
            if let data = data {
                do {
                    self.responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, AnyObject>
                    
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
}

private final class AccountSettingsView: NSView {
    let hostNameField = NSTextField()
    let authButton = NSButton()
    let inputCodeField = NSTextField()
    let codeEnterButton = NSButton()
    let scrollView = NSScrollView()
    let accountsView = AccountsView()
    
    init() {
        super.init(frame: SettingsWindow.contentRect)
        
        self.addSubview(hostNameField)
        self.addSubview(authButton)
        self.addSubview(inputCodeField)
        self.addSubview(codeEnterButton)
        self.addSubview(scrollView)
        scrollView.addSubview(accountsView)
        
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
        
        scrollView.drawsBackground = false
    }
    
    func showInputCodeField() {
        DispatchQueue.main.async {
            self.hostNameField.isHidden = true
            self.authButton.isHidden = true
            self.inputCodeField.isHidden = false
            self.codeEnterButton.isHidden = false
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
        
        scrollView.frame = NSRect(x: 0,
                                  y: 0,
                                  width: viewWidth,
                                  height: SettingsWindow.contentRect.height - 50)
    }
}

private final class AccountsView: NSView {
    init() {
        super.init(frame: SettingsWindow.contentRect)
        
        setProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
    }
    
    override func layout() {
    }
}
