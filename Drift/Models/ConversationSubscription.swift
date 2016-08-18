//
//  ConversationSubscription.swift
//  Drift
//
//  Created by Brian McDonald on 25/07/2016.
//  Copyright © 2016 Drift. All rights reserved.
//


public protocol ConversationDelegate: class{
    func conversationsDidUpdate(conversations: [Conversation])
    func conversationDidUpdate(conversation: Conversation)
}

public class ConversationSubscription {
    
    public convenience init(delegate: ConversationDelegate) {
        self.init()
        self.delegate = delegate
    }
    
    weak var delegate: ConversationDelegate?
}

