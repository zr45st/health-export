import Foundation
import HealthKit
import os

final class ObserverManager {
    private let store: HKHealthStore
    private let fetcher: SampleFetcher
    private let writer: ExportWriter
    private let anchorStore: AnchorStore
    private let logger = Logger(subsystem: "HealthExport", category: "Observer")

    private var activeQueries: [HKObserverQuery] = []

    init(store: HKHealthStore, fetcher: SampleFetcher, writer: ExportWriter, anchorStore: AnchorStore) {
        self.store = store
        self.fetcher = fetcher
        self.writer = writer
        self.anchorStore = anchorStore
    }

    func startObserving() async {
        for type in HealthTypes.allSampleTypes {
            do {
                try await store.enableBackgroundDelivery(for: type, frequency: .daily)
            } catch {
                logger.error("enableBackgroundDelivery failed for \(type.identifier, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }

            let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completionHandler, error in
                guard let self = self else { completionHandler(); return }
                if let error = error {
                    self.logger.error("Observer error for \(type.identifier, privacy: .public): \(error.localizedDescription, privacy: .public)")
                    completionHandler()
                    return
                }
                Task {
                    await self.exportNewSamples(for: type)
                    completionHandler()
                }
            }
            store.execute(query)
            activeQueries.append(query)
        }
    }

    func exportAllNow() async {
        for type in HealthTypes.allSampleTypes {
            await exportNewSamples(for: type)
        }
        anchorStore.setLastExportDate(Date())
    }

    private func exportNewSamples(for type: HKSampleType) async {
        do {
            let result = try await fetcher.fetchNew(for: type)
            try await writer.append(samples: result.samples, for: type.identifier)
            anchorStore.save(result.newAnchor, for: type.identifier)
            anchorStore.setLastExportDate(Date())
            logger.info("Exported \(result.samples.count, privacy: .public) samples for \(type.identifier, privacy: .public)")
        } catch {
            logger.error("Export failed for \(type.identifier, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }
}
