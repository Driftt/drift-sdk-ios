//
//  SocketManager.swift
//  Drift
//
//  Created by Eoin O'Connell on 31/05/2017.
//  Copyright © 2017 Drift. All rights reserved.
//

import UIKit
import Alamofire
import ObjectMapper

extension Notification.Name {
        static let driftOnNewMessageReceived = Notification.Name("drift-sdk-new-message-received")
    static let driftSocketStatusUpdated = Notification.Name("drift-sdk-socket-status-updated")
}

enum ConnectionStatus {
    case connected
    case connecting
    case disconnected
}

class SocketManager {
    
    static var sharedInstance: SocketManager = {
        let socketManager = SocketManager()
        NotificationCenter.default.addObserver(socketManager, selector: #selector(SocketManager.networkDidBecomeReachable), name: NSNotification.Name.driftNetworkStatusReachable, object: nil)
        return socketManager
    }()
    
    var socket: Socket?
    
    func connectToSocket(socketAuth: SocketAuth) {
        ReachabilityManager.sharedInstance.start()
        if let socket = socket {
            socket.disconnect()
        }
        
        socket = Socket(url: URL(string: "wss://chat.api.drift.com/ws/websocket")!, params: ["session_token": socketAuth.sessionToken])
        socket?.enableLogging = DriftManager.sharedInstance.debug
        socket!.onConnect =  {
            self.didConnect()
            let channel = self.socket?.channel("user:\(socketAuth.userId)")
            
            channel?.on("change", callback: { (response) in
                if let body = response.payload["body"] as? [String: Any], let object = body["object"] as? [String: Any], let data = body["data"] as? [String: Any], let type = object["type"] as? String {
                    switch type {
                    case "MESSAGE":
                        if let message = Mapper<Message>().map(JSON: data), message.contentType == ContentType.Chat{
                            self.didRecieveNewMessage(message: message)
                        }
                    default:
                        LoggerManager.log("Ignoring unknown event type")
                    }
                }else{
                    LoggerManager.log("Ignoring unknown event type")
                }
            })
            
            channel?.join()
        }
        
        socket?.onDisconnect = { error in
            self.didDisconnect()
            if ReachabilityManager.sharedInstance.networkReachabilityManager?.isReachable == true {
                self.socket?.connect()
            }
        }
        
        socket?.connect()
    }
    
    @objc func networkDidBecomeReachable(){
        if socket?.isConnected == false {
            willReconnect()
            socket?.connect()
        }
    }
    
    func willReconnect() {
        NotificationCenter.default.post(name: .driftSocketStatusUpdated, object: self, userInfo: ["connectionStatus": ConnectionStatus.connecting])
    }
    
    func didConnect() {
        NotificationCenter.default.post(name: .driftSocketStatusUpdated, object: self, userInfo: ["connectionStatus": ConnectionStatus.connected])
    }
    
    func didDisconnect() {
        NotificationCenter.default.post(name: .driftSocketStatusUpdated, object: self, userInfo: ["connectionStatus": ConnectionStatus.disconnected])
    }
    
    func didRecieveNewMessage(message: Message) {
        PresentationManager.sharedInstance.didRecieveNewMessage(message)
        NotificationCenter.default.post(name: .driftOnNewMessageReceived, object: self, userInfo: ["message": message])
    }
    
}
