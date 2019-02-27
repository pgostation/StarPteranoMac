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
    private var actions: [MyAlertAction] = []
    
    init(title: String?, message: String?) {
        super.init(nibName: nil, bundle: nil)
        
        let view = MyAlertView(title: title, message: message)
        self.view = view
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addAction(_ action: MyAlertAction) {
        actions.append(action)
    }
}

private class MyAlertView: NSView {
    init(title: String?, message: String?) {
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
