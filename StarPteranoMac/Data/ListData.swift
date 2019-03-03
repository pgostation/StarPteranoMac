//
//  ListData.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/03.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Foundation

final class ListData {
    private static var cache: [String: [AnalyzeJson.ListData]] = [:]
    
    static func getCache(accessToken: String) -> [AnalyzeJson.ListData]? {
        return cache[accessToken]
    }
    
    static func setCache(accessToken: String, value: [AnalyzeJson.ListData]) {
        cache[accessToken] = value
    }
}
