import Foundation

struct HealthSnapshot: Hashable {
    var sleepHours: Double?
    var weightKg: Double?
    var sourceLabel: String
}

enum HealthDataService {
    static func authorizationStatusDescription() -> String {
        #if !SKIP && canImport(HealthKit)
        return HealthKitBridge.isAvailable ? "Available on this iPhone" : "Health data unavailable"
        #else
        return "Manual logging on Android — Health Connect coming soon"
        #endif
    }

    static func requestAuthorization() async -> Bool {
        #if !SKIP && canImport(HealthKit)
        await HealthKitBridge.requestAuthorization()
        #else
        false
        #endif
    }

    static func fetchRecentSnapshot() async -> HealthSnapshot {
        #if !SKIP && canImport(HealthKit)
        await HealthKitBridge.fetchSnapshot()
        #else
        HealthSnapshot(sleepHours: nil, weightKg: nil, sourceLabel: "Manual entry")
        #endif
    }

    static func importIntoStore(_ store: WellnessStore, snapshot: HealthSnapshot) {
        if let hours = snapshot.sleepHours, hours > 0 {
            let minutes = Int(hours * 60) % 60
            let wholeHours = Int(hours)
            let quality = min(100, max(50, Int(hours / 8.0 * 100)))
            store.logSleep(hours: wholeHours, minutes: minutes, quality: quality)
        }
        if let weight = snapshot.weightKg, weight > 0 {
            store.logWeight(weight)
        }
    }
}

#if !SKIP && canImport(HealthKit)
import HealthKit

enum HealthKitBridge {
    private static let store = HKHealthStore()

    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    static func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!
        ]

        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            return true
        } catch {
            logger.error("HealthKit authorization failed: \(error.localizedDescription)")
            return false
        }
    }

    static func fetchSnapshot() async -> HealthSnapshot {
        guard isAvailable else {
            return HealthSnapshot(sleepHours: nil, weightKg: nil, sourceLabel: "HealthKit unavailable")
        }

        async let sleep = latestSleepHours()
        async let weight = latestWeightKg()
        let sleepHours = await sleep
        let weightKg = await weight

        return HealthSnapshot(
            sleepHours: sleepHours,
            weightKg: weightKg,
            sourceLabel: "Apple Health"
        )
    }

    private static func latestSleepHours() async -> Double? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        let start = Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]

                let total = samples
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { partial, sample in
                        partial + sample.endDate.timeIntervalSince(sample.startDate)
                    }

                continuation.resume(returning: total > 0 ? total / 3600.0 : nil)
            }
            store.execute(query)
        }
    }

    private static func latestWeightKg() async -> Double? {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            return nil
        }

        let start = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: kg)
            }
            store.execute(query)
        }
    }
}
#endif
