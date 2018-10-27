//
//  MainViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class MainViewController: NSViewController {
    static weak var instance: MainViewController?
    var timelineList: [String: TimeLineViewController] = [:]
}
