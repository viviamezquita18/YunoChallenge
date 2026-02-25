# Tienda Rapida - Offline Payment Queue

## Project Context
iOS PoC for Yuno's payment orchestration challenge. Queues payments offline, auto-syncs when online.

## Tech Stack
- SwiftUI + SwiftData (iOS 17+)
- NWPathMonitor for connectivity
- MVVM + SyncEngine service layer
- Mock payment gateway (actor)

## Build
```bash
xcodebuild -project TiendaRapida/TiendaRapida.xcodeproj -scheme TiendaRapida -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Key Files
- `TiendaRapida/TiendaRapida/Services/SyncEngine.swift` - Core sync orchestration
- `TiendaRapida/TiendaRapida/Services/ConnectivityManager.swift` - Network monitoring
- `TiendaRapida/TiendaRapida/Models/Transaction.swift` - SwiftData model
