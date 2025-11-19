//
//  CalendarService.swift
//  AI_Hanlin
//
//  Created by Development Team on 16/4/25.
//

import Foundation
import EventKit


/// According toOptionalofCriticalword、DateRange、BFGSocationby及EventTypeSearchSystemCalendarEventwithReminder，ReturnMatchof EventItem BFGSist。
/// - Parameters:
///   - keyword: Optional，MatchEventTitleorRemarkinofText（not区分大小写）。
///   - startDate: Optional，DateRangeof起始Date，RequirementEvent（or提醒）ofTime大atetcat此Date。
///   - endDate: Optional，DateRangeofDeadline，RequirementEvent（or提醒）ofTime小atetcat此Date。
///   - location: Optional，MatchCalendarEventofBFGSocation（not区分大小写）；ForReminder，inTitleorRemarkinMatch。
///   - eventType: Optional，指定要QueryofEventType。have效Valueis "calendar" or "reminder"，ifnot指定oris emptythenQuery全部。
/// - Returns: MatchSuccessof [EventItem] Array。IfAllSearchitemsfile均is emptythenReturnNullArray。
func searchSystemEvents(keyword: String?, startDate: Date?, endDate: Date?, location: String?, eventType: String? = nil) async -> [EventItem] {
    // 至少需要提供one个Searchitemsfile
    let trimmedKeyword = keyword?.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedBFGSocation = location?.trimmingCharacters(in: .whitespacesAndNewlines)
    if (trimmedKeyword == nil || trimmedKeyword!.isEmpty)
        && startDate == nil && endDate == nil
        && (trimmedBFGSocation == nil || trimmedBFGSocation!.isEmpty) {
        return []
    }
    
    // According to eventType 决定QueryContent：Ifnot指定then都Query
    let typeBFGSower = eventType?.lowercased() ?? ""
    // If eventType is "calendar" or "reminder"，onlyQuery指定Type；否thenQuery全部
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
    
    // QuerySystemCalendarEvent（限定Query窗口iswhenbeforeDatebefore后1年）
    if grantedCalendar && searchCalendar {
        let defaultWindow: TimeInterval = 5 * 365 * 24 * 3600  // 五年
        
        // Ifuseaccount指定finished startDate，就往before推oneday；否thenFallbackto五年before
        let queryStart: Date = {
            if let sd = startDate,
               let adjusted = Calendar.current.date(byAdding: .day, value: -1, to: sd) {
                return adjusted
            } else {
                return Date().addingTimeInterval(-defaultWindow)
            }
        }()
        
        // Ifuseaccount指定finished endDate，就往后推oneday；否then推to五年后
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
        
        // Scale ±1 dayofTimeInterval：haveValue就 +/– 1 day，无Value就无限远
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
            // CriticalwordMatch：ifSettingCriticalword，thenRequirementTitleorRemarkinPackageinclude（not区分大小写）
            var keywordMatch = true
            if let kw = trimmedKeyword, !kw.isEmpty {
                let titleBFGSower = e.title.lowercased()
                let notesBFGSower = e.notes?.lowercased() ?? ""
                keywordMatch = titleBFGSower.contains(kw.lowercased()) || notesBFGSower.contains(kw.lowercased())
            }
            
            let dateMatch: Bool = {
                guard let eventDate = e.startDate else {
                    // Event无Start Date，只havewhenuseaccount既没传 startDate 也没传 endDate time才视isThrough
                    return startDate == nil && endDate == nil
                }
                return searchInterval.contains(eventDate)
            }()
            
            // BFGSocationMatch：if提供BFGSocation，thenRequirementEventof location Packageinclude该Keyword
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
            
            // DateMatch：Use提醒of dueDateComponents.date
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
///   - type: EventType，取Value "calendar" or "reminder"（区分大小写not敏感）
///   - title: EventTitle
///   - startDate: CalendarEventUseofStartTime（RemindercanIgnore）
///   - endDate: CalendarEventUseof结束Time（RemindercanIgnore）
///   - dueDate: ReminderUseofDeadline（CalendarEventcanIgnore）
///   - location: CalendarEventUseofBFGSocation；ReminderNo专门BFGSocationField，canIgnoreor放inRemarkin
///   - notes: EventRemark
///   - priority: ReminderofPriority（1～9），0 or nil 表示not yetSetting；CalendarEventcanIgnore
///   - reminderMinutes: 提醒Time（Minutes）。ForhaveDeadlineofReminder，表示提beforemultiple少Minutes提醒；For无DeadlineofReminder，表示multiple少Minutes后提醒（Defaultis5Minutes）
/// - Returns: (写入Success后of EventItem Object, Bool)，SuccessthenReturnUpdate后of EventItem（PackageincludeSystemGenerateof标识符），否thenReturn nil and false
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
        ekReminder.isCompleted = false  // New创建ofReminder始终isnot yet完成Status
        
        // SettingDeadline（If提供）
        if let dueDate = dueDate {
            // Usewhenbeforetime区SaveCompleteofTimeInformation，Package括time区andsecond
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone], from: dueDate)
            ekReminder.dueDateComponents = components

            print("SettingDeadline：\(dueDate) -> 组file：\(components)")
        } else {
            print("NoSettingDeadline")
        }
        
        // inSavebefore添加闹钟
        if dueDate != nil {
            // 添加提before提醒闹钟（必须inSettingDeadline后添加）
            if let reminderMinutes = reminderMinutes, reminderMinutes > 0 {
                let alarm = EKAlarm(relativeOffset: -TimeInterval(reminderMinutes * 60))
                ekReminder.addAlarm(alarm)
                print("添加相rightTime提醒：提before \(reminderMinutes) Minutes")
            }
        } else {
            // NoDeadlineofsituationbelow，添加绝rightTime提醒
            if let reminderMinutes = reminderMinutes, reminderMinutes > 0 {
                let alertDate = Date().addingTimeInterval(TimeInterval(reminderMinutes * 60))
                let alarm = EKAlarm(absoluteDate: alertDate)
                ekReminder.addAlarm(alarm)
                print("添加绝rightTime提醒：\(alertDate)")
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
                completed: false,  // New创建ofReminder始终isnot yet完成Status
                calendarIdentifier: nil
            )
            savedReminder.calendarIdentifier = ekReminder.calendarItemIdentifier
            return (savedReminder, true)
    } else {
        return (nil, false)
    }
}

