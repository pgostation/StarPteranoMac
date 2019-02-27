//
//  AllListsViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/26.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa

final class AllListsViewController: NSViewController {
    init(accountId: String, hostName: String, accessToken: String) {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
