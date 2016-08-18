//
//  ErrorManager.swift
//  Drift
//
//  Created by Eoin O'Connell on 23/02/2016.
//  Copyright © 2016 Drift. All rights reserved.
//


enum DriftError: ErrorType {
    case APIFailure
    case AuthFailure
    case EmbedFailure
    case DataCreationFailure
}


class LoggerManager {
    
    class func didRecieveError(error: ErrorType) {
        if DriftManager.sharedInstance.debug {
            print(error)
        }
    }
    
    class func log(text: String) {
        if DriftManager.sharedInstance.debug {
            print("🚀🚀\(text)🚀🚀")
        }
    }
}