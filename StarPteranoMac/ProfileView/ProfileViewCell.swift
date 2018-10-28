//
//  ProfileViewCell.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class ProfileViewCell: NSView {
    weak var timelineView: TimeLineView? = nil
    
    init(accountData: AnalyzeJson.AccountData?, isTemp: Bool) {
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
