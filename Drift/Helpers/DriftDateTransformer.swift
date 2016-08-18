//
//  DriftDateTransformer.swift
//  Conversations
//
//  Created by Brian McDonald on 16/05/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import ObjectMapper

public class DriftDateTransformer: TransformType{
    public typealias Object = NSDate
    public typealias JSON = Double
    
    public init() {}
    
    public func transformFromJSON(value: AnyObject?) -> NSDate? {
        if let timeInt = value as? Double {
            return NSDate(timeIntervalSince1970: NSTimeInterval(timeInt/1000))
        }
        
        if let timeStr = value as? String {
            return NSDate(timeIntervalSince1970: NSTimeInterval(atof(timeStr)/1000))
        }
        
        return nil
    }
    
    public func transformToJSON(value: NSDate?) -> Double? {
        if let date = value {
            return Double(date.timeIntervalSince1970*1000)
        }
        return nil
    }
    
}
