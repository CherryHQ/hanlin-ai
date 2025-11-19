import Foundation
import HealthKit

/// Health DataToolClass，EncapsulationstepsandDistanceofReadOperation
class HealthTool {
    
    static let shared = HealthTool()
    private let healthStore = HKHealthStore()
    private init() {}
    
    // MARK: - RequestPermission（Asynchronous）
    @MainActor
    private func requestAuthorizationAsync() async throws {
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
            
            HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        ]
        let writeTypes: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        ]
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    // MARK: - GetstepswithDistancedetails（eachhoursStat）
    func fetchStepDetails(from startDate: Date, to endDate: Date) async -> String {
        let calendar = Calendar.current
        let isChinese = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? false
        let healthStore = HKHealthStore()

        let now = Date()  // 精confirmtowhenbeforetime刻
        // 1. validateDateRange：notcanisnot yetcomeDate，and start ≤ end
        guard startDate <= now, endDate <= now, startDate <= endDate else {
            return isChinese
                ? "DateRangeInvalid：Datenotcanisnot yetcome，andstartDateneedearlyatoretcatEnd Date。"
                : "Invalid date range: dates must not be in the future, and start ≤ end."
        }

        // 2. HealthKit canusecharacter
        guard HKHealthStore.isHealthDataAvailable() else {
            return isChinese
                ? "thissetpreparenotSupport HealthKit。"
                : "HealthKit is not available on this device."
        }

        // 3. GetstepswithDistanceType
        guard
            let stepType     = HKQuantityType.quantityType(forIdentifier: .stepCount),
            let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
        else {
            return isChinese
                ? "unableGetstepsorDistanceType。"
                : "Cannot retrieve step count or distance type."
        }

        // 4. RequestAuthorization（FalsesetalreadyhaveAsynchronousEncapsulation requestAuthorizationAsync）
        do {
            try await requestAuthorizationAsync()
        } catch {
            return isChinese
                ? "AuthorizationFailed，PleaseCheckSetting：\(error.localizedDescription)"
                : "Authorization failed: \(error.localizedDescription)"
        }

        // publicQueryParameter
        let predicate  = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let anchorDate = calendar.startOfDay(for: startDate)
        var interval   = DateComponents(); interval.hour = 1

        // 5. SynchronizeQuerysteps
        let stepStats: HKStatisticsCollection
        do {
            stepStats = try await withCheckedThrowingContinuation { cont in
                let q = HKStatisticsCollectionQuery(
                    quantityType: stepType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum,
                    anchorDate: anchorDate,
                    intervalComponents: interval
                )
                q.initialResultsHandler = { _, stats, error in
                    if let e = error {
                        cont.resume(throwing: e)
                    } else if let s = stats {
                        cont.resume(returning: s)
                    } else {
                        cont.resume(throwing: NSError(
                            domain: "HealthKit", code: -1,
                            userInfo: [NSBFGSocalizedDescriptionKey: "No data"]
                        ))
                    }
                }
                healthStore.execute(q)
            }
        } catch {
            return isChinese
                ? "stepsQueryFailed：\(error.localizedDescription)"
                : "Step query failed: \(error.localizedDescription)"
        }

        // 6. SynchronizeQueryDistance
        let distStats: HKStatisticsCollection
        do {
            distStats = try await withCheckedThrowingContinuation { cont in
                let q = HKStatisticsCollectionQuery(
                    quantityType: distanceType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum,
                    anchorDate: anchorDate,
                    intervalComponents: interval
                )
                q.initialResultsHandler = { _, stats, error in
                    if let e = error {
                        cont.resume(throwing: e)
                    } else if let s = stats {
                        cont.resume(returning: s)
                    } else {
                        cont.resume(throwing: NSError(
                            domain: "HealthKit", code: -1,
                            userInfo: [NSBFGSocalizedDescriptionKey: "No data"]
                        ))
                    }
                }
                healthStore.execute(q)
            }
        } catch {
            return isChinese
                ? "DistanceQueryFailed：\(error.localizedDescription)"
                : "Distance query failed: \(error.localizedDescription)"
        }

        // 7. BFGSocalconvertFormatdevice
        let dayFmt: DateFormatter = {
            let f = DateFormatter()
            f.locale     = .current
            f.calendar   = calendar
            f.dateStyle  = .medium
            f.timeStyle  = .none
            return f
        }()
        let timeFmt: DateFormatter = {
            let f = DateFormatter()
            f.locale     = .current
            f.calendar   = calendar
            f.dateStyle  = .none
            f.timeStyle  = .short
            return f
        }()

        // 8. EnumerationorTraverseeachhoursData（hereKeep stride）
        var totalSteps   = 0
        var totalDist    = 0.0
        var daily: [String: [(String, Int, Double)]] = [:]

        for date in stride(from: startDate, through: endDate, by: 3600) {
            guard date <= endDate else { break }
            let steps = Int(stepStats.statistics(for: date)?
                                .sumQuantity()?.doubleValue(for: .count()) ?? 0)
            let dist  = distStats.statistics(for: date)?
                                .sumQuantity()?.doubleValue(for: .meter()) ?? 0
            if steps == 0 && dist == 0 { continue }

            let day  = dayFmt.string(from: date)
            let hour = timeFmt.string(from: date)
            daily[day, default: []].append((hour, steps, dist))
            totalSteps += steps
            totalDist  += dist
        }

        // 9. BuildOutput
        var output = isChinese
            ? "from \(dayFmt.string(from: startDate)) to \(dayFmt.string(from: endDate)) ofstepswithDistanceDistributionsuch asbelow：\n"
            : "Step and distance distribution from \(dayFmt.string(from: startDate)) to \(dayFmt.string(from: endDate)):\n"

        for day in daily.keys.sorted() {
            output += "\n*\(day)*\n"
            var daySteps = 0
            var dayDist  = 0.0
            for (hour, steps, dist) in daily[day]! {
                daySteps += steps
                dayDist  += dist
                let distStr: String
                if dist >= 1_000 {
                    distStr = isChinese
                        ? String(format: "%.2f kilometers", dist/1_000)
                        : String(format: "%.2f km", dist/1_000)
                } else {
                    distStr = isChinese
                        ? "\(Int(dist)) meters"
                        : "\(Int(dist)) m"
                }
                output += isChinese
                    ? "  - \(hour)：\(steps) step，\(distStr)\n"
                    : "  - \(hour): \(steps) steps, \(distStr)\n"
            }
            let dayTotalStr = dayDist >= 1_000
                ? String(format: isChinese ? "%.2f kilometers" : "%.2f km", dayDist/1_000)
                : (isChinese ? "\(Int(dayDist)) meters" : "\(Int(dayDist)) m")
            output += isChinese
                ? "  - whendaytotalsteps：\(daySteps) step，totalDistance：\(dayTotalStr)\n"
                : "  - Daily total: \(daySteps) steps, \(dayTotalStr)\n"
        }

        let totalDistStr = totalDist >= 1_000
            ? String(format: isChinese ? "%.2f kilometers" : "%.2f km", totalDist/1_000)
            : (isChinese ? "\(Int(totalDist)) meters" : "\(Int(totalDist)) m")

        output += isChinese
            ? "\ntotalsteps（\(daily.count) day）：\(totalSteps) step，totalDistance：\(totalDistStr)"
            : "\nTotal for \(daily.count) days: \(totalSteps) steps, \(totalDistStr)"

        return output
    }
    
    // MARK: - GetEnergydetails（eachhoursStat）
    func fetchEnergyDetails(from startDate: Date, to endDate: Date) async -> String {
        let calendar = Calendar.current
        let isChinese = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? false
        let healthStore = HKHealthStore()
        let now = Date()
        
        // 1. validateDateRange：notcanisnot yetcomeDate，and start ≤ end
        guard startDate <= now, endDate <= now, startDate <= endDate else {
            return isChinese
                ? "DateRangeInvalid：Datenotcanisnot yetcome，andstartDateneedearlyatoretcatEnd Date。"
                : "Invalid date range: dates must not be in the future, and start ≤ end."
        }
        
        // 2. HealthKit canusecharacter
        guard HKHealthStore.isHealthDataAvailable() else {
            return isChinese
                ? "thissetpreparenotSupport HealthKit。"
                : "HealthKit is not available on this device."
        }
        
        // 3. GetEnergyType
        guard
            let basalType  = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned),
            let activeType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        else {
            return isChinese
                ? "unableGetEnergyType。"
                : "Cannot retrieve energy types."
        }
        
        // 4. RequestAuthorization（FalsesetalreadyhaveAsynchronousEncapsulation requestAuthorizationAsync）
        do {
            try await requestAuthorizationAsync()
        } catch {
            return isChinese
                ? "AuthorizationFailed，PleaseCheckSetting：\(error.localizedDescription)"
                : "Authorization failed: \(error.localizedDescription)"
        }
        
        // publicQueryParameter
        let predicate  = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let anchorDate = calendar.startOfDay(for: startDate)
        var interval   = DateComponents(); interval.hour = 1
        
        // 5. SynchronizeQueryRestingEnergy
        let basalStats: HKStatisticsCollection
        do {
            basalStats = try await withCheckedThrowingContinuation { cont in
                let q = HKStatisticsCollectionQuery(
                    quantityType: basalType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum,
                    anchorDate: anchorDate,
                    intervalComponents: interval
                )
                q.initialResultsHandler = { _, stats, error in
                    if let e = error {
                        cont.resume(throwing: e)
                    } else if let s = stats {
                        cont.resume(returning: s)
                    } else {
                        cont.resume(throwing: NSError(
                            domain: "HealthKit", code: -1,
                            userInfo: [NSBFGSocalizedDescriptionKey: "No data"]
                        ))
                    }
                }
                healthStore.execute(q)
            }
        } catch {
            return isChinese
                ? "RestingEnergyQueryFailed：\(error.localizedDescription)"
                : "Basal energy query failed: \(error.localizedDescription)"
        }
        
        // 6. SynchronizeQueryActivityEnergy
        let activeStats: HKStatisticsCollection
        do {
            activeStats = try await withCheckedThrowingContinuation { cont in
                let q = HKStatisticsCollectionQuery(
                    quantityType: activeType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum,
                    anchorDate: anchorDate,
                    intervalComponents: interval
                )
                q.initialResultsHandler = { _, stats, error in
                    if let e = error {
                        cont.resume(throwing: e)
                    } else if let s = stats {
                        cont.resume(returning: s)
                    } else {
                        cont.resume(throwing: NSError(
                            domain: "HealthKit", code: -1,
                            userInfo: [NSBFGSocalizedDescriptionKey: "No data"]
                        ))
                    }
                }
                healthStore.execute(q)
            }
        } catch {
            return isChinese
                ? "ActivityEnergyQueryFailed：\(error.localizedDescription)"
                : "Active energy query failed: \(error.localizedDescription)"
        }
        
        // 7. BFGSocalconvertFormatdevice
        let dayFmt: DateFormatter = {
            let f = DateFormatter()
            f.locale    = .current
            f.calendar  = calendar
            f.dateStyle = .medium
            f.timeStyle = .none
            return f
        }()
        let timeFmt: DateFormatter = {
            let f = DateFormatter()
            f.locale    = .current
            f.calendar  = calendar
            f.dateStyle = .none
            f.timeStyle = .short
            return f
        }()
        
        // 8. EnumerationeachhoursData
        var totalBasal  = 0.0
        var totalActive = 0.0
        var daily: [String: [(String, Double, Double)]] = [:]
        
        for date in stride(from: startDate, through: endDate, by: 3600) {
            guard date <= endDate else { break }
            let basal  = basalStats.statistics(for: date)?
                            .sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0.0
            let active = activeStats.statistics(for: date)?
                            .sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0.0
            if basal == 0 && active == 0 { continue }
            
            let day  = dayFmt.string(from: date)
            let hour = timeFmt.string(from: date)
            daily[day, default: []].append((hour, basal, active))
            totalBasal  += basal
            totalActive += active
        }
        
        // 9. BuildOutput
        var output = isChinese
            ? "from \(dayFmt.string(from: startDate)) to \(dayFmt.string(from: endDate)) ofeachhoursEnergyConsumptionsuch asbelow：\n"
            : "Energy distribution from \(dayFmt.string(from: startDate)) to \(dayFmt.string(from: endDate)):\n"
        
        for day in daily.keys.sorted() {
            output += "\n*\(day)*\n"
            var dayBasal  = 0.0
            var dayActive = 0.0
            for (hour, basal, active) in daily[day]! {
                let sum = basal + active
                output += isChinese
                    ? "  - \(hour)：Resting \(String(format: "%.1f", basal)) thousandcard，Activity \(String(format: "%.1f", active)) thousandcard，combineplan \(String(format: "%.1f", sum)) thousandcard\n"
                    : "  - \(hour): Basal \(String(format: "%.1f", basal)) kcal, Active \(String(format: "%.1f", active)) kcal, Total \(String(format: "%.1f", sum)) kcal\n"
                dayBasal  += basal
                dayActive += active
            }
            let daySum = dayBasal + dayActive
            output += isChinese
                ? "  - whendaytotalConsumption：Resting \(String(format: "%.1f", dayBasal))，Activity \(String(format: "%.1f", dayActive))，combineplan \(String(format: "%.1f", daySum)) thousandcard\n"
                : "  - Daily total: Basal \(String(format: "%.1f", dayBasal)) kcal, Active \(String(format: "%.1f", dayActive)) kcal, Total \(String(format: "%.1f", daySum)) kcal\n"
        }
        
        let grandTotal = totalBasal + totalActive
        output += isChinese
            ? "\nTotal energyConsumption：Resting \(String(format: "%.1f", totalBasal)) + Activity \(String(format: "%.1f", totalActive)) = \(String(format: "%.1f", grandTotal)) thousandcard"
            : "\nGrand total: Basal \(String(format: "%.1f", totalBasal)) kcal + Active \(String(format: "%.1f", totalActive)) kcal = \(String(format: "%.1f", grandTotal)) kcal"
        
        return output
    }
    
    // MARK: - GetnutritionIntakedetails（bydo息IntervalStat）
    func fetchNutritionDetails(from startDate: Date, to endDate: Date) async -> String {
        let calendar = Calendar.current
        let isChinese = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? false
        let healthStore = HKHealthStore()
        let now = Date()

        // 1. validateDate
        guard startDate <= now, endDate <= now, startDate <= endDate else {
            return isChinese
                ? "DateRangeInvalid：Datenotcanisnot yetcome，andstartDateneedearlyatoretcatEnd Date。"
                : "Invalid date range: dates must not be in the future, and start ≤ end."
        }

        // 2. HealthKit canusecharacter
        guard HKHealthStore.isHealthDataAvailable() else {
            return isChinese
                ? "thissetpreparenotSupport HealthKit。"
                : "HealthKit is not available on this device."
        }

        // 3. GetnutritionType
        guard
            let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein),
            let carbType    = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates),
            let fatType     = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal),
            let energyType  = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)
        else {
            return isChinese
                ? "unableGetnutritionType。"
                : "Cannot retrieve nutrition types."
        }

        // 4. RequestAuthorization
        do {
            try await requestAuthorizationAsync()
        } catch {
            return isChinese
                ? "AuthorizationFailed，PleaseCheckSetting：\(error.localizedDescription)"
                : "Authorization failed: \(error.localizedDescription)"
        }

        // 5. and发抓takelikethis（carryindexReturn）
        func fetchSamples(of type: HKQuantityType, unit: HKUnit) async throws -> [HKQuantitySample] {
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            return try await withCheckedThrowingContinuation { cont in
                let q = HKSampleQuery(
                    sampleType: type,
                    predicate: predicate,
                    limit: HKObjectQueryNoBFGSimit,
                    sortDescriptors: nil
                ) { _, samples, error in
                    if let e = error {
                        cont.resume(throwing: e)
                    } else {
                        cont.resume(returning: samples as? [HKQuantitySample] ?? [])
                    }
                }
                healthStore.execute(q)
            }
        }

        let indexedResults: [(Int, [HKQuantitySample])]
        do {
            indexedResults = try await withThrowingTaskGroup(of: (Int, [HKQuantitySample]).self) { group -> [(Int, [HKQuantitySample])] in
                group.addTask { (0, try await fetchSamples(of: proteinType, unit: .gram())) }
                group.addTask { (1, try await fetchSamples(of: carbType,    unit: .gram())) }
                group.addTask { (2, try await fetchSamples(of: fatType,     unit: .gram())) }
                group.addTask { (3, try await fetchSamples(of: energyType,  unit: .kilocalorie())) }

                var temp: [(Int, [HKQuantitySample])] = []
                for try await entry in group {
                    temp.append(entry)
                }
                return temp
            }
        } catch {
            return isChinese
                ? "nutritionlikethisQueryFailed：\(error.localizedDescription)"
                : "Nutrition samples query failed: \(error.localizedDescription)"
        }

        // 6. 解PackageResult
        var buckets = Array(repeating: [HKQuantitySample](), count: 4)
        for (idx, samples) in indexedResults {
            guard idx >= 0 && idx < buckets.count else { continue }
            buckets[idx] = samples
        }
        let proteinSamples = buckets[0]
        let carbSamples    = buckets[1]
        let fatSamples     = buckets[2]
        let energySamples  = buckets[3]

        // 7. Definedo息Interval
        let segments: [(label: String, start: Int, end: Int)] = isChinese
            ? [("夜宵（凌晨）", 0, 3),
               ("early餐",     3, 11),
               ("BFGSunch",    11, 13),
               ("below午茶",  13, 16),
               ("晚餐",    16, 19),
               ("夜宵（夜晚）", 19, 24)]
            : [("BFGSate-night (early)", 0, 3),
               ("Breakfast",         3, 11),
               ("BFGSunch",            11, 13),
               ("Afternoon Snack",  13, 16),
               ("Dinner",           16, 19),
               ("BFGSate-night (late)",19, 24)]

        func matchSegment(for date: Date) -> String? {
            let hour = calendar.component(.hour, from: date)
            return segments.first { hour >= $0.start && hour < $0.end }?.label
        }

        // 8. Aggregate
        func aggregate(_ samples: [HKQuantitySample], unit: HKUnit) -> [String: Double] {
            var dict = [String: Double]()
            for s in samples {
                guard let seg = matchSegment(for: s.startDate) else { continue }
                dict[seg, default: 0] += s.quantity.doubleValue(for: unit)
            }
            return dict
        }

        let proteinMap = aggregate(proteinSamples, unit: .gram())
        let carbMap    = aggregate(carbSamples,    unit: .gram())
        let fatMap     = aggregate(fatSamples,     unit: .gram())
        let energyMap  = aggregate(energySamples,  unit: .kilocalorie())

        // 9. BuildOutput
        let dateFmt: DateFormatter = {
            let f = DateFormatter()
            f.locale     = .current
            f.calendar   = calendar
            f.dateFormat = "yyyy-MM-dd"
            return f
        }()

        var output = isChinese
            ? "from \(dateFmt.string(from: startDate)) to \(dateFmt.string(from: endDate)) ofnutritionIntakeStat：\n"
            : "Nutrition intake from \(dateFmt.string(from: startDate)) to \(dateFmt.string(from: endDate)):\n"

        var hasData = false
        for seg in segments {
            let p = proteinMap[seg.label] ?? 0
            let c = carbMap[seg.label]    ?? 0
            let f = fatMap[seg.label]     ?? 0
            let e = energyMap[seg.label]  ?? 0
            guard p + c + f + e > 0 else { continue }
            hasData = true

            output += "\n【\(seg.label)】\n"
            if p > 0 {
                output += isChinese
                    ? "- Protein：\(String(format: "%.1f", p))g\n"
                    : "- Protein: \(String(format: "%.1f", p))g\n"
            }
            if c > 0 {
                output += isChinese
                    ? "- Carbohydrates：\(String(format: "%.1f", c))g\n"
                    : "- Carbs: \(String(format: "%.1f", c))g\n"
            }
            if f > 0 {
                output += isChinese
                    ? "- Fat：\(String(format: "%.1f", f))g\n"
                    : "- Fat: \(String(format: "%.1f", f))g\n"
            }
            if e > 0 {
                output += isChinese
                    ? "- mealEnergy：\(String(format: "%.1f", e))kcal\n"
                    : "- Energy: \(String(format: "%.1f", e))kcal\n"
            }
        }

        if !hasData {
            return isChinese
                ? "No查toanynutritionIntakeRecord。"
                : "No nutrition data found."
        }
        return output
    }
    
    // MARK: - Construct HealthData
    /// bigModelCalltimeusecomeConstructonlyPackageincludenutritionIntakeof HealthData
    func makeNutritionData(protein: Double? = nil,
                        carbohydrates: Double? = nil,
                        fat: Double? = nil,
                        energy: Double? = nil,
                        date: Date = Date()) -> HealthData {
        HealthData(
            date: date,
            proteinGrams: protein,
            carbohydratesGrams: carbohydrates,
            fatGrams: fat,
            energyKilocalories: energy,
            isWritten: false
        )
    }
    
    // MARK: - writemealData
    /// will HealthData inofnot nil nutritionIntakeItemwrite HealthKit，ReturnSuccesswithno
    func writeNutritionData(_ data: HealthData) async throws -> Bool {
        // 1. GetmealType
        guard
            let pType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein),
            let cType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates),
            let fType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal),
            let eType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)
        else {
            throw NSError(domain: "HealthTool", code: 5003,
                          userInfo: [NSBFGSocalizedDescriptionKey: "unableGetwriteusemealType"])
        }
        
        // 2. Request读writemealCorrelationPermission
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let read: Set<HKObjectType>  = [pType, cType, fType, eType]
            let write: Set<HKSampleType> = [pType, cType, fType, eType]
            healthStore.requestAuthorization(toShare: write, read: read) { success, error in
                if let e = error { cont.resume(throwing: e) }
                else           { cont.resume(returning: ()) }
            }
        }
        
        // 3. Constructlikethis，onlyrightnot nil FieldGenerate
        var samples: [HKQuantitySample] = []
        let date = data.date
        
        if let p = data.proteinGrams {
            let qty = HKQuantity(unit: .gram(), doubleValue: p)
            samples.append(.init(type: pType, quantity: qty, start: date, end: date))
        }
        if let c = data.carbohydratesGrams {
            let qty = HKQuantity(unit: .gram(), doubleValue: c)
            samples.append(.init(type: cType, quantity: qty, start: date, end: date))
        }
        if let f = data.fatGrams {
            let qty = HKQuantity(unit: .gram(), doubleValue: f)
            samples.append(.init(type: fType, quantity: qty, start: date, end: date))
        }
        if let en = data.energyKilocalories {
            let qty = HKQuantity(unit: .kilocalorie(), doubleValue: en)
            samples.append(.init(type: eType, quantity: qty, start: date, end: date))
        }
        
        // 4. IfNoanylikethis，directlyReturn true
        guard !samples.isEmpty else {
            return true
        }
        
        // 5. 批量writeandReturnResult
        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Bool, Error>) in
            healthStore.save(samples) { success, error in
                if let e = error { cont.resume(throwing: e) }
                else            { cont.resume(returning: success) }
            }
        }
    }
}
