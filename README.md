# Health Export

Liten iPhone-app som dagligen exporterar all tillgänglig Apple Health-data
till en JSON-fil per dag i en iCloud Drive-mapp som synkas till din MacBook.

## Hur det fungerar

1. Appen begär läsbehörighet till hela listan av HealthKit-typer
   (`HealthExport/HealthKit/HealthTypes.swift`).
2. För varje typ registreras en `HKObserverQuery` med
   `enableBackgroundDelivery(frequency: .daily)`. iOS väcker appen ungefär
   en gång per dygn när ny data finns.
3. När appen vaknar hämtar den bara nya samples (`HKAnchoredObjectQuery`
   med sparad anchor per typ), serialiserar till JSON och skriver/uppdaterar
   `Documents/YYYY-MM-DD.json` i appens iCloud-container.
4. iCloud Drive synkar mappen till din Mac under
   `~/Library/Mobile Documents/iCloud~se~zr45st~HealthExport/Documents/`.

## Förutsättningar

- **Apple Developer Program** ($99/år) — krävs för iCloud-entitlement.
- **Xcode 15+** på Mac.
- **iPhone med iOS 17+**.
- **XcodeGen** (`brew install xcodegen`) — genererar `.xcodeproj` från
  `project.yml` så vi slipper committa Xcodes interna projektfil.

## Setup

Bundle-ID är konfigurerat till `se.zr45st.HealthExport` och iCloud-containern
till `iCloud.se.zr45st.HealthExport`.

1. **Generera Xcode-projekt:**
   ```bash
   xcodegen generate
   ```
2. **Öppna** `HealthExport.xcodeproj` i Xcode.
3. **Signing & Capabilities** → välj ditt Team.
4. **Anslut iPhone** och kör (▶︎). Första bygget tar ett par minuter.
5. När appen startat på telefonen: bevilja alla hälsokategorier i dialogen.
6. Tryck **"Exportera nu"** för en första körning.

## Verifiering

- **På iPhone:** Files-app → iCloud Drive → HealthExport → `YYYY-MM-DD.json`
  ska finnas och innehålla JSON.
- **På Mac:**
  ```bash
  ls -la ~/Library/Mobile\ Documents/iCloud~se~zr45st~HealthExport/Documents/
  ```
- **Daglig automatik:** Lämna iPhone i fred i ett dygn. Nästa dag ska en
  ny fil ha skapats utan att du öppnat appen.

## Filformat

```json
{
  "date": "2026-05-24",
  "exportedAt": "2026-05-24T23:50:11Z",
  "samples": {
    "HKQuantityTypeIdentifierStepCount": [
      {
        "start": "2026-05-24T08:12:00Z",
        "end":   "2026-05-24T08:14:00Z",
        "value": 142,
        "unit":  "count",
        "source": "iPhone",
        "device": "iPhone 15 Pro",
        "metadata": null
      }
    ]
  },
  "workouts": [
    {
      "activityType": "running",
      "start": "2026-05-24T17:30:00Z",
      "end":   "2026-05-24T18:00:00Z",
      "duration": 1800,
      "totalDistanceMeters": 5000,
      "totalEnergyKcal": 320,
      "source": "Apple Watch",
      "metadata": { "HKWeatherTemperature": "..." }
    }
  ]
}
```

## Att veta

- **Bakgrundsfrekvens** är `.daily` — iOS levererar "ungefär en gång per
  dygn", inte exakt midnatt. Om telefonen är avstängd länge kan en
  uppvakning hoppas över; nästa gång appen vaknar plockar
  `HKAnchoredObjectQuery` upp allt som missats sedan förra anchor.
- **Throttling**: iOS kan slå tillbaka bakgrundsleverans om appen aldrig
  öppnas av användaren. Öppna appen någon gång i månaden för att hålla
  igång den.
- **Symptom-kategorier**: iOS exponerar dessa via `HKCategoryType` med ett
  heltal `category` istället för `value`/`unit`. Tolkningen finns i Apples
  `HKCategoryValue*`-enum.
- **Tidszon**: Dagfilerna grupperas på samplets `startDate` i lokal tidszon
  vid skrivtillfället.

## Filstruktur

```
health-export/
├── project.yml                        XcodeGen-spec
├── README.md
├── .gitignore
└── HealthExport/
    ├── HealthExportApp.swift          @main + AppCoordinator
    ├── ContentView.swift              SwiftUI-UI
    ├── Info.plist
    ├── HealthExport.entitlements
    ├── HealthKit/
    │   ├── HealthTypes.swift          Enumeration av alla typer
    │   ├── HealthAuthorization.swift  Behörighetsbegäran
    │   ├── ObserverManager.swift      Observer + background delivery
    │   └── SampleFetcher.swift        Anchored query + enhetsmappning
    ├── Export/
    │   ├── ExportRecord.swift         Codable-modeller
    │   └── ExportWriter.swift         iCloud-skrivning via NSFileCoordinator
    └── Storage/
        └── AnchorStore.swift          Sparar HKQueryAnchor per typ
```

## Fallback (utan $99/år)

iOS Genvägar + Personlig Automation kan trigga en daglig genväg som
hämtar valda hälsovärden och sparar dem som en fil i en iCloud Drive-mapp
du själv äger. Täcker dock inte alla HealthKit-typer (workouts och
sömnstadier är begränsade) och passar bara om du nöjer dig med en handfull
mätvärden.
