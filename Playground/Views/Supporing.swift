//
//  Supporing.swift
//  Playground
//
//  Created by Amin Benarieb on 3/3/23.
//  Copyright © 2023 com.amin.benarieb. All rights reserved.
//

import Foundation

// START: Mocks
struct NewsFeedMessage {
    let type: String?
    let message_sub_type: String?
    let message_type: String?
    let message_time: TimeInterval?
}

final class WTUserProfileService {
    
    var createdAt: Date? = Date()
    var userLimitsEnable: NSNumber? = NSNumber(booleanLiteral: true)
    var profile: Profile? = Profile(); struct Profile {
        let user_state: String? = "user"
        let billing_status: String? = "unpaid"
        let is_fake_trial: Bool? = false
        let is_aw_user: NSNumber? = NSNumber(booleanLiteral: true)
    }
    
}
// END


public enum DateForType {
    case startOfDay
    case endOfDay
    case startOfWeek
    case endOfWeek
    case startOfMonth
    case endOfMonth
    case tomorrow
    case yesterday
    case nearestMinute(minute: Int)
    case nearestHour(hour: Int)
}
public enum DateComponentType {
    case second
    case minute
    case hour
    case day
    case weekday
    case nthWeekday
    case week
    case month
    case year
}



extension Date {
    
    func isInSameYear(date: Date) -> Bool {
        equalTo(date, toGranularity: .year)
    }
    
    func isInSameMonth(date: Date) -> Bool {
        equalTo(date, toGranularity: .month)
    }
    
    func isInSameWeek(date: Date) -> Bool {
        equalTo(date, toGranularity: .weekOfYear)
    }
    
    func isInSameDay(date: Date) -> Bool {
        equalTo(date, toGranularity: .day)
    }
    
    func isInSameMinute(date: Date) -> Bool {
        equalTo(date, toGranularity: .minute)
    }
    
    private func equalTo(_ date: Date, toGranularity component: Calendar.Component) -> Bool {
        Calendar.current.isDate(self, equalTo: date, toGranularity: component)
    }
    
    var isInThisMonth: Bool {
        return isInSameMonth(date: Date())
    }
    
    var isInThisWeek: Bool {
        return isInSameWeek(date: Date())
    }
    
    var isInYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    var isInToday: Bool {
        return Calendar.current.isDateInToday(self)
    }


        func amountOfDays(to toDate: Date) -> Int {
            let calendar = Calendar.current
            let from = self.dateFor(.startOfDay)
            let to = toDate.dateFor(.startOfDay)
            let components = calendar.dateComponents([.day], from: from, to: to)
            let amountOfDays = components.day ?? 0
            return amountOfDays
        }
    
    // MARK: Date for...
    
    func dateFor(_ type: DateForType, calendar: Calendar = Calendar.current) -> Date {
        switch type {
        case .startOfDay:
            return adjust(hour: 0, minute: 0, second: 0)
        case .endOfDay:
            return adjust(hour: 23, minute: 59, second: 59)
        case .startOfWeek:
            return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))!
        case .endOfWeek:
            let offset = 7 - component(.weekday)!
            return adjust(.day, offset: offset)
        case .startOfMonth:
            return adjust(hour: 0, minute: 0, second: 0, day: 1)
        case .endOfMonth:
            let month = (component(.month) ?? 0) + 1
            return adjust(hour: 0, minute: 0, second: 0, day: 0, month: month)
        case .tomorrow:
            return adjust(.day, offset: 1)
        case .yesterday:
            return adjust(.day, offset: -1)
        case .nearestMinute(let nearest):
            let minutes = (component(.minute)! + nearest / 2) / nearest * nearest
            return adjust(hour: nil, minute: minutes, second: nil)
        case .nearestHour(let nearest):
            let hours = (component(.hour)! + nearest / 2) / nearest * nearest
            return adjust(hour: hours, minute: 0, second: nil)
        }
    }
    
    func adjust(hour: Int? = nil, minute: Int? = nil, second: Int? = nil, day: Int? = nil, month: Int? = nil, year: Int? = nil) -> Date {
        var comp = Date.components(self)
        comp.year = year ?? comp.year
        comp.month = month ?? comp.month
        comp.day = day ?? comp.day
        comp.hour = hour ?? comp.hour
        comp.minute = minute ?? comp.minute
        comp.second = second ?? comp.second
        return Calendar.current.date(from: comp)!
    }
    
    func adjust(_ component: DateComponentType, offset: Int) -> Date {
        var dateComp = DateComponents()
        switch component {
        case .second:
            dateComp.second = offset
        case .minute:
            dateComp.minute = offset
        case .hour:
            dateComp.hour = offset
        case .day:
            dateComp.day = offset
        case .weekday:
            dateComp.weekday = offset
        case .nthWeekday:
            dateComp.weekdayOrdinal = offset
        case .week:
            dateComp.weekOfYear = offset
        case .month:
            dateComp.month = offset
        case .year:
            dateComp.year = offset
        }
        return Calendar.current.date(byAdding: dateComp, to: self)!
    }
    
    func component(_ component: DateComponentType) -> Int? {
        let components = Date.components(self)
        switch component {
        case .second:
            return components.second
        case .minute:
            return components.minute
        case .hour:
            return components.hour
        case .day:
            return components.day
        case .weekday:
            return components.weekday
        case .nthWeekday:
            return components.weekdayOrdinal
        case .week:
            return components.weekOfYear
        case .month:
            return components.month
        case .year:
            return components.year
        }
    }
    
    
    
    internal static func componentFlags() -> Set<Calendar.Component> { return [Calendar.Component.year, Calendar.Component.month, Calendar.Component.day, Calendar.Component.weekOfYear, Calendar.Component.hour, Calendar.Component.minute, Calendar.Component.second, Calendar.Component.weekday, Calendar.Component.weekdayOrdinal, Calendar.Component.weekOfYear] }
    internal static func components(_ fromDate: Date) -> DateComponents {
        return Calendar.current.dateComponents(Date.componentFlags(), from: fromDate)
    }
    
    
}


