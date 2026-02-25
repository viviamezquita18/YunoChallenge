# Architecture Documentation

## Overview

Tienda Rapida follows an **MVVM + Service Layer** architecture pattern, designed around an offline-first principle where transactions are always persisted locally before any network activity.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                     Views (SwiftUI)                  │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ │
│  │TransactionForm│ │TransactionList│ │Connectivity  │ │
│  │    View       │ │    View       │ │ BannerView   │ │
│  └──────┬───────┘ └──────┬───────┘ └──────────────┘ │
│         │                │                           │
├─────────┼────────────────┼───────────────────────────┤
│         ▼                ▼       ViewModels          │
│  ┌──────────────┐ ┌──────────────┐                   │
│  │TransactionForm│ │TransactionList│                  │
│  │  ViewModel    │ │  ViewModel    │                  │
│  └──────┬───────┘ └──────┬───────┘                   │
│         │                │                           │
├─────────┼────────────────┼───────────────────────────┤
│         ▼                ▼       Services            │
│  ┌─────────────────────────────────────────────┐     │
│  │              SyncEngine                      │     │
│  │  - Queues transactions                       │     │
│  │  - Orchestrates sync on connectivity change  │     │
│  │  - Manages retry with exponential backoff    │     │
│  └──────────┬──────────────────┬───────────────┘     │
│             │                  │                      │
│  ┌──────────▼─────┐  ┌────────▼────────┐            │
│  │Connectivity    │  │MockPayment      │             │
│  │  Manager       │  │  Service        │             │
│  │(NWPathMonitor) │  │  (Actor)        │             │
│  └────────────────┘  └─────────────────┘             │
│                                                      │
├──────────────────────────────────────────────────────┤
│                  SwiftData (Persistence)              │
│  ┌─────────────────────────────────────────────┐     │
│  │  Transaction @Model                          │     │
│  │  - id, amount, currency, paymentMethod       │     │
│  │  - status, customerName, itemDescription     │     │
│  │  - createdAt, processedAt, retryCount        │     │
│  │  - idempotencyKey, errorMessage              │     │
│  └─────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────┘
```

## Key Components

### 1. Models

**Transaction** (`@Model`): The core SwiftData entity that persists payment transactions. Uses raw string storage for enums to ensure SwiftData compatibility. Includes an idempotency key for duplicate detection.

**Currency**: Enum supporting GTQ, COP, PEN, USD with locale-aware formatting.

**PaymentMethod**: Enum for credit card, debit card, cash, bank transfer, and mobile wallet.

**TransactionStatus**: State machine enum (queued → processing → approved/declined/failed).

### 2. Services

**ConnectivityManager** (`@Observable`, singleton): Wraps NWPathMonitor to track real network state. Exposes an `isSimulatingOffline` toggle for developer testing. Fires `onConnectivityRestored` callback when transitioning from offline to online.

**SyncEngine** (`@Observable`, `@MainActor`): The core orchestration service. Queues transactions into SwiftData, processes them sequentially when online, implements exponential backoff for retries, and listens for connectivity changes to trigger auto-sync.

**MockPaymentService** (`actor`): Thread-safe mock payment gateway. Simulates realistic latency (0.5-2s) and outcomes (70/20/10 split). Maintains an idempotency cache to return consistent results for duplicate requests.

### 3. ViewModels

**TransactionFormViewModel**: Manages form state, validation, and submission. Creates Transaction objects and passes them to SyncEngine.

**TransactionListViewModel**: Manages filtering (by status), sorting (by date/amount), and search. Delegates retry and sync operations to SyncEngine.

### 4. Views

**ContentView**: Root view that wires up dependencies (SyncEngine, ConnectivityManager, ModelContext).

**TransactionListView**: Dashboard showing stats bar, filter chips, and scrollable transaction list with pull-to-refresh.

**TransactionFormView**: Modal form for creating new transactions with currency/payment method pickers.

**ConnectivityBannerView**: Orange banner that appears when offline.

**TransactionRowView**: Individual transaction display with status badge, retry button for failed items.

## Data Flow

### Creating a Transaction (Offline)

1. User fills form in `TransactionFormView`
2. `TransactionFormViewModel.submitTransaction()` creates a `Transaction` object
3. `SyncEngine.queueTransaction()` inserts it into SwiftData with status `queued`
4. Since offline, no processing happens
5. Transaction appears in list with orange "Queued" badge

### Auto-Sync (Connectivity Restored)

1. `ConnectivityManager` detects network change via NWPathMonitor
2. Fires `onConnectivityRestored` callback
3. `SyncEngine.syncPendingTransactions()` fetches all `queued` transactions
4. For each transaction (sequentially, oldest first):
   a. Status changes to `processing`
   b. `MockPaymentService.processPayment()` called with idempotency key
   c. Simulated delay (0.5-2s)
   d. Status updates to `approved`, `declined`, or `failed`
   e. If `failed` and retryCount < 3, status resets to `queued` with new idempotency key

### Retry Flow

1. User taps "Retry" on a failed transaction
2. `SyncEngine.retryTransaction()` resets status to `queued`, generates new idempotency key
3. If online, immediately triggers `syncPendingTransactions()`
4. Exponential backoff applies: delay = baseDelay * 2^(retryCount-1) + jitter

## Thread Safety

- `MockPaymentService` is an `actor`, ensuring thread-safe access to the idempotency cache
- `SyncEngine` is `@MainActor`-isolated, simplifying UI state updates
- `ConnectivityManager` dispatches NWPathMonitor updates to main thread via `Task { @MainActor in ... }`
- SwiftData `ModelContext` is accessed only from the main thread

## Persistence Strategy

SwiftData automatically persists the `Transaction` model to SQLite. The app calls `modelContext.save()` after every state change to ensure data survives crashes. On app launch, `SyncEngine` checks for any `queued` transactions from previous sessions and processes them.
