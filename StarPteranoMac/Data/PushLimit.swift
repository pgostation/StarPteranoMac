//
//  PushLimit.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/26.
//  Copyright © 2019 pgostation. All rights reserved.
//

// プッシュ通知しすぎを制限する
// 5分で20回、60分で60回

import Foundation

final class PushLimit {
    private static var min5List: [Date] = []
    private static var min60List: [Date] = []
    
    // 通知送った時刻を保持する
    static func addCount() {
        min5List.append(Date())
        min60List.append(Date())
    }
    
    // 通知送ってもいいか
    static func isOK() -> Bool {
        // 5分以上経ったら記録削除
        for (index, date) in min5List.enumerated().reversed() {
            if date.timeIntervalSinceNow < -5 * 60 {
                min5List.remove(at: index)
            }
        }
        
        // 60分以上経ったら記録削除
        for (index, date) in min60List.enumerated().reversed() {
            if date.timeIntervalSinceNow < -60 * 60 {
                min60List.remove(at: index)
            }
        }
        
        // 5分間で20回制限
        if min5List.count >= 20 {
            return false
        }
        
        // 60分間で60回制限
        if min60List.count >= 60 {
            return false
        }
        
        return true
    }
}
