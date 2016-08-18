//
//  Conversation.swift
//  Drift
//
//  Created by Brian McDonald on 25/07/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import ObjectMapper

public enum ConversationStatus: String{
    case Open = "OPEN"
    case Closed = "CLOSED"
    case Pending = "PENDING"
}

public class Conversation: Mappable, Equatable{
    var id: Int!
    var orgId: Int!
    var uuid: String?
    
    var inboxId: Int!
    var displayId: Int!
    var endUserId: Int!
    var assigneeId: Int?
    var status: ConversationStatus!
    var subject: String?
    var preview: String?
    var updatedAt = NSDate()
    
    var messages: [Message]!
    
    public required convenience init?(_ map: Map) {
        self.init()
    }
    
    public func mapping(map: Map) {
        assigneeId  <- map["assigneeId"]
        id          <- map["id"]
        inboxId     <- map["inboxId"]
        displayId   <- map["displayId"]
        endUserId   <- map["endUserId"]
        subject     <- map["subject"]
        preview     <- map["preview"]
        updatedAt   <- (map["updatedAt"], DriftDateTransformer())
        uuid        <- map["uuid"]
        orgId       <- map["orgId"]
    }

}

public func ==(lhs: Conversation, rhs: Conversation) -> Bool {
    return lhs.uuid == rhs.uuid
}

