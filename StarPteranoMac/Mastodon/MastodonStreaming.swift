//
//  MastodonStreaming.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Foundation
import Starscream

final class MastodonStreaming: NSObject, WebSocketDelegate, WebSocketPongDelegate {
    private var socket: WebSocket
    private var callback: (String?)->Void
    private var timer: Timer? = nil
    private let accessToken: String
    var isConnecting = true
    var isConnected = false
    
    init(url: URL, accessToken: String, callback: @escaping (String?)->Void) {
        self.socket = WebSocket(url: url)
        self.accessToken = accessToken
        self.callback = callback
        
        super.init()
        
        self.socket.delegate = self
        self.socket.pongDelegate = self
        self.socket.connect()
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 30) { [weak self] in
            self?.isConnecting = false
        }
        
        MainViewController.setLamp(accessToken: accessToken)
    }
    
    deinit {
        print("websocket is disposed")
    }
    
    func websocketDidConnect(socket: WebSocketClient) {
        print("websocket is connected")
        self.isConnected = true
        self.isConnecting = false
        
        self.timer = Timer.scheduledTimer(timeInterval: 599, target: self, selector: #selector(ping), userInfo: nil, repeats: true)
        
        MainViewController.setLamp(accessToken: accessToken)
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("websocket is disconnected. error=\(error?.localizedDescription ?? "")")
        if self.isConnected {
            self.isConnected = false
            self.isConnecting = false
            self.timer?.invalidate()
            self.timer = nil
            
            MainViewController.setLamp(accessToken: accessToken)
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        DispatchQueue.global().async {
            self.callback(text)
        }
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        //
    }
    
    func disconnect() {
        if self.isConnected {
            self.isConnected = false
            self.isConnecting = false
            self.socket.disconnect()
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    @objc func ping() {
        print("websocket ping")
        self.socket.write(ping: Data())
    }
    
    func websocketDidReceivePong(socket: WebSocketClient, data: Data?) {
        print("Got pong! Maybe some data: \(data?.count ?? -1)")
    }
}
