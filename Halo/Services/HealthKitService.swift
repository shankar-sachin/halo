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

/// Reads/writes Apple Health: writes logged meals as dietary energy, and reads workouts recorded
/// by Apple Watch / Apple Fitness. `HKHealthStore` is documented as safe to use across threads.
struct HealthKitService: @unchecked Sendable {
    static let shared = HealthKitService()

    private let store = HKHealthStore()
    private var energyType: HKQuantityType { HKQuantityType(.dietaryEnergyConsumed) }
    private var activeEnergyType: HKQuantityType { HKQuantityType(.activeEnergyBurned) }

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
