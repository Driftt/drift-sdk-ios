//
//  Embed.swift
//  Drift
//
//  Created by Eoin O'Connell on 22/01/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import ObjectMapper

enum WidgetStatus: String{
    case on = "ON"
    case away = "AWAY"
}

enum WidgetMode: String{
    case manual = "MANUAL"
    case auto   = "AUTO"
}

enum UserListMode: String{
    case random = "RANDOM"
    case custom   = "CUSTOM"
}

///Embed - The organisation specific data used to customise the SDK for each organization
struct Embed: Mappable {
    
    var orgId: Int!
    var embedId: String!
    var inboxId: Int!
    
    var clientId: String!
    var redirectUri: String!
    
    var backgroundColor: String?
    var foregroundColor: String?
    var welcomeMessage: String?
    var awayMessage: String?

    var organizationName: String?
    
    var inboxEmailAddress: String?
    var refreshRate: Int?
    
    var widgetStatus: WidgetStatus = .on
    
    var widgetMode: WidgetMode = .manual
    
    var openHours: [OpenHours] = []
    var timeZoneString: String?
    var backgroundColorString: String?
    var users: [User] = []
    
    var userListMode: UserListMode = .random
    var userListIds: [Int] = []
    
    
    var activeCampaigns: [Campaign] = []
    
    init?(map: Map) {
        //These fields are required, without them we fail to init the object
        if map.JSON["orgId"] == nil || map.JSON["orgId"] as? String == "" ||
            map.JSON["id"] == nil || map.JSON["id"] as? String == "" ||
            map["configuration.inboxId"].currentValue == nil || map["configuration.inboxId"].currentValue as? String == "" ||
            map["configuration.authClientId"].currentValue == nil || map["configuration.authClientId"].currentValue as? String == "" {
            return nil
        }
    }
    
    mutating func mapping(map: Map) {
        orgId               <- map["orgId"]
        embedId             <- map["id"]
        inboxId             <- map["configuration.inboxId"]
        clientId            <- map["configuration.authClientId"]
        redirectUri         <- map["configuration.redirectUri"]
        backgroundColor     <- map["configuration.theme.backgroundColor"]
        foregroundColor     <- map["configuration.theme.foregroundColor"]
        welcomeMessage      <- map["configuration.theme.welcomeMessage"]
        awayMessage         <- map["configuration.theme.awayMessage"]
        organizationName    <- map["configuration.organizationName"]
        inboxEmailAddress   <- map["configuration.inboxEmailAddress"]
        refreshRate         <- map["configuration.refreshRate"]
        
        widgetStatus         <- map["configuration.widgetStatus"]
        widgetMode           <- map["configuration.widgetMode"]
        timeZoneString          <- map["configuration.theme.timezone"]
        backgroundColorString   <- map["configuration.theme.backgroundColor"]
        openHours               <- map["configuration.theme.openHours"]
        userListMode         <- map["configuration.theme.userListMode"]
        users                    <- map["configuration.team"]
        userListIds                <- map["configuration.theme.userList"]
        
        activeCampaigns     <- map["configuration.campaigns"]
    }
    
    func isOrgCurrentlyOpen() -> Bool {
        if widgetMode == .some(.manual) {
            if widgetStatus == .some(.on) {
                return true
            }else{
                return false
            }
        }else{
            //Use open hours
            
            if let timezone = TimeZone(identifier: timeZoneString ?? "") {
                return openHours.areWeCurrentlyOpen(date: Date(), timeZone: timezone)
            }else{
                return false
            }
        }
    }
    
    func getWelcomeMessageForUser() -> String? {
        
        if let welcomeMessage = welcomeMessage,  isOrgCurrentlyOpen() {
            return welcomeMessage
        }else if let awayMessage = awayMessage {
            return awayMessage
        }
        return nil
    }
    
    func getUserForWelcomeMessage() -> User? {
        
        if userListMode == .custom, let teamMember = users.filter({userListIds.contains($0.userId ?? -1)}).first{
            return teamMember
        }else{
            if users.count > 0 {
                return users[Int(arc4random_uniform(UInt32(users.count)))]
            } else {
                return nil
            }
        }
        
    }
}
