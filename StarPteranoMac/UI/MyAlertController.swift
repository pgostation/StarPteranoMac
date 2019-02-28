//
//  MyAlertController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/27.
//  Copyright © 2019 pgostation. All rights reserved.
//

// UIAlertControllerっぽく使えるポップアップView

import Cocoa

final class MyAlertController: NSViewController {
    init(title: String?, message: String?) {
        super.init(nibName: nil, bundle: nil)
        
        let view = MyAlertView(title: title, message: message)
        self.view = view
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addAction(_ action: MyAlertAction) {
        guard let view = self.view as? MyAlertView else { return }
        
        let button = view.addAction(action: action)
        
        button.target = self
        button.action = #selector(execAction(_:))
    }
    
    @objc func execAction(_ sender: MyAlertButton) {
        sender.alertAction.handler(true)
    }
}

private class MyAlertView: NSView {
    init(title: String?, message: String?) {
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addAction(action: MyAlertAction) -> MyAlertButton {
        let actionButton = MyAlertButton(action: action)
        
        let attributedTitle = NSMutableAttributedString(string: action.title)
        if action.style == .defaultValue {
            attributedTitle.addAttributes([NSAttributedString.Key.foregroundColor : NSColor.blue],
                                          range: NSRange(location: 0, length: attributedTitle.length))
        } else {
            attributedTitle.addAttributes([NSAttributedString.Key.foregroundColor : NSColor.red],
                                          range: NSRange(location: 0, length: attributedTitle.length))
        }
        actionButton.attributedTitle = attributedTitle
        
        self.addSubview(actionButton)
        self.needsLayout = true
        
        return actionButton
    }
    
    override func layout() {
        var top: CGFloat = 20
        
        for subview in self.subviews.reversed() {
            subview.frame = NSRect(x: 25, y: top, width: 150, height: 30)
            
            top += 30
        }
        
        self.frame = NSRect(x: 0, y: 0, width: 160, height: top + 10)
    }
}

final class MyAlertButton: NSButton {
    let alertAction: MyAlertAction
    
    init(action: MyAlertAction) {
        self.alertAction = action
        
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


final class MyAlertAction {
    enum Style {
        case destructive
        case defaultValue
    }
    
    let title: String
    let style: Style
    let handler: (Bool)->Void
    
    init(title: String, style: Style, handler: @escaping (Bool)->Void) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}
