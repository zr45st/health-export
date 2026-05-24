import Foundation
import HealthKit

actor ExportWriter {
    enum WriterError: Error {
        case iCloudUnavailable
    }

    private let containerID: String?
    private let fileManager = FileManager.default

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init(containerID: String? = nil) {
        self.containerID = containerID
    }

    private func documentsURL() throws -> URL {
        guard let containerURL = fileManager.url(forUbiquityContainerIdentifier: containerID) else {
            throw WriterError.iCloudUnavailable
        }
        let docs = containerURL.appendingPathComponent("Documents", isDirectory: true)
        if !fileManager.fileExists(atPath: docs.path) {
            try fileManager.createDirectory(at: docs, withIntermediateDirectories: true)
        }
        return docs
    }

    func append(samples: [HKSample], for typeIdentifier: String) throws {
        guard !samples.isEmpty else { return }
        let docs = try documentsURL()
        let grouped = Dictionary(grouping: samples) { dayFormatter.string(from: $0.startDate) }
        for (day, daySamples) in grouped {
            let fileURL = docs.appendingPathComponent("\(day).json")
            var export = (try? load(from: fileURL)) ?? DailyExport(
                date: day,
                exportedAt: Date(),
                samples: [:],
                workouts: []
            )
            export.exportedAt = Date()
            for sample in daySamples {
                if let workout = sample as? HKWorkout {
                    export.workouts.append(WorkoutRecord(from: workout))
                } else {
                    let record = SampleRecord(from: sample)
                    export.samples[typeIdentifier, default: []].append(record)
                }
            }
            try save(export, to: fileURL)
        }
    }

    private func load(from url: URL) throws -> DailyExport? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(DailyExport.self, from: data)
    }

    private func save(_ export: DailyExport, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(export)

        var coordinatorError: NSError?
        var writeError: Error?
        NSFileCoordinator().coordinate(
            writingItemAt: url,
            options: .forReplacing,
            error: &coordinatorError
        ) { writeURL in
            do {
                try data.write(to: writeURL, options: .atomic)
            } catch {
                writeError = error
            }
        }
        if let err = coordinatorError { throw err }
        if let err = writeError { throw err }
    }
}

extension SampleRecord {
    init(from sample: HKSample) {
        var value: Double? = nil
        var unit: String? = nil
        var category: Int? = nil

        if let q = sample as? HKQuantitySample, let qType = sample.sampleType as? HKQuantityType {
            let u = qType.preferredUnit
            value = q.quantity.doubleValue(for: u)
            unit = u.unitString
        } else if let c = sample as? HKCategorySample {
            category = c.value
        }

        self.start = sample.startDate
        self.end = sample.endDate
        self.value = value
        self.unit = unit
        self.category = category
        self.source = sample.sourceRevision.source.name
        self.device = sample.device?.name
        self.metadata = sample.metadata?.mapValues { "\($0)" }
    }
}

extension WorkoutRecord {
    init(from workout: HKWorkout) {
        self.activityType = workout.workoutActivityType.name
        self.start = workout.startDate
        self.end = workout.endDate
        self.duration = workout.duration
        self.totalDistanceMeters = workout.totalDistance?.doubleValue(for: .meter())
        self.totalEnergyKcal = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie())
        self.source = workout.sourceRevision.source.name
        self.metadata = workout.metadata?.mapValues { "\($0)" }
    }
}

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "running"
        case .walking: return "walking"
        case .cycling: return "cycling"
        case .swimming: return "swimming"
        case .hiking: return "hiking"
        case .yoga: return "yoga"
        case .pilates: return "pilates"
        case .functionalStrengthTraining: return "functionalStrengthTraining"
        case .traditionalStrengthTraining: return "traditionalStrengthTraining"
        case .highIntensityIntervalTraining: return "hiit"
        case .coreTraining: return "coreTraining"
        case .crossTraining: return "crossTraining"
        case .elliptical: return "elliptical"
        case .rowing: return "rowing"
        case .stairs, .stairClimbing: return "stairs"
        case .tennis: return "tennis"
        case .soccer: return "soccer"
        case .basketball: return "basketball"
        case .dance: return "dance"
        case .mindAndBody: return "mindAndBody"
        case .other: return "other"
        default: return "type_\(rawValue)"
        }
    }
}
