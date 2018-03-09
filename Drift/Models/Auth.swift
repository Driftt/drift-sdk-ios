//
//  Auth.swift
//  Drift
//
//  Created by Eoin O'Connell on 29/01/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import UIKit
import ObjectMapper

struct Auth: Mappable {
    
    var accessToken: String!
    var enduser: User?
    
    init?(map: Map) {
        let stringAccessToken = map["accessToken"] as? String
        
        //These fields are required, without them we fail to init the object
        if stringAccessToken == nil || stringAccessToken?.count == 0 {
            return nil
        }
    }
    
    mutating func mapping(map: Map) {
        accessToken <- map["accessToken"]
        enduser     <- map["endUser"]
    }
    
}
