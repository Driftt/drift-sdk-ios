//
//  PresentationManager.swift
//  Drift
//
//  Created by Eoin O'Connell on 26/01/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import UIKit

protocol PresentationManagerDelegate:class {
    func messageViewDidFinish(_ view: CampaignView)
}

///Responsible for showing a campaign
class PresentationManager: PresentationManagerDelegate {
    
    static var sharedInstance: PresentationManager = PresentationManager()
    weak var currentShownView: CampaignView?
    private var shouldShowMessagePopup = true
    
    init () {}

    func shouldShowMessagePopup(show: Bool) {
           shouldShowMessagePopup = show
    }
        
    func didRecieveNewMessages(_ enrichedConversations: [EnrichedConversation]) {
        guard shouldShowMessagePopup else { return }
        if let newMessageView = NewMessageView.drift_fromNib() as? NewMessageView , currentShownView == nil && !conversationIsPresenting() && !enrichedConversations.isEmpty{
            
            if let window = UIApplication.shared.keyWindow {
                currentShownView = newMessageView
                
                if let currentConversation = enrichedConversations.first, let lastMessage = currentConversation.lastMessage {
                    let otherConversations = enrichedConversations.filter({ $0.conversation.id != currentConversation.conversation.id })
                    newMessageView.otherConversations = otherConversations
                    newMessageView.message = lastMessage
                    newMessageView.delegate = self
                    newMessageView.showOnWindow(window)
                }
            }
        }
    }
    
    func didRecieveNewMessage(_ message: Message) {
        guard shouldShowMessagePopup else { return }
        if let newMessageView = NewMessageView.drift_fromNib() as? NewMessageView , currentShownView == nil && !conversationIsPresenting() {
            
            if let window = UIApplication.shared.keyWindow {
                currentShownView = newMessageView
                newMessageView.message = message
                newMessageView.delegate = self
                newMessageView.showOnWindow(window)
            }
        }
    }
        
    func conversationIsPresenting() -> Bool{
        if let topVC = TopController.viewController() , topVC.classForCoder == ConversationListViewController.classForCoder() || topVC.classForCoder == ConversationViewController.classForCoder(){
            return true
        }
        return false
    }
    
    func showConversationList(endUserId: Int64?){
        let conversationListController = ConversationListViewController.navigationController(endUserId: endUserId)
        TopController.viewController()?.present(conversationListController, animated: true, completion: nil)
    }
    
    func showConversationVC(_ conversationId: Int64) {
        if let topVC = TopController.viewController()  {
            let navVC = ConversationViewController.navigationController(ConversationViewController.ConversationType.continueConversation(conversationId: conversationId))
            topVC.present(navVC, animated: true, completion: nil)
        }
    }
    
    func showNewConversationVC(initialMessage: String? = nil) {
        if let topVC = TopController.viewController()  {
            let navVC = ConversationViewController.navigationController(ConversationViewController.ConversationType.createConversation, initialMessage: initialMessage)
            topVC.present(navVC, animated: true)
        }
    }
    
    ///Presentation Delegate
        
    func messageViewDidFinish(_ view: CampaignView) {
        view.hideFromWindow()
        currentShownView = nil
    }
    
}







