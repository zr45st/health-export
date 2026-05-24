import HealthKit

enum HealthTypes {
    static let quantityIdentifiers: [HKQuantityTypeIdentifier] = [
        .stepCount,
        .distanceWalkingRunning,
        .distanceCycling,
        .distanceSwimming,
        .flightsClimbed,
        .activeEnergyBurned,
        .basalEnergyBurned,
        .appleExerciseTime,
        .appleStandTime,
        .appleMoveTime,
        .vo2Max,
        .heartRate,
        .restingHeartRate,
        .walkingHeartRateAverage,
        .heartRateVariabilitySDNN,
        .heartRateRecoveryOneMinute,
        .oxygenSaturation,
        .respiratoryRate,
        .bloodPressureSystolic,
        .bloodPressureDiastolic,
        .peripheralPerfusionIndex,
        .bodyMass,
        .bodyFatPercentage,
        .bodyMassIndex,
        .height,
        .leanBodyMass,
        .waistCircumference,
        .dietaryWater,
        .dietaryEnergyConsumed,
        .dietaryProtein,
        .dietaryCarbohydrates,
        .dietaryFatTotal,
        .environmentalAudioExposure,
        .headphoneAudioExposure,
        .uvExposure,
        .numberOfTimesFallen,
        .walkingSpeed,
        .walkingStepLength,
        .walkingAsymmetryPercentage,
        .walkingDoubleSupportPercentage,
        .sixMinuteWalkTestDistance,
        .runningPower,
        .runningSpeed,
        .runningStrideLength,
        .runningVerticalOscillation,
        .runningGroundContactTime
    ]

    static let categoryIdentifiers: [HKCategoryTypeIdentifier] = [
        .sleepAnalysis,
        .mindfulSession,
        .appleStandHour,
        .highHeartRateEvent,
        .lowHeartRateEvent,
        .irregularHeartRhythmEvent,
        .headache,
        .nausea,
        .abdominalCramps,
        .bloating,
        .breastPain,
        .chestTightnessOrPain,
        .chills,
        .constipation,
        .coughing,
        .diarrhea,
        .dizziness,
        .drySkin,
        .fainting,
        .fatigue,
        .fever,
        .generalizedBodyAche,
        .hairLoss,
        .heartburn,
        .hotFlashes,
        .lossOfSmell,
        .lossOfTaste,
        .lowerBackPain,
        .memoryLapse,
        .moodChanges,
        .nightSweats,
        .pelvicPain,
        .rapidPoundingOrFlutteringHeartbeat,
        .runnyNose,
        .shortnessOfBreath,
        .sinusCongestion,
        .skippedHeartbeat,
        .soreThroat,
        .vomiting,
        .wheezing
    ]

    static let characteristicIdentifiers: [HKCharacteristicTypeIdentifier] = [
        .biologicalSex,
        .dateOfBirth,
        .bloodType,
        .fitzpatrickSkinType
    ]

    static var quantityTypes: [HKQuantityType] {
        quantityIdentifiers.compactMap { HKObjectType.quantityType(forIdentifier: $0) }
    }

    static var categoryTypes: [HKCategoryType] {
        categoryIdentifiers.compactMap { HKObjectType.categoryType(forIdentifier: $0) }
    }

    static var allSampleTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = []
        for q in quantityTypes { types.insert(q) }
        for c in categoryTypes { types.insert(c) }
        types.insert(HKWorkoutType.workoutType())
        return types
    }

    static var allReadTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        for s in allSampleTypes { types.insert(s) }
        for id in characteristicIdentifiers {
            if let c = HKObjectType.characteristicType(forIdentifier: id) {
                types.insert(c)
            }
        }
        return types
    }
}
