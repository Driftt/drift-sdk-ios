//
//  Message.swift
//  Drift
//
//  Created by Brian McDonald on 25/07/2016.
//  Copyright © 2016 Drift. All rights reserved.
//


import ObjectMapper

public enum ContentType: String{
    case Chat = "CHAT"
}

public enum Type: String{
    case Chat = "CHAT"
}

public enum AuthorType: String{
    case User = "USER"
    case EndUser = "END_USER"
}

public enum SendStatus: String{
    case Sent = "SENT"
    case Pending = "PENDING"
    case Failed = "FAILED"
}

public class Message: Mappable, Equatable, Hashable{
    var id: Int!
    var uuid: String?
    var inboxId: Int!
    var body: String?
    var attachments: [Int] = []
    var contentType = ContentType.Chat.rawValue
    var createdAt = NSDate()
    var authorId: Int!
    var authorType: AuthorType!
    var type: Type!
    
    var conversationId: Int!
    var requestId: Double = 0
    var sendStatus: SendStatus!

    public var hashValue: Int {
        return id
    }
    
    required convenience public init?(_ map: Map) {
        if map.JSONDictionary["contentType"] as? String == nil || ContentType(rawValue: map.JSONDictionary["contentType"] as! String) == nil{
            return nil
        }
        
        if let body = map.JSONDictionary["body"] as? String, attachments = map.JSONDictionary["attachments"] as? [Int]{
            if body == "" && attachments.count == 0{
                return nil
            }
        }
        
        self.init()
    }
    
    public func mapping(map: Map) {
        id                      <- map["id"]
        uuid                    <- map["uuid"]
        inboxId                 <- map["inboxId"]
        body                    <- map["body"]
        attachments             <- map["attachments"]
        contentType             <- map["contentType"]
        createdAt               <- (map["createdAt"], DriftDateTransformer())
        authorId                <- map["authorId"]
        authorType              <- map["authorType"]
        type                    <- map["type"]
        conversationId          <- map["conversationId"]
    }

}

public func ==(lhs: Message, rhs: Message) -> Bool {
    return lhs.uuid == rhs.uuid
}

