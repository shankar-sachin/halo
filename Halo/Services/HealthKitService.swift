import Foundation
import HealthKit

/// A workout read from Apple Health (recorded on Apple Watch / Apple Fitness).
struct HealthWorkout: Identifiable, Sendable {
    let id: UUID
    let type: String
    let durationMinutes: Int
    let calories: Int
    let date: Date
    let symbol: String
}

/// A body-weight sample read from Apple Health.
struct HealthWeight: Identifiable, Sendable {
    let id: UUID
    let weightKg: Double
    let date: Date
}

/// A night's sleep duration read from Apple Health (aggregated across asleep stages).
struct HealthSleepNight: Identifiable, Sendable {
    let id: UUID
    let hoursAsleep: Double
    let date: Date
}

/// Reads/writes Apple Health: writes logged meals as dietary energy, and reads workouts recorded
/// by Apple Watch / Apple Fitness. `HKHealthStore` is documented as safe to use across threads.
struct HealthKitService: @unchecked Sendable {
    static let shared = HealthKitService()

    private let store = HKHealthStore()
    private var energyType: HKQuantityType { HKQuantityType(.dietaryEnergyConsumed) }
    private var activeEnergyType: HKQuantityType { HKQuantityType(.activeEnergyBurned) }
    private var bodyMassType: HKQuantityType { HKQuantityType(.bodyMass) }
    private var sleepType: HKCategoryType { HKCategoryType(.sleepAnalysis) }
    private var stepCountType: HKQuantityType { HKQuantityType(.stepCount) }

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// Requests permission to write dietary energy. Returns whether sharing is authorized.
    @discardableResult
    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [energyType], read: [energyType])
            return store.authorizationStatus(for: energyType) == .sharingAuthorized
        } catch {
            return false
        }
    }

    /// Saves a calorie amount to Health at the given date. Silently no-ops if unavailable.
    func save(calories: Int, at date: Date) async {
        guard isAvailable, calories > 0 else { return }
        if store.authorizationStatus(for: energyType) != .sharingAuthorized {
            guard await requestAuthorization() else { return }
        }
        let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: Double(calories))
        let sample = HKQuantitySample(type: energyType, quantity: quantity, start: date, end: date)
        try? await store.save(sample)
    }

    // MARK: - Reading workouts (Apple Watch / Apple Fitness)

    /// Requests read access to workouts + active energy. Read authorization status can't be queried
    /// (HealthKit hides it for privacy), so callers just attempt the query afterward.
    @discardableResult
    func requestWorkoutAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: [HKObjectType.workoutType(), activeEnergyType])
            return true
        } catch {
            return false
        }
    }

    /// Fetches the most recent workouts recorded in Apple Health, newest first. Returns `[]` when
    /// unavailable or not authorized.
    func recentWorkouts(limit: Int = 30) async -> [HealthWorkout] {
        guard isAvailable, await requestWorkoutAuthorization() else { return [] }
        let activeEnergy = activeEnergyType
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: nil,
                limit: limit,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let workouts = (samples as? [HKWorkout]) ?? []
                let mapped = workouts.map { workout -> HealthWorkout in
                    let kcal = workout.statistics(for: activeEnergy)?
                        .sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                    return HealthWorkout(
                        id: workout.uuid,
                        type: Self.name(for: workout.workoutActivityType),
                        durationMinutes: max(Int((workout.duration / 60).rounded()), 0),
                        calories: Int(kcal.rounded()),
                        date: workout.startDate,
                        symbol: Self.symbol(for: workout.workoutActivityType)
                    )
                }
                continuation.resume(returning: mapped)
            }
            store.execute(query)
        }
    }

    // MARK: - Daily activity (steps + active energy, read)

    /// Requests read access to steps and active energy. Read status can't be queried, so callers
    /// just attempt the query afterward.
    @discardableResult
    func requestActivityAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: [stepCountType, activeEnergyType])
            return true
        } catch {
            return false
        }
    }

    /// Today's step count and active energy burned, read-only from Apple Health. Returns zeros
    /// when unavailable or not authorized.
    func todayActivity() async -> (steps: Int, activeKcal: Int) {
        guard isAvailable, await requestActivityAuthorization() else { return (0, 0) }
        let steps = await todaySum(stepCountType, unit: .count())
        let kcal = await todaySum(activeEnergyType, unit: .kilocalorie())
        return (Int(steps), Int(kcal))
    }

    /// Cumulative sum of a quantity type since the start of today (0 on failure/no data).
    private func todaySum(_ type: HKQuantityType, unit: HKUnit) async -> Double {
        let start = Calendar.current.startOfDay(for: .now)
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: .now, options: .strictStartDate)
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                continuation.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(query)
        }
    }

    // MARK: - Body weight (read + write)

    /// Requests read+write access to body mass. Returns whether sharing is authorized.
    @discardableResult
    func requestWeightAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [bodyMassType], read: [bodyMassType])
            return store.authorizationStatus(for: bodyMassType) == .sharingAuthorized
        } catch {
            return false
        }
    }

    /// Saves a weight measurement (in kilograms) to Health. Silently no-ops if unavailable.
    func saveWeight(kg: Double, at date: Date = .now) async {
        guard isAvailable, kg > 0 else { return }
        if store.authorizationStatus(for: bodyMassType) != .sharingAuthorized {
            guard await requestWeightAuthorization() else { return }
        }
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        let sample = HKQuantitySample(type: bodyMassType, quantity: quantity, start: date, end: date)
        try? await store.save(sample)
    }

    /// Fetches recent body-weight samples from Apple Health, newest first.
    func recentWeights(limit: Int = 30) async -> [HealthWeight] {
        guard isAvailable, await requestWeightAuthorization() else { return [] }
        let unit = HKUnit.gramUnit(with: .kilo)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: limit, sortDescriptors: [sort]) { _, samples, _ in
                let mapped = ((samples as? [HKQuantitySample]) ?? []).map {
                    HealthWeight(id: $0.uuid, weightKg: $0.quantity.doubleValue(for: unit), date: $0.startDate)
                }
                continuation.resume(returning: mapped)
            }
            store.execute(query)
        }
    }

    // MARK: - Sleep (read)

    /// Requests read access to sleep analysis. Read status can't be queried, so callers just query.
    @discardableResult
    func requestSleepAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: [sleepType])
            return true
        } catch {
            return false
        }
    }

    /// Fetches sleep for the last `nights` nights, summed across asleep stages and bucketed by the
    /// morning the user woke. Newest night first. Returns `[]` when unavailable or unauthorized.
    func recentSleep(nights: Int = 14) async -> [HealthSleepNight] {
        guard isAvailable, await requestSleepAuthorization() else { return [] }
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -(nights + 1), to: .now) ?? .now
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now, options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let asleepValues = Self.asleepValues
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
                let categorySamples = (samples as? [HKCategorySample]) ?? []
                // Sum "asleep" seconds per night, keyed by the day the sample ended (the morning).
                var perNight: [Date: TimeInterval] = [:]
                for sample in categorySamples where asleepValues.contains(sample.value) {
                    let morning = calendar.startOfDay(for: sample.endDate)
                    perNight[morning, default: 0] += max(sample.endDate.timeIntervalSince(sample.startDate), 0)
                }
                let nights = perNight
                    .map { HealthSleepNight(id: UUID(), hoursAsleep: $0.value / 3600, date: $0.key) }
                    .sorted { $0.date > $1.date }
                continuation.resume(returning: nights)
            }
            store.execute(query)
        }
    }

    /// `HKCategoryValueSleepAnalysis` raw values that count as actually asleep (not "in bed"/"awake").
    private static let asleepValues: Set<Int> = [
        HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
        HKCategoryValueSleepAnalysis.asleepCore.rawValue,
        HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
        HKCategoryValueSleepAnalysis.asleepREM.rawValue,
    ]

    private static func name(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: "Run"
        case .walking: "Walk"
        case .cycling: "Cycling"
        case .swimming: "Swim"
        case .traditionalStrengthTraining, .functionalStrengthTraining: "Strength"
        case .hiking: "Hike"
        case .yoga: "Yoga"
        case .pilates: "Pilates"
        case .highIntensityIntervalTraining: "HIIT"
        case .rowing: "Rowing"
        case .elliptical: "Elliptical"
        case .coreTraining: "Core"
        case .dance, .cardioDance: "Dance"
        default: "Workout"
        }
    }

    private static func symbol(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: "figure.run"
        case .walking: "figure.walk"
        case .cycling: "figure.outdoor.cycle"
        case .swimming: "figure.pool.swim"
        case .traditionalStrengthTraining, .functionalStrengthTraining: "dumbbell.fill"
        case .hiking: "figure.hiking"
        case .yoga: "figure.yoga"
        case .pilates: "figure.pilates"
        case .highIntensityIntervalTraining: "figure.highintensity.intervaltraining"
        case .rowing: "figure.rower"
        case .elliptical: "figure.elliptical"
        case .coreTraining: "figure.core.training"
        case .dance, .cardioDance: "figure.dance"
        default: "figure.mixed.cardio"
        }
    }
}
