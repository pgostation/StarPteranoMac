//
//  MastodonRequest.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/26.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class MastodonRequest {
    static let session = URLSession.shared
    
    // GETメソッド
    private static var lastRequestStr = "" // GETメソッドをループして呼ぶのを防ぐ
    private static var lastReqestDate = Date()
    static func get(url: URL, accessToken: String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws {
        let requestStr = accessToken + url.absoluteString
        if lastRequestStr == requestStr && Date().timeIntervalSince(lastReqestDate) <= 1 {
            print("1秒以内に同一URLへのGETがありました \(url.absoluteString)")
            return
        }
        
        print("get \(url.absoluteString)")
        
        lastRequestStr = requestStr
        lastReqestDate = Date()
        
        var request: URLRequest = URLRequest(url: url)
        
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        session.dataTask(with: request) { (data, response, error) in
            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    print("response.statusCode=\(response.statusCode), data=\(String(data: data ?? Data(), encoding: String.Encoding.utf8) ?? "-")")
                }
                showRemain(accessToken: accessToken, response: response)
            }
            
            completionHandler(data, response, error)
            }.resume()
    }
    
    // POSTメソッド
    static func post(url: URL, accessToken: String, body: Dictionary<String, Any>, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws {
        print("post \(url.path)")
        
        var request: URLRequest = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        
        session.dataTask(with: request) { (data, response, error) in
            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    print("response.statusCode=\(response.statusCode), data=\(String(data: data ?? Data(), encoding: String.Encoding.utf8) ?? "-")")
                }
                showRemain(accessToken: accessToken, response: response)
            }
            
            completionHandler(data, response, error)
            }.resume()
    }
    
    // DELETEメソッド
    static func delete(url: URL, accessToken: String, body: Dictionary<String, Any>? = nil, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws {
        var request: URLRequest = URLRequest(url: url)
        
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if let body = body {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        }
        
        session.dataTask(with: request) { (data, response, error) in
            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    print("response.statusCode=\(response.statusCode), data=\(String(data: data ?? Data(), encoding: String.Encoding.utf8) ?? "-")")
                }
                showRemain(accessToken: accessToken, response: response)
            }
            
            completionHandler(data, response, error)
            }.resume()
    }
    
    // PATCHメソッド
    static func patch(url: URL, accessToken: String, body: Dictionary<String, Any>?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws {
        var request: URLRequest = URLRequest(url: url)
        
        request.httpMethod = "PATCH"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if let body = body {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        }
        
        session.dataTask(with: request) { (data, response, error) in
            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    print("response.statusCode=\(response.statusCode), data=\(String(data: data ?? Data(), encoding: String.Encoding.utf8) ?? "-")")
                }
                showRemain(accessToken: accessToken, response: response)
            }
            
            completionHandler(data, response, error)
            }.resume()
    }
    
    // POSTメソッド (アクセストークンなし、認証前に使う)
    static func firstPost(url: URL, body: Dictionary<String, String>, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws {
        var request: URLRequest = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        
        session.dataTask(with: request, completionHandler: completionHandler).resume()
    }
    
    private static func showRemain(accessToken: String, response: HTTPURLResponse) {
        guard let remain = response.allHeaderFields["x-ratelimit-remaining"] as? String ?? response.allHeaderFields["X-RateLimit-Remaining"] as? String else { return }
        guard let maxCount = response.allHeaderFields["x-ratelimit-limit"] as? String ?? response.allHeaderFields["X-RateLimit-Limit"] as? String else { return }
        
        MainViewController.showRemain(accessToken: accessToken, remain: Int(remain)!, maxCount: Int(maxCount)!)
    }
}
