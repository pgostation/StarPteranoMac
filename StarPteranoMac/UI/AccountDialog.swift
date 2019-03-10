//
//  AccountDialog.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/10.
//  Copyright © 2019 pgostation. All rights reserved.
//

// アカウントの入力サジェストがあるダイアログ

import Cocoa

final class AccountDialog: NSView, NSTextFieldDelegate {
    private static var delegate: AccountDialog?
    fileprivate var textField = MyTextField()
    private let helperView = AccountHelperView()
    private let alert = NSAlert()
    private var callback: ((NSTextField, Bool)->Void)?
    
    // 入力欄付きのダイアログを表示
    static func showWithTextInput(message: String, window: NSWindow? = nil, okName: String, cancelName: String, defaultText: String?, accountList: [String: AnalyzeJson.AccountData]?, subAccountList: [String],  callback: @escaping (NSTextField, Bool)->Void) {
        let object = AccountDialog()
        
        object.callback = callback
        
        let alert = object.alert
        alert.messageText = message
        
        self.delegate = object
        object.layout()
        
        let textField = object.textField
        textField.stringValue = defaultText ?? ""
        textField.delegate = object
        alert.accessoryView = object
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            textField.becomeFirstResponder()
        }
        
        object.addSubview(textField)
        object.addSubview(object.helperView)
        
        object.helperView.setList(accountList: accountList)
        object.helperView.setList(subAccountList: subAccountList)
        
        alert.addButton(withTitle: okName)
        alert.addButton(withTitle: cancelName)
        
        if let window = MainWindow.window {
            alert.beginSheetModal(for: window, completionHandler: { result in
                callback(textField, result == .alertFirstButtonReturn)
                delegate = nil
            })
        } else {
            let result = alert.runModal()
            callback(textField, result == .alertFirstButtonReturn)
            delegate = nil
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        helperView.change(string: textField.stringValue)
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(moveUp(_:)) {
            helperView.up()
        } else if commandSelector == #selector(moveDown(_:)) {
            helperView.down()
        } else if commandSelector == #selector(insertNewline(_:)) {
            self.textField.resignFirstResponder()
            MainWindow.window?.attachedSheet?.close()
            callback?(textField, true)
        }
        return false
    }
    
    override func layout() {
        self.frame = NSRect(x: 0, y: 0, width: 300, height: 300)
        
        textField.frame = NSRect(x: 0, y: 280, width: 300, height: 20)
        
        helperView.frame = NSRect(x: 0, y: 0, width: 300, height: 280)
    }
}

private class AccountHelperView: NSView {
    private var accountList: [String: AnalyzeJson.AccountData]?
    private var subAccountList: [String]?
    private var helperCell: [AccountHelperCell] = []
    var selectedLine: Int? = nil
    
    func change(string: String) {
        var list: [String] = []
        
        // 先頭が一致
        for tmp in accountList ?? [:] {
            if list.count >= 20 { break }
            if let acct = tmp.value.acct {
                if acct.lowercased().hasPrefix(string.lowercased()) && !list.contains(acct) {
                    list.append(acct)
                }
            }
        }
        for tmp in subAccountList ?? [] {
            if list.count >= 20 { break }
            if tmp.lowercased().hasPrefix(string.lowercased()) && !list.contains(tmp) {
                list.append(tmp)
            }
        }
        
        // 途中一致
        for tmp in accountList ?? [:] {
            if list.count >= 20 { break }
            if let acct = tmp.value.acct {
                if acct.lowercased().contains(string.lowercased()) && !list.contains(acct) {
                    list.append(acct)
                }
            }
        }
        for tmp in subAccountList ?? [] {
            if list.count >= 20 { break }
            if tmp.lowercased().contains(string.lowercased()) && !list.contains(tmp) {
                list.append(tmp)
            }
        }
        
        for oldCell in helperCell {
            oldCell.removeFromSuperview()
        }
        helperCell = []
        for name in list {
            let cell = AccountHelperCell(name: name)
            self.addSubview(cell)
            helperCell.append(cell)
        }
        
        self.needsLayout = true
    }
    
    func setList(accountList: [String: AnalyzeJson.AccountData]?) {
        self.accountList = accountList
    }
    
    func setList(subAccountList: [String]) {
        self.subAccountList = subAccountList
    }
    
    override func layout() {
        var top = CGFloat(280)
        
        for cell in helperCell {
            top -= 20
            cell.frame = NSRect(x: 0,
                                y: top,
                                width: 300,
                                height: 20)
        }
    }
    
    func up() {
        if selectedLine == nil {
            selectedLine = helperCell.count - 1
        } else {
            selectedLine = max(0, selectedLine! - 1)
        }
        refresh()
    }
    
    func down() {
        if selectedLine == nil {
            selectedLine = 0
        } else {
            selectedLine = max(0, min(helperCell.count - 1, selectedLine! + 1))
        }
        refresh()
    }
    
    private func refresh() {
        for cell in helperCell {
            cell.wantsLayer = true
            cell.layer?.backgroundColor = NSColor.clear.cgColor
        }
        
        if let selectedLine = selectedLine, selectedLine >= 0, selectedLine < helperCell.count {
            helperCell[selectedLine].layer?.backgroundColor = NSColor.highlightColor.cgColor
            
            helperCell[selectedLine].tapAction()
        }
    }
}

private class AccountHelperCell: NSView {
    let label = MyTextField()
    let button = NSButton()
    
    init(name: String) {
        super.init(frame: NSRect(x: 0, y: 0, width: 300, height: 20))
        
        self.addSubview(label)
        self.addSubview(button)
        
        label.stringValue = name
        label.isSelectable = false
        label.isEditable = false
        label.drawsBackground = false
        label.isBordered = false
        
        button.isTransparent = true
        button.target = self
        button.action = #selector(tapAction)
        
        label.frame = self.frame
        button.frame = self.frame
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tapAction() {
        guard let helperView = self.superview as? AccountHelperView else { return }
        guard let dialogView = helperView.superview as? AccountDialog else { return }
        
        dialogView.textField.stringValue = self.label.stringValue
    }
}
