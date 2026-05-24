import Foundation
import HealthKit

final class AnchorStore {
    private let defaults: UserDefaults
    private let anchorPrefix = "anchor."
    private let lastExportKey = "lastExportDate"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func anchor(for key: String) -> HKQueryAnchor? {
        guard let data = defaults.data(forKey: anchorPrefix + key) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
    }

    func save(_ anchor: HKQueryAnchor, for key: String) {
        guard let data = try? NSKeyedArchiver.archivedData(
            withRootObject: anchor,
            requiringSecureCoding: true
        ) else { return }
        defaults.set(data, forKey: anchorPrefix + key)
    }

    var lastExportDate: Date? {
        defaults.object(forKey: lastExportKey) as? Date
    }

    func setLastExportDate(_ date: Date) {
        defaults.set(date, forKey: lastExportKey)
    }
}
