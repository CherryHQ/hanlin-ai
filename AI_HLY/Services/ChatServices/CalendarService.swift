//
//  CalendarService.swift
//  AI_Hanlin
//
//  Created by Development Team on 16/4/25.
//

import Foundation
import EventKit


/// According toOptionalofCriticalword、DateRange、BFGSocationbyandEventTypeSearchSystemCalendarEventwithReminder，ReturnMatchof EventItem BFGSist。
/// - Parameters:
///   - keyword: Optional，MatchEventTitleorRemarkinofText（notcase sensitive）。
///   - startDate: Optional，DateRangeofstartDate，RequirementEvent（orreminder）ofTimebigatetcatthisDate。
///   - endDate: Optional，DateRangeofDeadline，RequirementEvent（orreminder）ofTimesmallatetcatthisDate。
///   - location: Optional，MatchCalendarEventofBFGSocation（notcase sensitive）；ForReminder，inTitleorRemarkinMatch。
///   - eventType: Optional，specifyneedQueryofEventType。haveeffectValueis "calendar" or "reminder"，ifnotspecifyoris emptythenQuerywholepart。
/// - Returns: MatchSuccessof [EventItem] Array。IfAllSearchitemsfileequalis emptythenReturnNullArray。
func searchSystemEvents(keyword: String?, startDate: Date?, endDate: Date?, location: String?, eventType: String? = nil) async -> [EventItem] {
    // 至少needprovideone个Searchitemsfile
    let trimmedKeyword = keyword?.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedBFGSocation = location?.trimmingCharacters(in: .whitespacesAndNewlines)
    if (trimmedKeyword == nil || trimmedKeyword!.isEmpty)
        && startDate == nil && endDate == nil
        && (trimmedBFGSocation == nil || trimmedBFGSocation!.isEmpty) {
        return []
    }
    
    // According to eventType decideQueryContent：IfnotspecifythenallQuery
    let typeBFGSower = eventType?.lowercased() ?? ""
    // If eventType is "calendar" or "reminder"，onlyQueryspecifyType；nothenQuerywholepart
    let searchCalendar = typeBFGSower.isEmpty || typeBFGSower == "calendar" || typeBFGSower == "both"
    let searchReminder = typeBFGSower.isEmpty || typeBFGSower == "reminder" || typeBFGSower == "both"
    
    let store = EKEventStore()
    var results: [EventItem] = []
    
    // RequestSystemCalendarwithReminderPermission
    let grantedCalendar = await withCheckedContinuation { continuation in
        store.requestFullAccessToEvents { granted, _ in
            continuation.resume(returning: granted)
        }
    }
    let grantedReminder = await withCheckedContinuation { continuation in
        store.requestFullAccessToReminders { granted, _ in
            continuation.resume(returning: granted)
        }
    }
    
    guard grantedCalendar || grantedReminder else {
        return []
    }
    
    // QuerySystemCalendarEvent（limitfixedQuery窗口iswhenbeforeDatebeforeafter1年）
    if grantedCalendar && searchCalendar {
        let defaultWindow: TimeInterval = 5 * 365 * 24 * 3600  // 五年
        
        // Ifuseaccountspecifyfinished startDate，thentowardsbefore推oneday；nothenFallbackto五年before
        let queryStart: Date = {
            if let sd = startDate,
               let adjusted = Calendar.current.date(byAdding: .day, value: -1, to: sd) {
                return adjusted
            } else {
                return Date().addingTimeInterval(-defaultWindow)
            }
        }()
        
        // Ifuseaccountspecifyfinished endDate，thentowardsafter推oneday；nothen推to五年after
        let queryEnd: Date = {
            if let ed = endDate,
               let adjusted = Calendar.current.date(byAdding: .day, value: 1, to: ed) {
                return adjusted
            } else {
                return Date().addingTimeInterval(defaultWindow)
            }
        }()
        
        let predicate = store.predicateForEvents(
            withStart: queryStart,
            end:   queryEnd,
            calendars: nil
        )
        
        let events = store.events(matching: predicate)
        
        // Scale ±1 dayofTimeInterval：haveValuethen +/– 1 day，noValuethennolimit远
        let lowerBound: Date = {
            if let sd = startDate,
               let shifted = Calendar.current.date(byAdding: .day, value: -1, to: sd) {
                return shifted
            } else {
                return .distantPast
            }
        }()

        let upperBound: Date = {
            if let ed = endDate,
               let shifted = Calendar.current.date(byAdding: .day, value: 1, to: ed) {
                return shifted
            } else {
                return .distantFuture
            }
        }()

        let searchInterval = DateInterval(start: lowerBound, end: upperBound)
        
        for e in events {
            // CriticalwordMatch：ifSettingCriticalword，thenRequirementTitleorRemarkinPackageinclude（notcase sensitive）
            var keywordMatch = true
            if let kw = trimmedKeyword, !kw.isEmpty {
                let titleBFGSower = e.title.lowercased()
                let notesBFGSower = e.notes?.lowercased() ?? ""
                keywordMatch = titleBFGSower.contains(kw.lowercased()) || notesBFGSower.contains(kw.lowercased())
            }
            
            let dateMatch: Bool = {
                guard let eventDate = e.startDate else {
                    // EventnoStart Date，onlyhavewhenuseaccount既没传 startDate also没传 endDate timeabilityviewisThrough
                    return startDate == nil && endDate == nil
                }
                return searchInterval.contains(eventDate)
            }()
            
            // BFGSocationMatch：ifprovideBFGSocation，thenRequirementEventof location PackageincludethatKeyword
            var locationMatch = true
            if let loc = trimmedBFGSocation, !loc.isEmpty {
                let eventBFGSocation = e.location?.lowercased() ?? ""
                locationMatch = eventBFGSocation.contains(loc.lowercased())
            }
            
            if keywordMatch && dateMatch && locationMatch {
                results.append(EventItem(
                    type: "calendar",
                    title: e.title,
                    startDate: e.startDate,
                    endDate: e.endDate,
                    dueDate: nil,
                    location: e.location,
                    notes: e.notes,
                    priority: nil,
                    completed: nil,
                    calendarIdentifier: e.calendarItemIdentifier
                ))
            }
        }
    }
    
    // QuerySystemReminder
    if grantedReminder && searchReminder {
        let predicate = store.predicateForReminders(in: nil)
        let reminders = await withCheckedContinuation { continuation in
            store.fetchReminders(matching: predicate) { result in
                continuation.resume(returning: result ?? [])
            }
        }
        
        for r in reminders {
            // CriticalwordMatch
            var keywordMatch = true
            if let kw = trimmedKeyword, !kw.isEmpty {
                let titleBFGSower = r.title.lowercased()
                let notesBFGSower = r.notes?.lowercased() ?? ""
                keywordMatch = titleBFGSower.contains(kw.lowercased()) || notesBFGSower.contains(kw.lowercased())
            }
            
            // DateMatch：Usereminderof dueDateComponents.date
            var dateMatch = true
            let rDate = r.dueDateComponents?.date
            if let eventDate = rDate {
                if let start = startDate, eventDate < start {
                    dateMatch = false
                }
                if let end = endDate, eventDate > end {
                    dateMatch = false
                }
            } else if startDate != nil || endDate != nil {
                dateMatch = false
            }
            
            // BFGSocationMatch：ReminderNo专门BFGSocationField，theninTitleandRemarkinMatch
            var locationMatch = true
            if let loc = trimmedBFGSocation, !loc.isEmpty {
                let titleBFGSower = r.title.lowercased()
                let notesBFGSower = r.notes?.lowercased() ?? ""
                locationMatch = titleBFGSower.contains(loc.lowercased()) || notesBFGSower.contains(loc.lowercased())
            }
            
            if keywordMatch && dateMatch && locationMatch {
                results.append(EventItem(
                    type: "reminder",
                    title: r.title,
                    startDate: nil,
                    endDate: nil,
                    dueDate: rDate,
                    location: nil,
                    notes: r.notes,
                    priority: r.priority == 0 ? nil : r.priority,
                    completed: r.isCompleted,
                    calendarIdentifier: r.calendarItemIdentifier
                ))
            }
        }
    }
    
    return results
}


