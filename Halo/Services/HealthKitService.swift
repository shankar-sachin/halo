import Foundation
import HealthKit

/// Writes logged meals to Apple Health as dietary energy, when the user has opted in.
/// `HKHealthStore` is documented as safe to use from multiple threads.
struct HealthKitService: @unchecked Sendable {
    static let shared = HealthKitService()

    private let store = HKHealthStore()
    private var energyType: HKQuantityType { HKQuantityType(.dietaryEnergyConsumed) }

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
}
