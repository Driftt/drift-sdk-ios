//
//  Message.swift
//  Drift
//
//  Created by Brian McDonald on 25/07/2016.
//  Copyright © 2016 Drift. All rights reserved.
//


enum ContentType: String, Codable{
    case Chat = "CHAT"
    case Annoucement = "ANNOUNCEMENT"
    case Edit = "EDIT"
    case ConversationEvent = "CONVERSATION_EVENT"
    case BotEvaluation = "BOT_NODE_CONDITION_EVALUATION"
}
enum AuthorType: String, Codable{
    case User = "USER"
    case EndUser = "END_USER"
}

enum SendStatus: String {
    case Sent = "SENT"
    case Pending = "PENDING"
    case Failed = "FAILED"
}

class Message: Equatable {
    let id: Int64?
    let uuid: String?
    let body: String?
    let attachmentIds: [Int64]
    var attachments: [Attachment] = []
    let contentType: ContentType
    let createdAt: Date
    let authorId: Int64
    let authorType: AuthorType
    
    let conversationId: Int64
    var sendStatus: SendStatus = SendStatus.Sent
    var formattedBody: NSAttributedString?
    let appointmentInformation: AppointmentInformation?

    var presentSchedule: Int64?
    let scheduleMeetingFlow: Bool
    let offerSchedule: Int64
    
    let preMessages: [PreMessage]
    let requestId: Double
    let fakeMessage: Bool
    let preMessage: Bool

    init(id: Int64? = nil,
        uuid: String?,
        body: String?,
        attachmentIds: [Int64] = [],
        contentType:ContentType,
        createdAt: Date,
        authorId: Int64,
        authorType: AuthorType,
        conversationId: Int64,
        appointmentInformation: AppointmentInformation? = nil,
        presentSchedule: Int64? = nil,
        scheduleMeetingFlow: Bool = false,
        offerSchedule: Int64 = -1,
        preMessages: [PreMessage] = [],
        requestId: Double = 0,
        fakeMessage: Bool = false,
        preMessage: Bool = false) {
        
        self.id = id
        self.uuid = uuid
        self.body = body
        self.attachmentIds = attachmentIds
        self.contentType = contentType
        self.createdAt = createdAt
        self.authorId = authorId
        self.authorType = authorType
        self.conversationId = conversationId
        self.appointmentInformation = appointmentInformation
        self.presentSchedule = presentSchedule
        self.scheduleMeetingFlow = scheduleMeetingFlow
        self.offerSchedule = offerSchedule
        self.preMessages = preMessages
        self.requestId = requestId
        self.fakeMessage = fakeMessage
        self.preMessage = preMessage
    }
    
    func formatHTMLBody() {
        if formattedBody == nil {
            formattedBody = TextHelper.attributedTextForString(text: body ?? "")
        }
    }
}

class MessageDTO: Codable, DTO {
    typealias DataObject = Message
    
    var id: Int64?
    var uuid: String?
    var body: String?
    var attachmentIds: [Int64]?
    var contentType:ContentType?
    var createdAt: Date?
    var authorId: Int64?
    var authorType: AuthorType?
    
    var conversationId: Int64?
    
    var attributes: MessageAttributesDTO?
        
    func mapToObject() -> Message? {
        
        guard let contentType = contentType,
            let id = id,
            let authorType = authorType,
            let conversationId = conversationId else { return nil }
        
        return Message(id: id,
                       uuid: uuid,
                       body: body,
                       attachmentIds: attachmentIds ?? [],
                       contentType: contentType,
                       createdAt: createdAt ?? Date(),
                       authorId: authorId ?? -1,
                       authorType: authorType,
                       conversationId: conversationId,
                       appointmentInformation: attributes?.appointmentInformation?.mapToObject(),
                       presentSchedule: attributes?.presentSchedule,
                       scheduleMeetingFlow: attributes?.scheduleMeetingFlow ?? false,
                       offerSchedule: attributes?.offerSchedule ?? -1,
                       preMessages: attributes?.preMessages?.compactMap({$0.mapToObject()}) ?? [])
    }
    
    enum CodingKeys: String, CodingKey {
        case id             = "id"
        case uuid           = "uuid"
        case body           = "body"
        case attachmentIds  = "attachments"
        case contentType    = "contentType"
        case createdAt      = "createdAt"
        case authorId       = "authorId"
        case authorType     = "authorType"
        case conversationId = "conversationId"
        case attributes     = "attributes"
    }
}

class MessageAttributesDTO: Codable{
    var appointmentInformation: AppointmentInformationDTO?
    var presentSchedule: Int64?
    var scheduleMeetingFlow: Bool?
    var offerSchedule: Int64?
    var preMessages: [PreMessageDTO]?
    
    enum CodingKeys: String, CodingKey {
        case appointmentInformation     = "appointmentInfo"
        case presentSchedule            = "presentSchedule"
        case scheduleMeetingFlow        = "scheduleMeetingFlow"
        case offerSchedule              = "offerSchedule"
        case preMessages                = "preMessages"
    }
}

extension Array where Iterator.Element == Message
{
    
    func sortMessagesForConversation() -> Array<Message> {
        
        var output:[Message] = []
        
        let sorted = self.sorted(by: { $0.createdAt.compare($1.createdAt) == .orderedAscending})
        
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
        
        return output.sorted(by: { $0.createdAt.compare($1.createdAt) == .orderedDescending})
    }
    
    private func getMessagesFromPreMessages(message: Message, preMessages: [PreMessage]) -> [Message] {
        
        let date = message.createdAt
        var output: [Message] = []
        for (index, preMessage) in preMessages.enumerated() {
            
            if let authorId = preMessage.user?.userId {
                
                let fakeMessage = Message(uuid: UUID().uuidString,
                                          body: preMessage.messageBody,
                                          contentType: .Chat,
                                          createdAt: date.addingTimeInterval(TimeInterval(-(index + 1))),
                                          authorId: authorId,
                                          authorType: .User,
                                          conversationId: message.conversationId,
                                          fakeMessage: true,
                                          preMessage: true)
                
                output.append(fakeMessage)
            }
        }
        
        return output
    }
    
}


func ==(lhs: Message, rhs: Message) -> Bool {
    return lhs.uuid == rhs.uuid
}

