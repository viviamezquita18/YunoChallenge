# Technical Decisions

## 1. SwiftData over Core Data

**Decision**: Use SwiftData for persistence instead of Core Data.

**Rationale**: SwiftData is Apple's modern persistence framework introduced alongside iOS 17. It provides a cleaner API with `@Model` macro, native SwiftUI integration, and automatic schema migration. Since our minimum target is iOS 17, there's no compatibility concern. SwiftData reduces boilerplate significantly compared to Core Data's NSManagedObject subclasses.

## 2. NWPathMonitor over Reachability Libraries

**Decision**: Use Apple's Network framework (NWPathMonitor) instead of third-party reachability libraries.

**Rationale**: NWPathMonitor is the official Apple API for monitoring network path changes. It's more reliable than SCNetworkReachability and doesn't require third-party dependencies. Combined with our developer toggle for offline simulation, it provides all the connectivity detection we need.

## 3. @Observable over ObservableObject

**Decision**: Use the Swift 5.9 `@Observable` macro instead of `ObservableObject` protocol.

**Rationale**: `@Observable` (Observation framework) provides more granular change tracking - views only re-render when the specific properties they read change, rather than when any `@Published` property changes. This improves performance and simplifies the code by removing the need for `@Published` wrappers.

## 4. Actor for MockPaymentService

**Decision**: Implement MockPaymentService as a Swift actor.

**Rationale**: The payment service maintains mutable state (idempotency cache) that could be accessed concurrently from multiple sync operations. Using an actor ensures data race safety at compile time without manual locking. This also models how a real payment SDK would handle concurrent requests.

## 5. Raw String Storage for Enums in SwiftData

**Decision**: Store enum values as raw strings in the SwiftData model with computed property wrappers.

**Rationale**: SwiftData has limitations with direct enum storage in `@Model` classes. Storing as raw strings ensures reliable persistence and query predicates (`#Predicate`) work correctly. The computed properties provide type-safe access while keeping the storage layer simple.

## 6. Sequential Transaction Processing

**Decision**: Process queued transactions sequentially (oldest first) rather than in parallel.

**Rationale**: Sequential processing is simpler to reason about, easier to debug, and prevents overwhelming the (mock) payment gateway. In a real-world scenario with rate limits and connection constraints in low-connectivity markets, sequential processing with proper error handling is more reliable than parallel batch processing.

## 7. Idempotency Key per Transaction

**Decision**: Generate a unique idempotency key for each transaction, regenerated on retry.

**Rationale**: Idempotency keys prevent double-charging when the same transaction is accidentally submitted twice (e.g., due to a network retry). On explicit retry of a failed transaction, we generate a new key so the payment gateway treats it as a new attempt rather than returning the cached failure.

## 8. Exponential Backoff with Jitter

**Decision**: Use exponential backoff (base * 2^retryCount) plus random jitter for automatic retries.

**Rationale**: This is the industry standard for retry strategies. Exponential backoff prevents overwhelming the server after failures. Adding random jitter (0-0.5s) prevents the "thundering herd" problem where multiple clients retry at the same moment after a shared outage.

## 9. MVVM Architecture

**Decision**: Use MVVM (Model-View-ViewModel) with a service layer.

**Rationale**: MVVM is the natural fit for SwiftUI apps. ViewModels encapsulate business logic and state management, keeping Views declarative and focused on layout. The service layer (SyncEngine, ConnectivityManager, MockPaymentService) handles cross-cutting concerns that don't belong in any single ViewModel.

## 10. No External Dependencies

**Decision**: Build the entire app using only Apple frameworks (SwiftUI, SwiftData, Network).

**Rationale**: Zero external dependencies means faster builds, no dependency management complexity, no supply chain risk, and guaranteed compatibility with iOS 17+. For a proof-of-concept, the Apple frameworks provide everything needed.
