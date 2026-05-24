import Foundation

struct SampleRecord: Codable {
    let start: Date
    let end: Date
    let value: Double?
    let unit: String?
    let category: Int?
    let source: String
    let device: String?
    let metadata: [String: String]?
}

struct WorkoutRecord: Codable {
    let activityType: String
    let start: Date
    let end: Date
    let duration: TimeInterval
    let totalDistanceMeters: Double?
    let totalEnergyKcal: Double?
    let source: String
    let metadata: [String: String]?
}

struct DailyExport: Codable {
    let date: String           // yyyy-MM-dd, local timezone
    var exportedAt: Date
    var samples: [String: [SampleRecord]]
    var workouts: [WorkoutRecord]
}
