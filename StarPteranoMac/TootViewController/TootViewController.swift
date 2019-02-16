//
//  TootViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class TootViewController: NSViewController {
    private static var instances: [String: TootViewController] = [:]
    private let hostName: String
    private let accessToken: String
    
    init(hostName: String, accessToken: String) {
        self.hostName = hostName
        self.accessToken = accessToken
        
        super.init(nibName: nil, bundle: nil)
        
        TootViewController.instances[accessToken] = self
        
        self.view = TootView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func get(accessToken: String?) -> TootViewController? {
        guard let accessToken = accessToken else { return nil }
        
        return instances[accessToken]
    }
}
