//
//  File.swift
//  Driftt
//
//  Created by Eoin O'Connell on 21/01/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import Foundation

@objc
public class Drift: NSObject {

    
    /**
     Initialise Driftt SDK with an embed ID.
     
     - Parameter embedId: Embed ID found in Driftt Settings
     
    */
    public class func setup(embedId: String) {
        DriftManager.retrieveDataFromEmbeds(embedId)
        DriftManager.createTemporaryDirectory()
    }
    
    /**
     Registers Users with drift. Should be completed after user login
    
     - Parameter userId: The User id from your database. Will be the same as on driftt.
     
    */
    public class func registerUser(userId: String, email: String) {
        DriftManager.registerUser(userId, email: email, attrs: nil)
    }
    
    /**
     Logs users out of Drift
     */
    public class func logout() {
        LayerManager.logout()
        DriftManager.logout()
    }
    
    
    /**

     This mode enables you to see the output logs of drift for debug purposes
     This will also stop dismissing announcements from being sticky so you can see the same announcement over and over
     
     - parameter debug: A Bool indicating if debug mode should be enabled or not
     
    */
    public class func debugMode(debug:Bool) {
        DriftManager.debugMode(debug)
    }
    
    /**

     This will show a list of Drift conversations for the current user
     
     */
    public class func showConversations() {
        DriftManager.showConversations()
    }
    
}