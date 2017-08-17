//
//  DriftManager.swift
//  Drift
//
//  Created by Eoin O'Connell on 22/01/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import Foundation
import MessageUI

class DriftManager: NSObject {
    
    static var sharedInstance: DriftManager = DriftManager()
    var debug: Bool = false
    var directoryURL: URL?
    ///Used to store register data while we wait for embed to finish in case where register and embed is called together
    private var registerInfo: (userId: String, email: String, attrs: [String: AnyObject]?)?

    fileprivate override init(){
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(DriftManager.didEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    class func createTemporaryDirectory(){
        sharedInstance.directoryURL =  URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)
        do {
            if let directoryURL = sharedInstance.directoryURL{
                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            sharedInstance.directoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
        }
    }
    
    ///Call Embeds API if needed
    class func retrieveDataFromEmbeds(_ embedId: String, completion: ((Bool)->())? = nil) {
        if let pastEmbedId = DriftDataStore.sharedInstance.embed?.embedId {
            //New Embed Account - Logout and continue to get new data
            if pastEmbedId != embedId {
                Drift.logout()
            }
        }
        
        getEmbedData(embedId) { (success) in
            //If we have pending register data go in register flow - If register called before embeds is complete
            if let registerInfo = DriftManager.sharedInstance.registerInfo , success {
                DriftManager.registerUser(registerInfo.userId, email: registerInfo.email, attrs: registerInfo.attrs, completion: { userId in
                    if userId != nil{
                        completion?(success)
                        return
                    }
                    completion?(false)
                })
            }
        }
    }
    
    class func debugMode(_ debug:Bool){
        sharedInstance.debug = debug
    }
    
    /**
     Gets Auth for user - Calls Identify if new user
    */
    class func registerUser(_ userId: String, email: String, attrs: [String: AnyObject]? = nil, completion: ((Int?)->())? = nil){
        DriftDataStore.sharedInstance.setUserId(userId)
        DriftDataStore.sharedInstance.setEmail(email)
        
        guard let orgId = DriftDataStore.sharedInstance.embed?.orgId else {
            LoggerManager.log("No Embed, not registering user - Waiting for Embeds to complete")
            DriftManager.sharedInstance.registerInfo = (userId, email, attrs)
            return
        }
        
        DriftManager.sharedInstance.registerInfo = nil
    
        DriftAPIManager.postIdentify(orgId, userId: userId, email: email, attributes: nil) { (result) -> () in
            getAuth(email, userId: userId) { (auth) in
                if let auth = auth {
                    self.setupSocket(auth.accessToken)
                    
                    if let userId = auth.enduser?.userId {
                        ConversationsManager.checkForConversations(userId: userId)
                        CampaignsManager.checkForCampaigns(userId: userId)
                        completion?(userId)
                    }
                }
            }
        }
    }
    
    /**
     Delete Data Store
     */
    class func logout(){
        DriftDataStore.sharedInstance.removeData()
    }
    
    /**
     Calls Auth and caches
     - parameter email: Users email
     - parameter userId: User Id from app data base
     - returns: completion with success bool
    */
    class func getAuth(_ email: String, userId: String, completion: @escaping (_ success: Auth?) -> ()) {
        
        if let orgId = DriftDataStore.sharedInstance.embed?.orgId, let clientId = DriftDataStore.sharedInstance.embed?.clientId, let redirURI = DriftDataStore.sharedInstance.embed?.redirectUri {
            DriftAPIManager.getAuth(email, userId: userId, redirectURL: redirURI, orgId: orgId, clientId: clientId, completion: { (result) -> () in
                switch result {
                case .success(let auth):
                    DriftDataStore.sharedInstance.setAuth(auth)
                    completion(auth)
                case .failure(let error):
                    LoggerManager.log("Failed to get Auth: \(error)")
                    completion(nil)
                }
            })
        }else{
            LoggerManager.log("Not enough data to get Auth")
        }
    }
    
    /**
        Called when app is opened from background - Refresh Identify if logged in
    */
    func didEnterForeground(){
        if let user = DriftDataStore.sharedInstance.auth?.enduser, let orgId = user.orgId, let userId = user.externalId, let email = user.email {
            DriftAPIManager.postIdentify(orgId, userId: userId, email: email, attributes: nil) { (result) -> () in }
            
            if let userId = user.userId {
                ConversationsManager.checkForConversations(userId: userId)
                CampaignsManager.checkForCampaigns(userId: userId)
            }
        }else{
            if let embedId = DriftDataStore.sharedInstance.embed?.embedId, let userId = DriftDataStore.sharedInstance.userId, let userEmail = DriftDataStore.sharedInstance.userEmail {
                Drift.setup(embedId)
                Drift.registerUser(userId, email: userEmail)
            }else{
                LoggerManager.log("No End user to post identify for")
            }
        }
        
        if let pastEmbedId = DriftDataStore.sharedInstance.embed?.embedId {

            DriftManager.retrieveDataFromEmbeds(pastEmbedId)

        }
        
    }
    
    /**
     Once we have a userId from Auth - Start Layer Auth Handoff to Layer Manager
    */
    fileprivate class func setupSocket(_ accessToken: String) {
        DriftAPIManager.getSocketAuth(accessToken: accessToken) { (result) in
            switch result {
            case .success(let socketAuth):
                LoggerManager.log(socketAuth.sessionToken)
                SocketManager.sharedInstance.connectToSocket(socketAuth: socketAuth)
            case .failure(let error):
                LoggerManager.log(error.localizedDescription)
            }
        }
    }
    
    class func showConversations(){
        if let endUserId = DriftDataStore.sharedInstance.auth?.enduser?.userId{
            PresentationManager.sharedInstance.showConversationList(endUserId: endUserId)
        }else{
            PresentationManager.sharedInstance.showConversationList(endUserId: nil)
            LoggerManager.log("No Auth, will present conversations vc authless")
        }
    }
    
    class func getEmbedData(_ embedId: String, completion: @escaping (_ success: Bool) -> ()){
        let refresh = DriftDataStore.sharedInstance.embed?.refreshRate
        DriftAPIManager.getEmbeds(embedId, refreshRate: refresh) { (result) -> () in
            
            switch result {
            case .success(let embed):
                LoggerManager.log("Updated Embed Id")
                DriftDataStore.sharedInstance.setEmbed(embed)
                completion(true)
            case .failure(let error):
                LoggerManager.log(error.localizedDescription)
                completion(false)
            }
        }
    }
    
}

///Convenience Extension to dismiss a MFMailComposeViewController - Used as views will not stay in window and delegate would become nil
extension DriftManager: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
}
