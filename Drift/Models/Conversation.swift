//
//  Conversation.swift
//  Drift
//
//  Created by Brian McDonald on 25/07/2016.
//  Copyright © 2016 Drift. All rights reserved.
//


enum ConversationStatus: String, Codable {
    case Open = "OPEN"
    case Closed = "CLOSED"
    case Pending = "PENDING"
    case BulkSent = "BULK_SENT"
}

struct Conversation {
    let id: Int64
    let status: ConversationStatus?
    let preview: String?
    let updatedAt: Date
    let type: String?
}

class ConversationDTO: DTO, Codable {
    typealias DataObject = Conversation
    
    var id: Int64?
    var status: ConversationStatus?
    var preview: String?
    var updatedAt: Date?
    let type: String?
        
    enum CodingKeys: String, CodingKey {
        case id         = "id"
        case preview    = "preview"
        case updatedAt  = "updatedAt"
        case status     = "status"
        case type       = "type"
    }

    func mapToObject() -> Conversation? {
        
        guard let id = id else { return nil }
        
        return Conversation(id: id,
                            status: status,
                            preview: preview,
                            updatedAt: updatedAt ?? Date(),
                            type: type)
    }
    
    
}
