//
//  Attachment.swift
//  Drift
//
//  Created by Brian McDonald on 29/07/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import ObjectMapper

public class Attachment: Mappable{
    var id = 0
    var fileName = ""
    var size = 0
    var data = NSData()
    var mimeType = ""
    var conversationId = 0
    var publicPreviewURL: String?
    
    public func mapping(map: Map) {
        id          <- map["id"]
        fileName    <- map["fileName"]
        size        <- map["size"]
        data        <- map["data"]
        mimeType    <- map["mimeType"]
        conversationId <- map["conversationId"]
        publicPreviewURL <- map["publicPreviewUrl"]
    }
    
    required convenience public init?(_ map: Map) {
        self.init()
    }
}
