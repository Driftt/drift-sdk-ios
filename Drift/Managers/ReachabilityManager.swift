//
//  ReachabilityManager.swift
//  Drift
//
//  Created by Brian McDonald on 15/06/2017.
//  Copyright © 2017 Drift. All rights reserved.
//

import Foundation
import Alamofire

extension Notification.Name {
    static let driftNetworkStatusReachable = Notification.Name("drift-sdk-new-network-reachable")
    static let driftNetworkStatusNotReachable = Notification.Name("drift-sdk-new-network-not-reachable")
    static let driftNetworkStatusUnknown = Notification.Name("drift-sdk-new-network-unknown")
}

class ReachabilityManager {
    static var sharedInstance: ReachabilityManager = ReachabilityManager()
    let networkReachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.apple.com")
    
    func start() {        
        networkReachabilityManager?.listener = { status in
            
            switch status {
            case .reachable(.wwan), .reachable(.ethernetOrWiFi):
                LoggerManager.log("Network status became reachable")
                NotificationCenter.default.post(name: .driftNetworkStatusReachable, object: self, userInfo: nil)
            case .notReachable:
                LoggerManager.log("Network status became not reachable")
                NotificationCenter.default.post(name: .driftNetworkStatusNotReachable, object: self, userInfo: nil)
            case .unknown:
                LoggerManager.log("Network Status became unknown")
                NotificationCenter.default.post(name: .driftNetworkStatusUnknown, object: self, userInfo: nil)
            }
        }
        
        networkReachabilityManager?.startListening()
    }
    
}
