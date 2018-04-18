//
//  Message.swift
//  Drift
//
//  Created by Brian McDonald on 25/07/2016.
//  Copyright © 2016 Drift. All rights reserved.
//


import ObjectMapper

enum ContentType: String{
    case Chat = "CHAT"
    case Annoucement = "ANNOUNCEMENT"
    case Edit = "EDIT"
}
enum AuthorType: String{
    case User = "USER"
    case EndUser = "END_USER"
}

enum SendStatus: String{
    case Sent = "SENT"
    case Pending = "PENDING"
    case Failed = "FAILED"
}

enum RecipientStatus: String {
    case Sent = "Sent"
    case Delivered = "Delivered"
    case Read = "Read"
}

class Message: Mappable, Equatable, Hashable{
    var id: Int!
    var uuid: String?
    var inboxId: Int!
    var body: String?
    var attachmentIds: [Int] = []
    var attachments: [Attachment] = []
    var contentType:ContentType = ContentType.Chat
    var createdAt = Date()
    var authorId: Int!
    var authorType: AuthorType!
    
    var conversationId: Int!
    var requestId: Double = 0
    var sendStatus: SendStatus = SendStatus.Sent
    var formattedBody: NSAttributedString?
    var viewerRecipientStatus: RecipientStatus?
    var appointmentInformation: AppointmentInformation?

    var presentSchedule: Int?
    var scheduleMeetingFlow: Bool = false
    var offerSchedule: Int = -1
    
    var preMessages: [PreMessage] = []
    var fakeMessage = false
    var preMessage = false
    var hashValue: Int {
        return id
    }
    
    required convenience init?(map: Map) {
        if map.JSON["contentType"] as? String == nil || ContentType(rawValue: map.JSON["contentType"] as! String) == nil{
            return nil
        }
        
        self.init()
    }
    
    func mapping(map: Map) {
        id                      <- map["id"]
        uuid                    <- map["uuid"]
        inboxId                 <- map["inboxId"]
        body                    <- map["body"]
        
        body = TextHelper.cleanString(body: body ?? "")
        
        
        attachmentIds           <- map["attachments"]
        contentType             <- (map["contentType"], EnumTransform<ContentType>())
        createdAt               <- (map["createdAt"], DriftDateTransformer())
        authorId                <- map["authorId"]
        authorType              <- map["authorType"]
        conversationId          <- map["conversationId"]
        viewerRecipientStatus   <- map["viewerRecipientStatus"]
        appointmentInformation  <- map["attributes.appointmentInfo"]
        preMessages             <- map["attributes.preMessages"]
        presentSchedule         <- map["attributes.presentSchedule"]
        offerSchedule           <- map["attributes.offerSchedule"]
        scheduleMeetingFlow     <- map["attributes.scheduleMeetingFlow"]

        
        formattedBody = TextHelper.attributedTextForString(text: body ?? "")

    }

}

extension Array where Iterator.Element == Message
{
    
    mutating func sortMessagesForConversation() -> Array {
        
        var output:[Message] = []
        
        let sorted = self.sorted(by: { $0.createdAt.compare($1.createdAt as Date) == .orderedAscending})
        
        for message in sorted {
            
            if message.preMessage {
                //Ignore pre messages, we will recreate them
                continue
            }
            
            if !message.preMessages.isEmpty {
                output.append(contentsOf: getMessagesFromPreMessages(message: message, preMessages: message.preMessages))
            }
            
            if message.offerSchedule != -1 {
                continue
            }
            
            if let _ = message.appointmentInformation {
                //Go backwards and remove the most recent message asking for an apointment
                
                output = output.map({
                    
                    if let _ = $0.presentSchedule {
                        $0.presentSchedule = nil
                    }
                    return $0
                })
                
            }
            
            output.append(message)
        }
        
        return output.sorted(by: { $0.createdAt.compare($1.createdAt as Date) == .orderedDescending})
    }
    
    private func getMessagesFromPreMessages(message: Message, preMessages: [PreMessage]) -> [Message] {
        
        let date = message.createdAt
        var output: [Message] = []
        for (index, preMessage) in preMessages.enumerated() {
            let fakeMessage = Message()
            
            fakeMessage.createdAt = date.addingTimeInterval(TimeInterval(-(index + 1)))
            fakeMessage.conversationId = message.conversationId
            fakeMessage.body = TextHelper.cleanString(body: preMessage.messageBody)
            fakeMessage.formattedBody = TextHelper.attributedTextForString(text: fakeMessage.body ?? "")
            fakeMessage.fakeMessage = true
            fakeMessage.preMessage = true
            fakeMessage.uuid = UUID().uuidString
            
            fakeMessage.sendStatus = .Sent
            fakeMessage.contentType = ContentType.Chat
            fakeMessage.authorType = AuthorType.User
            
            if let sender = preMessage.user {
                fakeMessage.authorId = sender.userId
                output.append(fakeMessage)
            }
        }
        
        return output
    }
    
}


func ==(lhs: Message, rhs: Message) -> Bool {
    return lhs.uuid == rhs.uuid
}

