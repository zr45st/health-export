import Foundation
import HealthKit

enum HealthAuthorization {
    enum Status: Equatable {
        case unknown
        case unavailable
        case requested
        case failed(String)
    }

    static func requestAll(store: HKHealthStore) async -> Status {
        guard HKHealthStore.isHealthDataAvailable() else { return .unavailable }
        do {
            try await store.requestAuthorization(toShare: [], read: HealthTypes.allReadTypes)
            return .requested
        } catch {
            return .failed(error.localizedDescription)
        }
    }
}
