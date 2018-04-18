//
//  PreMessage.swift
//  Drift-SDK
//
//  Created by Eoin O'Connell on 01/02/2018.
//  Copyright © 2018 Drift. All rights reserved.
//

import UIKit
import ObjectMapper

class PreMessage: Mappable {
    
    var messageBody: String = ""
    var user: User?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        messageBody     <- map["body"]
        user            <- map["sender"]
    }
}
