//
//  PresentationManager.swift
//  Drift
//
//  Created by Eoin O'Connell on 26/01/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import UIKit

protocol PresentationManagerDelegate:class {
    
    func campaignDidFinishWithResponse(view: CampaignView, campaign: Campaign, response: CampaignResponse)
    func messageViewDidFinish(view: CampaignView)
}


///Responsible for showing a campaign
class PresentationManager: PresentationManagerDelegate {
    
    static var sharedInstance: PresentationManager = PresentationManager()
    weak var currentShownView: CampaignView?
    
    init () {}
    
    func didRecieveCampaigns(campaigns: [Campaign]) {
        
        ///Show latest first
        let sortedCampaigns = campaigns.sort {
            
            if let d1 = $0.createdAt, d2 = $1.createdAt {
                return d1.compare(d2) == .OrderedAscending
            }else{
                return false
            }
        }
        
        var nextCampaigns = [Campaign]()
        
        if campaigns.count > 1 {
            nextCampaigns = Array(sortedCampaigns.dropFirst())
        }
        

        dispatch_async(dispatch_get_main_queue()) { () -> Void in
         
            if let firstCampaign = sortedCampaigns.first, type = firstCampaign.messageType  {
                
                switch type {
                    
                case .Announcement:
                    self.showAnnouncementCampaign(firstCampaign, otherCampaigns: nextCampaigns)
                case .NPS:
                    self.showNPSCampaign(firstCampaign, otherCampaigns: nextCampaigns)
                case .NPSResponse:
                    ()
                }
            }
        }
    }
    
    func didRecieveNewMessages(messages: [(conversationId: Int, messages: [Message])]) {
        
        if let newMessageView = NewMessageView.fromNib() as? NewMessageView where currentShownView == nil && !conversationIsPresenting() {
            
            if let window = UIApplication.sharedApplication().keyWindow {
                currentShownView = newMessageView
                
                let currentConversation = messages.first!
                let otherConversations = messages.filter({ $0.conversationId != currentConversation.conversationId })
                newMessageView.otherConversations = otherConversations                
                newMessageView.conversation = currentConversation
                newMessageView.delegate = self
                newMessageView.showOnWindow(window)
                
            }
        }

        
        
    }
    
    func showAnnouncementCampaign(campaign: Campaign, otherCampaigns:[Campaign]) {
        if let announcementView = AnnouncementView.fromNib() as? AnnouncementView where currentShownView == nil && !conversationIsPresenting() {
            
            if let window = UIApplication.sharedApplication().keyWindow {
                currentShownView = announcementView
                announcementView.otherCampaigns = otherCampaigns
                announcementView.campaign = campaign
                announcementView.delegate = self
                announcementView.showOnWindow(window)
                                
            }
        }
    }
    
    func showExpandedAnnouncement(campaign: Campaign) {
    
        if let announcementView = AnnouncementExpandedView.fromNib() as? AnnouncementExpandedView, window = UIApplication.sharedApplication().keyWindow where !conversationIsPresenting() {
            
            currentShownView = announcementView
            announcementView.campaign = campaign
            announcementView.delegate = self
            announcementView.showOnWindow(window)
            
        }
    }
    
    
    func showNPSCampaign(campaign: Campaign, otherCampaigns: [Campaign]) {
     
     
        if let npsContainer = NPSContainerView.fromNib() as? NPSContainerView, npsView = NPSView.fromNib() as? NPSView where currentShownView == nil && !conversationIsPresenting(){
            
            if let window = UIApplication.sharedApplication().keyWindow {
                currentShownView = npsContainer
                npsContainer.delegate = self
                npsContainer.campaign = campaign
                npsView.campaign = campaign
                npsView.otherCampaigns = otherCampaigns
                npsContainer.showOnWindow(window)
                npsContainer.popUpContainer(initialView: npsView)
            }
        }else{
            LoggerManager.log("Error Loading Nib")
        }
    }
    
    func conversationIsPresenting() -> Bool{
        if let topVC = TopController.viewController() where topVC.classForCoder == ConversationListViewController.classForCoder() || topVC.classForCoder == ConversationViewController.classForCoder(){
            return true
        }
        return false
    }
    
    func showConversationList(){

        let conversationListController = ConversationListViewController.navigationController()
        TopController.viewController()?.presentViewController(conversationListController, animated: true, completion: nil)
        
    }
    
    func showConversationVC(conversationId: Int) {
        if let topVC = TopController.viewController()  {
            let navVC = ConversationViewController.navigationController(ConversationViewController.ConversationType.ContinueConversation(conversationId: conversationId))
            topVC.presentViewController(navVC, animated: true, completion: nil)
        }
    }
    
    func showNewConversationVC(authorId: Int?) {
        if let topVC = TopController.viewController()  {
            let navVC = ConversationViewController.navigationController(ConversationViewController.ConversationType.CreateConversation(authorId: authorId))
            topVC.presentViewController(navVC, animated: true, completion: nil)
        }
    }
    
    ///Presentation Delegate
    
    func campaignDidFinishWithResponse(view: CampaignView, campaign: Campaign, response: CampaignResponse) {
        view.hideFromWindow()
        currentShownView = nil
        switch response {
        case .Announcement(let announcementResponse):
            if announcementResponse == .Opened {
                self.showExpandedAnnouncement(campaign)
            }
            CampaignResponseManager.recordAnnouncementResponse(campaign, response: announcementResponse)
        case .NPS(let npsResponse):
            CampaignResponseManager.recordNPSResponse(campaign, response: npsResponse)
        }
    }
    
    func messageViewDidFinish(view: CampaignView) {
        view.hideFromWindow()
        currentShownView = nil
    }
}







