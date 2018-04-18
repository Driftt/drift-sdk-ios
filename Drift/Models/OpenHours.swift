//
//  OpenHours.swift
//  Drift
//
//  Created by Eoin O'Connell on 19/01/2017.
//  Copyright © 2017 Drift. All rights reserved.
//

import ObjectMapper

class OpenHours: Mappable {

    enum Weekday: String{
        case monday     = "MONDAY"
        case tuesday    = "TUESDAY"
        case wednesday  = "WEDNESDAY"
        case thursday   = "THURSDAY"
        case friday     = "FRIDAY"
        case saturday   = "SATURDAY"
        case sunday     = "SUNDAY"
        case everyday   = "EVERYDAY"
        case weekdays   = "WEEKDAYS"
        case weekends   = "WEEKENDS"
        
        func includesDay(weekdayInt: Int) -> Bool{
         
            switch self {
            case .monday where weekdayInt == 2:
                return true
            case .tuesday where weekdayInt == 3:
                return true
            case .wednesday where weekdayInt == 4:
                return true
            case .thursday where weekdayInt == 5:
                return true
            case .friday where weekdayInt == 6:
                return true
            case .saturday where weekdayInt == 7:
                return true
            case .sunday where weekdayInt == 1:
                return true
            case .everyday where (1...7).contains(weekdayInt):
               return true
            case .weekdays where (2...6).contains(weekdayInt):
                return true
            case .weekends where weekdayInt == 7 || weekdayInt == 1:
                return true
            default:
                return false
            }
        }
    }
    
    var opens:     String?
    var closes:    String?
    var dayOfWeek: String?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        opens           <- map["opens"]
        closes          <- map["closes"]
        dayOfWeek       <- map["dayOfWeek"]
    }
    
    
    func populateTimeForTimezone(timezone: TimeZone) -> (open: Date?, close: Date?) {
    
        let result: (open: Date?, close: Date?)

        if let openHours = opens {
            result.open = OpenHoursHelpers.convertStringForDate(dateString: openHours, timezone: timezone)
        }else{
            result.open = nil
        }
        
        if let closeHours = closes {
            result.close = OpenHoursHelpers.convertStringForDate(dateString: closeHours, timezone: timezone)
        }else{
            result.close = nil
        }
        
        
        return result
    }
    
    func weekday() -> Weekday? {
        return Weekday(rawValue: dayOfWeek ?? "")
    }
    
}

extension Sequence where Iterator.Element : OpenHours {
    
    func areWeCurrentlyOpen(date : Date, timeZone: TimeZone) -> Bool {
        for openHour in self {

            let currentWeekdayInTimeZone = OpenHoursHelpers.getWeekDayFromDate(date: date, timezone: timeZone)
            
            if let weekday = openHour.weekday() {
                if (weekday.includesDay(weekdayInt: currentWeekdayInTimeZone)) {
                    let population = openHour.populateTimeForTimezone(timezone: timeZone)
                    
                    if let openTime = population.open, let closedTime = population.close{
                        if (date.isAfter(openTime) && date.isBefore(closedTime)){
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
}


extension Date {
    func isBefore(_ date: Date) -> Bool {
        return self.timeIntervalSince1970 < date.timeIntervalSince1970
    }
    
    func isAfter(_ date: Date) -> Bool {
        return self.timeIntervalSince1970 > date.timeIntervalSince1970
    }
}
