import SwiftUI

struct ContentView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        NavigationStack {
            Form {
                Section("Status") {
                    LabeledContent("Behörigheter", value: coordinator.authStatus)
                    LabeledContent("Senaste export") {
                        Text(coordinator.lastExport.map { $0.formatted(date: .abbreviated, time: .standard) } ?? "Aldrig")
                    }
                }

                Section("iCloud-mapp på enheten") {
                    Text(coordinator.iCloudPath)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }

                Section {
                    Button {
                        Task { await coordinator.exportNow() }
                    } label: {
                        if coordinator.working {
                            HStack {
                                ProgressView()
                                Text("Exporterar…")
                            }
                        } else {
                            Text("Exportera nu")
                        }
                    }
                    .disabled(coordinator.working)
                } footer: {
                    Text("Bakgrundsleverans är aktiverad — appen vaknar automatiskt ungefär en gång per dygn när ny hälsodata kommer in.")
                }
            }
            .navigationTitle("Health Export")
        }
    }
}
