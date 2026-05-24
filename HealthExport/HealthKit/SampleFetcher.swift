import Foundation
import HealthKit

struct FetchResult {
    let samples: [HKSample]
    let deleted: [HKDeletedObject]
    let newAnchor: HKQueryAnchor
}

final class SampleFetcher {
    private let store: HKHealthStore
    private let anchorStore: AnchorStore

    init(store: HKHealthStore, anchorStore: AnchorStore) {
        self.store = store
        self.anchorStore = anchorStore
    }

    func fetchNew(for type: HKSampleType) async throws -> FetchResult {
        let key = type.identifier
        let previousAnchor = anchorStore.anchor(for: key)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKAnchoredObjectQuery(
                type: type,
                predicate: nil,
                anchor: previousAnchor,
                limit: HKObjectQueryNoLimit
            ) { _, samples, deleted, anchor, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: FetchResult(
                    samples: samples ?? [],
                    deleted: deleted ?? [],
                    newAnchor: anchor ?? HKQueryAnchor(fromValue: 0)
                ))
            }
            self.store.execute(query)
        }
    }
}

extension HKQuantityType {
    var preferredUnit: HKUnit {
        switch identifier {
        case HKQuantityTypeIdentifier.stepCount.rawValue,
             HKQuantityTypeIdentifier.flightsClimbed.rawValue,
             HKQuantityTypeIdentifier.numberOfTimesFallen.rawValue,
             HKQuantityTypeIdentifier.uvExposure.rawValue,
             HKQuantityTypeIdentifier.bodyMassIndex.rawValue:
            return .count()

        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue,
             HKQuantityTypeIdentifier.distanceCycling.rawValue,
             HKQuantityTypeIdentifier.distanceSwimming.rawValue,
             HKQuantityTypeIdentifier.sixMinuteWalkTestDistance.rawValue,
             HKQuantityTypeIdentifier.runningStrideLength.rawValue,
             HKQuantityTypeIdentifier.walkingStepLength.rawValue,
             HKQuantityTypeIdentifier.height.rawValue,
             HKQuantityTypeIdentifier.waistCircumference.rawValue,
             HKQuantityTypeIdentifier.runningVerticalOscillation.rawValue:
            return .meter()

        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue,
             HKQuantityTypeIdentifier.basalEnergyBurned.rawValue,
             HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue:
            return .kilocalorie()

        case HKQuantityTypeIdentifier.appleExerciseTime.rawValue,
             HKQuantityTypeIdentifier.appleStandTime.rawValue,
             HKQuantityTypeIdentifier.appleMoveTime.rawValue,
             HKQuantityTypeIdentifier.runningGroundContactTime.rawValue:
            return .second()

        case HKQuantityTypeIdentifier.heartRate.rawValue,
             HKQuantityTypeIdentifier.restingHeartRate.rawValue,
             HKQuantityTypeIdentifier.walkingHeartRateAverage.rawValue,
             HKQuantityTypeIdentifier.respiratoryRate.rawValue,
             HKQuantityTypeIdentifier.heartRateRecoveryOneMinute.rawValue:
            return HKUnit.count().unitDivided(by: .minute())

        case HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue:
            return .secondUnit(with: .milli)

        case HKQuantityTypeIdentifier.oxygenSaturation.rawValue,
             HKQuantityTypeIdentifier.bodyFatPercentage.rawValue,
             HKQuantityTypeIdentifier.walkingAsymmetryPercentage.rawValue,
             HKQuantityTypeIdentifier.walkingDoubleSupportPercentage.rawValue,
             HKQuantityTypeIdentifier.peripheralPerfusionIndex.rawValue:
            return .percent()

        case HKQuantityTypeIdentifier.bodyMass.rawValue,
             HKQuantityTypeIdentifier.leanBodyMass.rawValue:
            return .gramUnit(with: .kilo)

        case HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue,
             HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue:
            return .millimeterOfMercury()

        case HKQuantityTypeIdentifier.dietaryWater.rawValue:
            return .literUnit(with: .milli)

        case HKQuantityTypeIdentifier.dietaryProtein.rawValue,
             HKQuantityTypeIdentifier.dietaryCarbohydrates.rawValue,
             HKQuantityTypeIdentifier.dietaryFatTotal.rawValue:
            return .gram()

        case HKQuantityTypeIdentifier.environmentalAudioExposure.rawValue,
             HKQuantityTypeIdentifier.headphoneAudioExposure.rawValue:
            return .decibelAWeightedSoundPressureLevel()

        case HKQuantityTypeIdentifier.vo2Max.rawValue:
            return HKUnit(from: "ml/kg*min")

        case HKQuantityTypeIdentifier.runningSpeed.rawValue,
             HKQuantityTypeIdentifier.walkingSpeed.rawValue:
            return HKUnit.meter().unitDivided(by: .second())

        case HKQuantityTypeIdentifier.runningPower.rawValue:
            return HKUnit(from: "W")

        default:
            return .count()
        }
    }
}
