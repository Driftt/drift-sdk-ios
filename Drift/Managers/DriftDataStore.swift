//
//  DriftDataStore.swift
//  Drift
//
//  Created by Eoin O'Connell on 28/01/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import UIKit
import ObjectMapper

///Datastore for caching Embed and Auth object between app opens
class DriftDataStore {

    static let driftAuthCacheString = "DriftAuthDataJSONCache"
    static let driftEmbedCacheString = "DriftEmbedJSONCache"
    
    private (set) var auth: Auth?
    private (set) var embed: Embed?
    
    static var sharedInstance: DriftDataStore = {
        let store = DriftDataStore()
        store.loadData()
        return store
    }()
    
    func setAuth(auth: Auth) {
        self.auth = auth
        saveData()
    }
    
    func setEmbed(embed: Embed) {
        self.embed = embed
        saveData()
    }

    
    func loadData(){
        
        let userDefs = NSUserDefaults.standardUserDefaults()
        
        if let data = userDefs.stringForKey(DriftDataStore.driftAuthCacheString), json = convertStringToDictionary(data) {
            let tempAuth = Auth(JSON: json)
            if let auth =  tempAuth{
                self.auth = auth
            }else{
                LoggerManager.log("Failed to load auth")
            }
        }
        
        if let data = userDefs.stringForKey(DriftDataStore.driftEmbedCacheString), json = convertStringToDictionary(data) {
            let tempEmbed = Mapper<Embed>().map(json)
            
            if let embed = tempEmbed {
                self.embed = embed
            }else{
                LoggerManager.log("Failed to load embed")
            }
        }
    }
    
    func saveData(){
        let userDefs = NSUserDefaults.standardUserDefaults()
        
        if let embed = embed, json = convertDictionaryToString(embed.toJSON()) {
            userDefs.setObject(json, forKey: DriftDataStore.driftEmbedCacheString)
        }else{
            LoggerManager.log("Failed to save embed")
        }
        
        if let auth = auth, json = convertDictionaryToString( auth.toJSON()) {
            userDefs.setObject(json, forKey: DriftDataStore.driftAuthCacheString)
        }
        
        userDefs.synchronize()
        
        DriftDataStore.sharedInstance = self
    }
    
    func removeData(){
        let userDefs = NSUserDefaults.standardUserDefaults()
        userDefs.removeObjectForKey(DriftDataStore.driftAuthCacheString)
        userDefs.removeObjectForKey(DriftDataStore.driftEmbedCacheString)
        userDefs.synchronize()
        auth = nil
        embed = nil
    }
    
    
    ///Converts string to JSON - Used in loading from cache
    private func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject]
            } catch let error as NSError {
                LoggerManager.didRecieveError(error)
            }
        }
        return nil
    }
    
    ///Converst JSON to string for caching in NSUserDefaults
    private func convertDictionaryToString(json: [String: AnyObject]) -> String? {
        
        if NSJSONSerialization.isValidJSONObject(json) {
        
            do {
                let jsonData = try NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
                return String(data: jsonData, encoding: NSUTF8StringEncoding)
            } catch let error as NSError {
                LoggerManager.didRecieveError(error)
            }
        }
        return nil
    }
}

extension DriftDataStore{
    
    func generateBackgroundColor() -> UIColor {
        if let backgroundColor = embed?.backgroundColor {
            return UIColor(hexString: backgroundColor)
        }
        return UIColor(red:0.54, green:0.4, blue:1, alpha:1)
    }
    
    func generateForegroundColor() -> UIColor {
        if let foregroundColor = embed?.foregroundColor {
            return UIColor(hexString: foregroundColor)
        }
        return UIColor(red:0.54, green:0.4, blue:1, alpha:1)
    }
    
    static let primaryFontColor = UIColor(red:0.20, green:0.20, blue:0.20, alpha:1.00)
    static let secondaryFontColor = UIColor(red:0.60, green:0.60, blue:0.60, alpha:1.00)
    
}
