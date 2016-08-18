//
//  InboxManager.swift
//  Drift
//
//  Created by Brian McDonald on 25/07/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import ObjectMapper

class InboxManager {
    static let sharedInstance: InboxManager = InboxManager()
    let pageSize = 30
    
    var conversationSubscriptions: [ConversationSubscription] = []
    var messageSubscriptions: [MessageSubscription] = []
    
    func hasSubscriptionForConversationId(conversationId: Int) -> Bool {
        let matchingSub = messageSubscriptions.filter({$0.conversationId == conversationId && $0.delegate != nil})
        return !matchingSub.isEmpty
    }
    
    
    func getConversations(endUserId: Int, completion:(conversations: [Conversation]?) -> ()){
        
        
        guard let auth = DriftDataStore.sharedInstance.auth?.accessToken else {
            LoggerManager.log("No Auth Token for Recording")
            return
        }
        
        APIManager.getConversations(endUserId, authToken: auth) { (result) in
            switch result{
            case .Success(let conversations):
                completion(conversations: conversations)
            case .Failure:
                LoggerManager.log("Unable to retreive conversations for endUserId: \(endUserId)")
                completion(conversations: nil)
            }
        }
    }
    
    func getMessages(conversationId: Int, completion:(messages: [Message]?) -> ()){

        
        guard let auth = DriftDataStore.sharedInstance.auth?.accessToken else {
            LoggerManager.log("No Auth Token for Recording")
            return
        }
        
        APIManager.getMessages(conversationId, authToken: auth) { (result) in
            switch result{
            case .Success(let messages):
                completion(messages: messages)
            case .Failure:
                LoggerManager.log("Unable to retreive messages for conversationId: \(conversationId)")
                completion(messages: nil)
            }
        }
    }
    
    func postMessage(message: Message, conversationId: Int, completion:(message: Message?, requestId: Double) -> ()){
        

        guard let auth = DriftDataStore.sharedInstance.auth?.accessToken else {
            LoggerManager.log("No Auth Token for Recording")
            return
        }
        
        APIManager.postMessage(conversationId, message: message, authToken: auth) { (result) in
            switch result{
            case .Success(let returnedMessage):
                completion(message: returnedMessage, requestId: message.requestId)
            case .Failure:
                LoggerManager.log("Unable to post message for conversationId: \(conversationId)")
                completion(message: nil, requestId: message.requestId)
            }
        }
    }
    
    
    func createConversation(message: Message, authorId: Int?, completion:(message: Message?, requestId: Double) -> ()){
        
        
        guard let auth = DriftDataStore.sharedInstance.auth?.accessToken else {
            LoggerManager.log("No Auth Token for Recording")
            return
        }
        
        APIManager.createConversation(message.body ?? "", authorId: authorId, authToken: auth) { (result) in
            switch result{
            case .Success(let returnedMessage):
                completion(message: returnedMessage, requestId: message.requestId)
            case .Failure:
                LoggerManager.log("Unable to create conversation")
                completion(message: nil, requestId: message.requestId)
            }
        }
    }
    
    //Create subscriptions for objects
    func addConversationSubscription(subscription: ConversationSubscription){
        self.conversationSubscriptions.append(subscription)
    }
    
    func addMessageSubscription(subscription: MessageSubscription){
        self.messageSubscriptions.append(subscription)
    }

    //Alert delegates of updated to Conversations
    func conversationsDidUpdate(inboxId: Int, conversations: [Conversation]){
        for conversationSubscription in conversationSubscriptions{
            conversationSubscription.delegate?.conversationsDidUpdate(conversations)
        }
    }
    
    func conversationDidUpdate(conversation: Conversation){
        for conversationSubscription in conversationSubscriptions{
            conversationSubscription.delegate?.conversationDidUpdate(conversation)
        }
    }
    
    //Alert delegates of updates to messages
    func messagesDidUpdate(conversationId: Int, messages: [Message]){
        for messageSubscription in messageSubscriptions{
            if messageSubscription.conversationId == conversationId{
                messageSubscription.delegate?.messagesDidUpdate(messages)
            }
        }
    }
    
    func messageDidUpdate(message: Message){
        for messageSubscription in messageSubscriptions{
            if messageSubscription.conversationId == message.conversationId{
                messageSubscription.delegate?.newMessage(message)
            }
        }
    }
    
}

