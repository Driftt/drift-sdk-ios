//
//  DriftDateFormatter.swift
//  Conversations
//
//  Created by Brian McDonald on 16/05/2016.
//  Copyright © 2016 Drift. All rights reserved.
//


public class DriftDateFormatter: NSDateFormatter {
    
    public func createdAtStringFromDate(date: NSDate) -> String{
        dateFormat = "HH:mm"
        timeStyle = .ShortStyle
        return stringFromDate(date)
    }
    
    public func updatedAtStringFromDate(date: NSDate) -> String{
        let now = NSDate()
        if NSCalendar.currentCalendar().component(.Day, fromDate: date) != NSCalendar.currentCalendar().component(.Day, fromDate: now){
            dateStyle = .ShortStyle
        }else{
            dateFormat = "H:mm a"
        }
        return stringFromDate(date)
    }
    
    public func headerStringFromDate(date: NSDate) -> String{
        let now = NSDate()
        if NSCalendar.currentCalendar().component(.Day, fromDate: date) != NSCalendar.currentCalendar().component(.Day, fromDate: now){
            dateFormat = "MMMM d"
        }else{
            return "Today"
        }
        return stringFromDate(date)
    }
    
}
