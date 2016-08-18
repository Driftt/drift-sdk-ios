//
//  Inbox.swift
//  Drift
//
//  Created by Brian McDonald on 25/07/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import ObjectMapper

public enum InboxStatus: String{
    case Enabled = "ENABLED"
    case Closed = "CLOSED"
}

public class Inbox: Mappable {
    
    var id: Int!
    var status: InboxStatus!
    var name: String?
    var address: String?
    var forwardAddress: String?
    var openConversationCount: Int!
    var closedConversationCount: Int!
    var createdAt: NSDate = NSDate()
    var conversations: [Conversation]!
    
    public required convenience init?(_ map: Map) {
        self.init()
    }
    
    public func mapping(map: Map) {
        id                      <- map["id"]
        status                  <- map["status"]
        name                    <- map["name"]
        address                 <- map["address"]
        forwardAddress          <- map["forwardAddress"]
        openConversationCount   <- map["openConversationCount"]
        closedConversationCount <- map["closedConversationCount"]
        createdAt               <- (map["createdAt"], DriftDateTransformer())
    }
}
