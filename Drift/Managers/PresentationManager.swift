//
//  PresentationManager.swift
//  Drift
//
//  Created by Eoin O'Connell on 26/01/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import UIKit

protocol PresentationManagerDelegate:class {
    func campaignDidFinishWithResponse(_ view: CampaignView, campaign: CampaignMessage, response: CampaignResponse)
    func messageViewDidFinish(_ view: CampaignView)
}

///Responsible for showing a campaign
class PresentationManager: PresentationManagerDelegate {
    
    static var sharedInstance: PresentationManager = PresentationManager()
    weak var currentShownView: CampaignView?
    
    init () {}
    
    func didRecieveCampaigns(_ campaigns: [CampaignMessage]) {
        ///Show latest first
        let sortedCampaigns = campaigns.sorted {
            
            if let d1 = $0.createdAt, let d2 = $1.createdAt {
                return d1.compare(d2) == .orderedAscending
            }else{
                return false
            }
        }
        
        var nextCampaigns = [CampaignMessage]()
        
        if campaigns.count > 1 {
            nextCampaigns = Array(sortedCampaigns.dropFirst())
        }
        
        DispatchQueue.main.async { () -> Void in
            if let firstCampaign = sortedCampaigns.first, let type = firstCampaign.messageType  {
                switch type {
                case .Announcement:
                    self.showAnnouncementCampaign(firstCampaign, otherCampaigns: nextCampaigns)
                }
            }
        }
    }
    
    func didRecieveNewMessages(_ enrichedConversations: [EnrichedConversation]) {
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
        if let newMessageView = NewMessageView.drift_fromNib() as? NewMessageView , currentShownView == nil && !conversationIsPresenting() {
            
            if let window = UIApplication.shared.keyWindow {
                currentShownView = newMessageView
                newMessageView.message = message
                newMessageView.delegate = self
                newMessageView.showOnWindow(window)
            }
        }
    }
    
    func showAnnouncementCampaign(_ campaign: CampaignMessage, otherCampaigns:[CampaignMessage]) {
        if let announcementView = AnnouncementView.drift_fromNib() as? AnnouncementView , currentShownView == nil && !conversationIsPresenting() {
            
            if let window = UIApplication.shared.keyWindow {
                currentShownView = announcementView
                announcementView.otherCampaigns = otherCampaigns
                announcementView.campaign = campaign
                announcementView.delegate = self
                announcementView.showOnWindow(window)
            }
        }
    }
    
    func showExpandedAnnouncement(_ campaign: CampaignMessage) {
        if let announcementView = AnnouncementExpandedView.drift_fromNib() as? AnnouncementExpandedView, let window = UIApplication.shared.keyWindow , !conversationIsPresenting() {
            currentShownView = announcementView
            announcementView.campaign = campaign
            announcementView.delegate = self
            announcementView.showOnWindow(window)
        }
    }
    
    func conversationIsPresenting() -> Bool{
        if let topVC = TopController.viewController() , topVC.classForCoder == ConversationListViewController.classForCoder() || topVC.classForCoder == ConversationViewController.classForCoder(){
            return true
        }
        return false
    }
    
    func showConversationList(endUserId: Int?){
        let conversationListController = ConversationListViewController.navigationController(endUserId: endUserId)
        TopController.viewController()?.present(conversationListController, animated: true, completion: nil)
    }
    
    func showConversationVC(_ conversationId: Int) {
        if let topVC = TopController.viewController()  {
            let navVC = ConversationViewController.navigationController(ConversationViewController.ConversationType.continueConversation(conversationId: conversationId))
            topVC.present(navVC, animated: true, completion: nil)
        }
    }
    
    func showNewConversationVC(_ authorId: Int?) {
        if let topVC = TopController.viewController()  {
            let navVC = ConversationViewController.navigationController(ConversationViewController.ConversationType.createConversation)
            topVC.present(navVC, animated: true, completion: nil)
        }
    }
    
    ///Presentation Delegate
    
    func campaignDidFinishWithResponse(_ view: CampaignView, campaign: CampaignMessage, response: CampaignResponse) {
        view.hideFromWindow()
        currentShownView = nil
        switch response {
        case .announcement(let announcementResponse):
            if announcementResponse == .Opened {
                self.showExpandedAnnouncement(campaign)
            }
            CampaignResponseManager.recordAnnouncementResponse(campaign, response: announcementResponse)
        }
    }
    
    func messageViewDidFinish(_ view: CampaignView) {
        view.hideFromWindow()
        currentShownView = nil
    }
    
}







