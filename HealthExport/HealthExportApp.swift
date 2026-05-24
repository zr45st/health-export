import SwiftUI
import HealthKit

@main
struct HealthExportApp: App {
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            ContentView(coordinator: coordinator)
                .task { await coordinator.bootstrap() }
        }
    }
}

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var authStatus: String = "Inte begärt"
    @Published var lastExport: Date?
    @Published var iCloudPath: String = "—"
    @Published var working = false

    private let store = HKHealthStore()
    private let anchorStore = AnchorStore()
    private lazy var fetcher = SampleFetcher(store: store, anchorStore: anchorStore)
    private let writer = ExportWriter()
    private lazy var observer = ObserverManager(
        store: store,
        fetcher: fetcher,
        writer: writer,
        anchorStore: anchorStore
    )

    func bootstrap() async {
        lastExport = anchorStore.lastExportDate
        if let url = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
            iCloudPath = url.appendingPathComponent("Documents").path
        } else {
            iCloudPath = "iCloud ej tillgängligt (logga in iCloud + aktivera iCloud Drive)"
        }

        switch await HealthAuthorization.requestAll(store: store) {
        case .unknown: authStatus = "Okänd"
        case .unavailable: authStatus = "HealthKit ej tillgängligt"
        case .requested: authStatus = "Begärt"
        case .failed(let msg): authStatus = "Fel: \(msg)"
        }

        await observer.startObserving()
    }

    func exportNow() async {
        working = true
        defer { working = false }
        await observer.exportAllNow()
        lastExport = anchorStore.lastExportDate
    }
}
