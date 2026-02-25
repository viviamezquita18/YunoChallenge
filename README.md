# Tienda Rapida - Offline Payment Queue

An iOS proof-of-concept app that queues payment transactions locally when offline and auto-syncs when connectivity returns. Built for Yuno's payment orchestration platform challenge, targeting low-connectivity markets in Latin America (Guatemala, Colombia, Peru).

## Features

- **Offline-First Architecture**: Create payment transactions without internet - they're persisted locally via SwiftData
- **Auto-Sync**: Transactions automatically process when connectivity is restored using NWPathMonitor
- **Developer Toggle**: Simulate offline mode with an in-app toggle for testing
- **Transaction Dashboard**: View, filter, sort, and search all transactions
- **Retry Failed Payments**: One-tap retry for failed transactions with exponential backoff
- **Multi-Currency Support**: GTQ (Guatemala), COP (Colombia), PEN (Peru), USD
- **Multiple Payment Methods**: Credit/debit cards, cash, bank transfer, mobile wallet
- **Idempotency**: Duplicate detection prevents double-charging via idempotency keys
- **Persistence**: All data survives app restarts via SwiftData

## Technical Stack

| Component | Technology |
|-----------|-----------|
| UI Framework | SwiftUI (iOS 17+) |
| Persistence | SwiftData |
| Connectivity | NWPathMonitor + manual toggle |
| Architecture | MVVM + SyncEngine service |
| Backend | Mocked in-app (simulated latency + random outcomes) |
| Concurrency | Swift Concurrency (async/await, actors) |
| Min Target | iOS 17.0 |

## Project Structure

```
TiendaRapida/
├── TiendaRapidaApp.swift           # App entry point + SwiftData container
├── Models/
│   ├── Transaction.swift            # @Model - SwiftData entity with status machine
│   ├── PaymentMethod.swift          # Payment method enum
│   └── Currency.swift               # Currency enum with formatting
├── Services/
│   ├── ConnectivityManager.swift    # NWPathMonitor + offline simulation
│   ├── SyncEngine.swift             # Queue management + auto-sync orchestration
│   └── MockPaymentService.swift     # Simulated payment gateway (actor)
├── ViewModels/
│   ├── TransactionFormViewModel.swift
│   └── TransactionListViewModel.swift
└── Views/
    ├── ContentView.swift            # Root view + dependency wiring
    ├── TransactionFormView.swift    # New transaction form
    ├── TransactionListView.swift    # Dashboard with filters/stats
    ├── ConnectivityBannerView.swift # Offline status banner
    └── TransactionRowView.swift     # Transaction list item
```

## Setup & Build

### Prerequisites
- macOS 14+ (Sonoma)
- Xcode 15+
- iOS 17+ Simulator or device

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/viviamezquita18/YunoChallenge.git
   cd YunoChallenge
   ```

2. **Open in Xcode**
   ```bash
   open TiendaRapida/TiendaRapida.xcodeproj
   ```

3. **Select a simulator** (iPhone 15/16 recommended)

4. **Build and run** (Cmd + R)

   Or from the command line:
   ```bash
   xcodebuild -project TiendaRapida/TiendaRapida.xcodeproj \
     -scheme TiendaRapida \
     -destination 'platform=iOS Simulator,name=iPhone 16' \
     build
   ```

## Demo Walkthrough

### 1. Create Transactions While Offline
1. Launch the app
2. Tap the **...** menu (top-left) and enable **"Simulate Offline"**
3. Notice the orange **"Offline Mode (Simulated)"** banner appears
4. Tap **+** to create a new transaction
5. Fill in amount, currency (GTQ/COP/PEN/USD), payment method, customer name, and description
6. Tap **"Queue Payment"** - the transaction is saved locally with status **Queued**
7. Create several more transactions

### 2. Watch Auto-Sync on Reconnection
1. Tap the **...** menu and disable **"Simulate Offline"**
2. The orange banner disappears
3. Watch transactions automatically transition: **Queued** → **Processing** → **Approved/Declined/Failed**
4. The stats bar at the top updates in real-time

### 3. Verify Persistence
1. Create transactions while offline
2. Force-close the app (swipe up from app switcher)
3. Reopen the app
4. All queued transactions are still there

### 4. Filter and Search
1. Use the filter chips (All, Queued, Processing, Approved, Declined, Failed)
2. Use the search bar to find transactions by customer name or description
3. Use the **...** menu to change sort order

### 5. Retry Failed Transactions
1. Find a transaction with **Failed** status
2. Tap the **"Retry"** button on the transaction row
3. The transaction resets to **Queued** and will re-process

## Mock Payment Outcomes

The MockPaymentService simulates realistic payment gateway behavior:

| Outcome | Probability | Description |
|---------|------------|-------------|
| Approved | 70% | Payment processed successfully |
| Declined | 20% | Card issues (insufficient funds, expired, blocked) |
| Failed | 10% | Network/server errors (eligible for retry) |

- Simulated latency: 0.5-2.0 seconds per transaction
- Idempotency keys prevent duplicate processing
- Exponential backoff on automatic retries (up to 3 attempts)

## Transaction State Machine

```
                    ┌─────────┐
  Create ──────────►│ Queued  │
                    └────┬────┘
                         │ (online)
                    ┌────▼────┐
                    │Processing│
                    └────┬────┘
                    ┌────┼────┐
               ┌────▼─┐ │ ┌──▼───┐
               │Approved│ │ │Failed│──► Retry ──► Queued
               └───────┘ │ └──────┘
                    ┌─────▼────┐
                    │ Declined │
                    └──────────┘
```

## Production Considerations

This is a proof-of-concept. For production deployment, consider:

- **Real Payment Gateway**: Replace MockPaymentService with Yuno SDK integration
- **Authentication**: Add user auth (OAuth/JWT) and associate transactions with merchants
- **Encryption**: Encrypt sensitive data at rest (card numbers, PII)
- **Certificate Pinning**: Protect API communication
- **Server-Side Idempotency**: Implement idempotency key validation on the backend
- **Conflict Resolution**: Handle concurrent edits from multiple devices
- **Push Notifications**: Notify users when offline transactions are processed
- **Analytics**: Track sync success rates, latency, and failure patterns
- **Accessibility**: Full VoiceOver support, Dynamic Type
- **Localization**: Spanish translations for target markets
- **Background Sync**: Use BGTaskScheduler for sync when app is backgrounded

## Architecture

See [docs/architecture.md](docs/architecture.md) for detailed architecture documentation.

## License

Built for the Yuno Payment Orchestration Challenge.
