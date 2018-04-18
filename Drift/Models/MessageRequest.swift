//
//  MessageRequest.swift
//  Drift-SDK
//
//  Created by Eoin O'Connell on 06/02/2018.
//  Copyright © 2018 Drift. All rights reserved.
//

import UIKit
import ObjectMapper

class MessageRequest {

    var body: String = ""
    var type:ContentType = .Chat
    var attachments: [Int] = []
    var requestId: Double = Date().timeIntervalSince1970

    var googleMeeting: GoogleMeeting?
    var userAvailability: UserAvailability?
    var conversationId: Int?
    var meetingUserId: Int?
    var meetingTimeSlot:Date?
    
    init (body: String, contentType: ContentType = .Chat, attachmentIds: [Int] = []) {
        self.body = TextHelper.wrapTextInHTML(text: body)
        self.type = contentType
        self.attachments = attachmentIds
    }
    
    init(googleMeeting: GoogleMeeting, userAvailability: UserAvailability, meetingUserId: Int, conversationId: Int, timeSlot: Date) {
        self.body = ""
        self.type = .Chat
        self.googleMeeting = googleMeeting
        self.userAvailability = userAvailability
        self.conversationId = conversationId
        self.meetingUserId = meetingUserId
        self.meetingTimeSlot = timeSlot
    }
    
    func getContextUserAgent() -> String {

        var userAgent = "Mobile App / \(UIDevice.current.drift_modelName) / \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] {
            userAgent.append(" / App Version: \(version)")
        }
        return userAgent
    }
    
  
    func toJSON() -> [String: Any]{
        
        var json:[String : Any] = [
            "body": body,
            "type": type.rawValue,
            "attachments": attachments,
            "context": ["userAgent": getContextUserAgent()]
        ]
        
        if let googleMeetingId = googleMeeting?.meetingId,
            let googleMeetingURL = googleMeeting?.meetingURL,
            let meetingDuration = userAvailability?.duration,
            let meetingUserId = meetingUserId,
            let meetingTimeSlot = meetingTimeSlot,
            let conversationId = conversationId,
            let agentTimeZone = userAvailability?.timezone{
            
            
            /*
 
             "id": "vojjqq8qub2sgaqk40ukbj9fbs",
             "url": "https://www.google.com/calendar/event?eid=dm9qanFxOHF1YjJzZ2FxazQwdWtiajlmYnMgc2FtbWllc2tpQG0",
             "availabilitySlot": 1518880500000,
             "slotDuration": 45,
             "agentId": 11890,
             "conversationId": 110522,
             "endUserTimeZone": "America/New_York",
             "agentTimeZone": "America/North_Dakota/New_Salem"
             
            */
            
            let apointment: [String: Any] = [
                "id":googleMeetingId,
                "url": googleMeetingURL,
                "availabilitySlot": meetingTimeSlot.timeIntervalSince1970*1000,
                "slotDuration": meetingDuration,
                "agentId": meetingUserId,
                "conversationId": conversationId,
                "endUserTimeZone": TimeZone.current.identifier,
                "agentTimeZone": agentTimeZone
            ]
            
            let attributes: [String: Any] = [
                "scheduleMeetingFlow": true,
                "scheduleMeetingWith":meetingUserId,
                "appointmentInfo":apointment]
            json["attributes"] = attributes
        }
        
        return json
    }
    
    func generateFakeMessage(conversationId:Int, userId: Int) -> Message {
        
        let message = Message()
        message.authorId = userId
        message.body = body
        message.uuid = UUID().uuidString
        message.contentType = type
        message.fakeMessage = true
        message.sendStatus = .Pending
        message.conversationId = conversationId
        message.createdAt = Date()
        message.authorType = .EndUser
        message.requestId = requestId
        return message
    }
    
}