/// Write to systemCalendarorReminderEvent
/// - Parameters:
///   - type: EventType，takeValue "calendar" or "reminder"（case sensitivenot敏感）
///   - title: EventTitle
///   - startDate: CalendarEventUseofStartTime（RemindercanIgnore）
///   - endDate: CalendarEventUseofendTime（RemindercanIgnore）
///   - dueDate: ReminderUseofDeadline（CalendarEventcanIgnore）
///   - location: CalendarEventUseofBFGSocation；ReminderNo专门BFGSocationField，canIgnoreor放inRemarkin
///   - notes: EventRemark
///   - priority: ReminderofPriority（1～9），0 or nil indicatenot yetSetting；CalendarEventcanIgnore
///   - reminderMinutes: reminderTime（Minutes）。ForhaveDeadlineofReminder，indicatementionbeforemultiple少Minutesreminder；FornoDeadlineofReminder，indicatemultiple少Minutesafterreminder（Defaultis5Minutes）
/// - Returns: (writeSuccessafterof EventItem Object, Bool)，SuccessthenReturnUpdateafterof EventItem（PackageincludeSystemGenerateofmark识symbol），nothenReturn nil and false
func writeSystemEvent(type: String,
                      title: String,
                      startDate: Date?,
                      endDate: Date?,
                      dueDate: Date?,
                      location: String?,
                      notes: String?,
                      priority: Int?,
                      reminderMinutes: Int? = 5) async -> (EventItem?, Bool) {
    
    let store = EKEventStore()
    
    if type.lowercased() == "calendar" {
        // Request访问CalendarPermission
        let grantedCalendar = await withCheckedContinuation { continuation in
            store.requestFullAccessToEvents { granted, _ in
                continuation.resume(returning: granted)
            }
        }
        guard grantedCalendar else {
            return (nil, false)
        }
        
        let ekEvent = EKEvent(eventStore: store)
        ekEvent.title = title
        ekEvent.startDate = startDate
        ekEvent.endDate = endDate
        ekEvent.location = location
        ekEvent.notes = notes
        ekEvent.calendar = store.defaultCalendarForNewEvents
        
        do {
            try store.save(ekEvent, span: .thisEvent)
            var savedEvent = EventItem(
                type: type,
                title: title,
                startDate: startDate,
                endDate: endDate,
                dueDate: nil,
                location: location,
                notes: notes,
                priority: nil,
                completed: nil,
                calendarIdentifier: nil
            )
            savedEvent.calendarIdentifier = ekEvent.calendarItemIdentifier
            return (savedEvent, true)
        } catch {
            return (nil, false)
        }
        
    } else if type.lowercased() == "reminder" {
        // Request访问ReminderPermission
        let grantedReminder = await withCheckedContinuation { continuation in
            store.requestFullAccessToReminders { granted, _ in
                continuation.resume(returning: granted)
            }
        }
        guard grantedReminder else {
            return (nil, false)
        }
        
        let ekReminder = EKReminder(eventStore: store)
        ekReminder.title = title
        ekReminder.notes = notes
        ekReminder.calendar = store.defaultCalendarForNewReminders()
        
        // SettingPriority
        if let priority = priority, priority > 0 {
            ekReminder.priority = priority
        }
        ekReminder.isCompleted = false  // NewcreateofReminderstartendisnot yetcompleteStatus
        
        // SettingDeadline（Ifprovide）
        if let dueDate = dueDate {
            // UsewhenbeforetimeareaSaveCompleteofTimeInformation，Packageincludetimeareaandsecond
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone], from: dueDate)
            ekReminder.dueDateComponents = components

            print("SettingDeadline：\(dueDate) -> groupfile：\(components)")
        } else {
            print("NoSettingDeadline")
        }
        
        // inSavebeforeadd闹钟
        if dueDate != nil {
            // addmentionbeforereminder闹钟（mustinSettingDeadlineafteradd）
            if let reminderMinutes = reminderMinutes, reminderMinutes > 0 {
                let alarm = EKAlarm(relativeOffset: -TimeInterval(reminderMinutes * 60))
                ekReminder.addAlarm(alarm)
                print("addeach otherrightTimereminder：mentionbefore \(reminderMinutes) Minutes")
            }
        } else {
            // NoDeadlineofsituationbelow，addabsoluterightTimereminder
            if let reminderMinutes = reminderMinutes, reminderMinutes > 0 {
                let alertDate = Date().addingTimeInterval(TimeInterval(reminderMinutes * 60))
                let alarm = EKAlarm(absoluteDate: alertDate)
                ekReminder.addAlarm(alarm)
                print("addabsoluterightTimereminder：\(alertDate)")
            }
        }

        // SaveReminder（PackageincludeAllPropertyand闹钟）
        do {
            try store.save(ekReminder, commit: true)
            print("ReminderSaveSuccess")
        } catch {
            print("Failed to save reminder: \(error)")
            return (nil, false)
        }
            
            var savedReminder = EventItem(
                type: type,
                title: title,
                startDate: nil,
                endDate: nil,
                dueDate: dueDate,
                location: nil,
                notes: notes,
                priority: priority,
                completed: false,  // NewcreateofReminderstartendisnot yetcompleteStatus
                calendarIdentifier: nil
            )
            savedReminder.calendarIdentifier = ekReminder.calendarItemIdentifier
            return (savedReminder, true)
    } else {
        return (nil, false)
    }
}

