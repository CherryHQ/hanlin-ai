//
//  CalendarService.swift
//  AI_Hanlin
//
//  Created by 哆啦好多梦 on 16/4/25.
//

import Foundation
import EventKit


/// 根据可选的关键词、日期范围、地点以及事件类型搜索系统日历事件与提醒事项，返回匹配的 EventItem 列表。
/// - Parameters:
///   - keyword: 可选，匹配事件标题或备注中的文本（不区分大小写）。
///   - startDate: 可选，日期范围的起始日期，要求事件（或提醒）的时间大于等于此日期。
///   - endDate: 可选，日期范围的截止日期，要求事件（或提醒）的时间小于等于此日期。
///   - location: 可选，匹配日历事件的地点（不区分大小写）；对于提醒事项，在标题或备注中匹配。
///   - eventType: 可选，指定要查询的事件类型。有效值为 "calendar" 或 "reminder"，若不指定或为空则查询全部。
/// - Returns: 匹配成功的 [EventItem] 数组。如果所有搜索条件均为空则返回空数组。
func searchSystemEvents(keyword: String?, startDate: Date?, endDate: Date?, location: String?, eventType: String? = nil) async -> [EventItem] {
    // 至少需要提供一个搜索条件
    let trimmedKeyword = keyword?.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedLocation = location?.trimmingCharacters(in: .whitespacesAndNewlines)
    if (trimmedKeyword == nil || trimmedKeyword!.isEmpty)
        && startDate == nil && endDate == nil
        && (trimmedLocation == nil || trimmedLocation!.isEmpty) {
        return []
    }
    
    // 根据 eventType 决定查询内容：如果不指定则都查询
    let typeLower = eventType?.lowercased() ?? ""
    // 如果 eventType 为 "calendar" 或 "reminder"，仅查询指定类型；否则查询全部
    let searchCalendar = typeLower.isEmpty || typeLower == "calendar" || typeLower == "both"
    let searchReminder = typeLower.isEmpty || typeLower == "reminder" || typeLower == "both"
    
    let store = EKEventStore()
    var results: [EventItem] = []
    
    // 请求系统日历与提醒事项权限
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
    
    // 查询系统日历事件（限定查询窗口为当前日期前后1年）
    if grantedCalendar && searchCalendar {
        let defaultWindow: TimeInterval = 5 * 365 * 24 * 3600  // 五年
        
        // 如果用户指定了 startDate，就往前推一天；否则回退到五年前
        let queryStart: Date = {
            if let sd = startDate,
               let adjusted = Calendar.current.date(byAdding: .day, value: -1, to: sd) {
                return adjusted
            } else {
                return Date().addingTimeInterval(-defaultWindow)
            }
        }()
        
        // 如果用户指定了 endDate，就往后推一天；否则推到五年后
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
        
        // 扩展 ±1 天的时间区间：有值就 +/– 1 天，无值就无限远
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
            // 关键词匹配：若设置关键词，则要求标题或备注中包含（不区分大小写）
            var keywordMatch = true
            if let kw = trimmedKeyword, !kw.isEmpty {
                let titleLower = e.title.lowercased()
                let notesLower = e.notes?.lowercased() ?? ""
                keywordMatch = titleLower.contains(kw.lowercased()) || notesLower.contains(kw.lowercased())
            }
            
            let dateMatch: Bool = {
                guard let eventDate = e.startDate else {
                    // 事件无开始日期，只有当用户既没传 startDate 也没传 endDate 时才视为通过
                    return startDate == nil && endDate == nil
                }
                return searchInterval.contains(eventDate)
            }()
            
            // 地点匹配：若提供地点，则要求事件的 location 包含该关键字
            var locationMatch = true
            if let loc = trimmedLocation, !loc.isEmpty {
                let eventLocation = e.location?.lowercased() ?? ""
                locationMatch = eventLocation.contains(loc.lowercased())
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
    
    // 查询系统提醒事项
    if grantedReminder && searchReminder {
        let predicate = store.predicateForReminders(in: nil)
        let reminders = await withCheckedContinuation { continuation in
            store.fetchReminders(matching: predicate) { result in
                continuation.resume(returning: result ?? [])
            }
        }
        
        for r in reminders {
            // 关键词匹配
            var keywordMatch = true
            if let kw = trimmedKeyword, !kw.isEmpty {
                let titleLower = r.title.lowercased()
                let notesLower = r.notes?.lowercased() ?? ""
                keywordMatch = titleLower.contains(kw.lowercased()) || notesLower.contains(kw.lowercased())
            }
            
            // 日期匹配：使用提醒的 dueDateComponents.date
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
            
            // 地点匹配：提醒事项没有专门地点字段，则在标题和备注中匹配
            var locationMatch = true
            if let loc = trimmedLocation, !loc.isEmpty {
                let titleLower = r.title.lowercased()
                let notesLower = r.notes?.lowercased() ?? ""
                locationMatch = titleLower.contains(loc.lowercased()) || notesLower.contains(loc.lowercased())
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


/// 写入系统日历或提醒事项事件
/// - Parameters:
///   - type: 事件类型，取值 "calendar" 或 "reminder"（区分大小写不敏感）
///   - title: 事件标题
///   - startDate: 日历事件使用的开始时间（提醒事项可忽略）
///   - endDate: 日历事件使用的结束时间（提醒事项可忽略）
///   - dueDate: 提醒事项使用的截止日期（日历事件可忽略）
///   - location: 日历事件使用的地点；提醒事项没有专门地点字段，可忽略或放在备注中
///   - notes: 事件备注
///   - priority: 提醒事项的优先级（1～9），0 或 nil 表示未设置；日历事件可忽略
///   - reminderMinutes: 提醒时间（分钟）。对于有截止日期的提醒事项，表示提前多少分钟提醒；对于无截止日期的提醒事项，表示多少分钟后提醒（默认为5分钟）
/// - Returns: (写入成功后的 EventItem 对象, Bool)，成功则返回更新后的 EventItem（包含系统生成的标识符），否则返回 nil 和 false
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
        // 请求访问日历权限
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
        // 请求访问提醒事项权限
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
        
        // 设置优先级
        if let priority = priority, priority > 0 {
            ekReminder.priority = priority
        }
        ekReminder.isCompleted = false  // 新创建的提醒事项始终为未完成状态
        
        // 设置截止日期（如果提供）
        if let dueDate = dueDate {
            // 使用当前时区保存完整的时间信息，包括时区和秒
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone], from: dueDate)
            ekReminder.dueDateComponents = components

            print("设置截止日期：\(dueDate) -> 组件：\(components)")
        } else {
            print("没有设置截止日期")
        }
        
        // 在保存前添加闹钟
        if dueDate != nil {
            // 添加提前提醒闹钟（必须在设置截止日期后添加）
            if let reminderMinutes = reminderMinutes, reminderMinutes > 0 {
                let alarm = EKAlarm(relativeOffset: -TimeInterval(reminderMinutes * 60))
                ekReminder.addAlarm(alarm)
                print("添加相对时间提醒：提前 \(reminderMinutes) 分钟")
            }
        } else {
            // 没有截止日期的情况下，添加绝对时间提醒
            if let reminderMinutes = reminderMinutes, reminderMinutes > 0 {
                let alertDate = Date().addingTimeInterval(TimeInterval(reminderMinutes * 60))
                let alarm = EKAlarm(absoluteDate: alertDate)
                ekReminder.addAlarm(alarm)
                print("添加绝对时间提醒：\(alertDate)")
            }
        }

        // 保存提醒事项（包含所有属性和闹钟）
        do {
            try store.save(ekReminder, commit: true)
            print("提醒事项保存成功")
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
                completed: false,  // 新创建的提醒事项始终为未完成状态
                calendarIdentifier: nil
            )
            savedReminder.calendarIdentifier = ekReminder.calendarItemIdentifier
            return (savedReminder, true)
    } else {
        return (nil, false)
    }
}

