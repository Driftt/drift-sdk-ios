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
    var directoryURL = NSURL()
    ///Used to store register data while we wait for embed to finish in case where register and embed is called together
    var registerInfo: (userId: String, email: String, attrs: [String: AnyObject]?)?

    
    private override init(){
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DriftManager.didEnterForeground), name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    class func createTemporaryDirectory(){
        sharedInstance.directoryURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(NSProcessInfo.processInfo().globallyUniqueString, isDirectory: true) as NSURL
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(sharedInstance.directoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            sharedInstance.directoryURL = NSURL(fileURLWithPath: NSTemporaryDirectory())
        }
    }
    
    ///Call Embeds API if needed
    class func retrieveDataFromEmbeds(embedId: String) {
        
        if let pastEmbedId = DriftDataStore.sharedInstance.embed?.embedId {
            //New Embed Account - Logout and continue to get new
            if pastEmbedId != embedId {
                Drift.logout()
            }
        }
        
        //New User - First Time Launch
        getEmbedData(embedId) { (success) in
            if let registerInfo = DriftManager.sharedInstance.registerInfo where success {
                DriftManager.registerUser(registerInfo.userId, email: registerInfo.email, attrs: registerInfo.attrs)
                DriftManager.sharedInstance.registerInfo = nil
            }
        }
    }
    
    class func debugMode(debug:Bool){
        sharedInstance.debug = debug
    }
    
    class func showConversations(){
        PresentationManager.sharedInstance.showConversationList()
    }
    
    /**
     Gets Auth for user - Calls Identify if new user
    */
    class func registerUser(userId: String, email: String, attrs: [String: AnyObject]? = nil){
        
        guard let orgId = DriftDataStore.sharedInstance.embed?.orgId else {
            LoggerManager.log("No Embed, not registering user - Waiting for Embeds to complete")
            DriftManager.sharedInstance.registerInfo = (userId,email, attrs)
            return
        }
        
        if let auth = DriftDataStore.sharedInstance.auth {
            
            if let _ = auth.enduser {
                
                getAuth(email, userId: userId) { (success) in
                    if success {
                        self.initializeLayer(userId)
                    }
                }
            }else{
                ///No Users. lets Auth
                getAuth(email, userId: userId) { (success) in
                    if success {
                        self.initializeLayer(userId)
                    }
                }
            }
            
        }else{
            ///New User
            //Call Identify
            //Call Auth
            
            APIManager.postIdentify(orgId, userId: userId, email: email, attributes: nil) { (result) -> () in }
            getAuth(email, userId: userId) { (success) in
                if success {
                    self.initializeLayer(userId)
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
    class func getAuth(email: String, userId: String, completion: (success: Bool) -> ()) {
        
        if let orgId = DriftDataStore.sharedInstance.embed?.orgId, clientId = DriftDataStore.sharedInstance.embed?.clientId, redirURI = DriftDataStore.sharedInstance.embed?.redirectUri {
            APIManager.getAuth(email, userId: userId, redirectURL: redirURI, orgId: orgId, clientId: clientId, completion: { (result) -> () in
                switch result {
                case .Success(let auth):
                    DriftDataStore.sharedInstance.setAuth(auth)
                    completion(success: true)
                case .Failure(let error):
                    LoggerManager.log("Failed to get Auth: \(error)")
                    completion(success: false)
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
        if let user = DriftDataStore.sharedInstance.auth?.enduser, orgId = user.orgId, userId = user.externalId, email = user.email {
            APIManager.postIdentify(orgId, userId: userId, email: email, attributes: nil) { (result) -> () in }

        }else{
            LoggerManager.log("No End user to post identify for")
        }
    }
    
    /**
     Once we have a userId from Auth - Start Layer Auth Handoff to Layer Manager
    */
    private class func initializeLayer(userId: String) {

        if let appId = DriftDataStore.sharedInstance.embed?.layerAppId, userId = DriftDataStore.sharedInstance.auth?.enduser?.userId {
            LayerManager.initialize(appId, userId: userId) { (success) in
                if success {
                    do {
                        try CampaignsManager.checkForCampaigns()
                    } catch {
                        LoggerManager.log("Announcements Error")
                    }
                }
            }
        }
    }
    
    class func getEmbedData(embedId: String, completion: (success: Bool) -> ()){
        let refresh = DriftDataStore.sharedInstance.embed?.refreshRate
        APIManager.getEmbeds(embedId, refreshRate: refresh) { (result) -> () in
            
            switch result {
            case .Success(let embed):
                LoggerManager.log("Updated Embed Id")
                DriftDataStore.sharedInstance.setEmbed(embed)
                completion(success: true)
            case .Failure(let error):
                print(error)
                completion(success: false)
            }
        }
    }
}

///Convenience Extension to dismiss a MFMailComposeViewController - Used as views will not stay in window and delegate would become nil
extension DriftManager: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
