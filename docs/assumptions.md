# Assumptions

## Technical Assumptions

1. **iOS 17+ Only**: We assume the target audience uses devices running iOS 17 or later. This enables SwiftData, @Observable, and modern SwiftUI APIs. Older devices are not supported.

2. **Single Device**: The app operates on a single device at a time. There is no multi-device sync or conflict resolution for the same merchant account across devices.

3. **No Real Backend**: The mock payment service is in-process. All "network" calls are simulated with `Task.sleep`. A production version would replace this with actual HTTP calls to Yuno's API.

4. **No Authentication**: The PoC has no user authentication. In production, transactions would be associated with a merchant account via OAuth/JWT tokens.

5. **SQLite is Sufficient**: SwiftData's default SQLite storage handles the expected transaction volume. We assume a typical store processes hundreds, not millions, of transactions per day on a single device.

6. **Connectivity Detection is Binary**: We treat network state as either "online" or "offline". We don't differentiate between "connected but slow" vs "fully connected". The developer toggle provides a reliable way to test the offline→online transition.

## Business Assumptions

1. **Small Store Context**: The app is designed for small retail stores ("tiendas") in Guatemala, Colombia, and Peru where internet connectivity is unreliable but not permanently absent.

2. **Store Clerk as User**: The primary user is a store clerk who processes customer payments. They need a simple, reliable interface that works regardless of connectivity.

3. **Transaction Volume**: We assume 10-100 transactions per day per store. The app does not need to handle high-throughput scenarios.

4. **Currency is Per-Transaction**: Each transaction specifies its own currency. The store may accept payments in the local currency (GTQ, COP, PEN) or USD.

5. **No Partial Payments**: Each transaction represents a single, complete payment. Split payments or installments are out of scope.

6. **Declined ≠ Retriable**: Declined transactions (card issues) are NOT automatically retried, as the underlying problem (insufficient funds, expired card) won't resolve on its own. Only server/network failures are eligible for automatic retry.

7. **Mock Probabilities are Representative**: The 70/20/10 split (approved/declined/failed) approximates real-world payment success rates in emerging markets where card infrastructure may be less reliable.

## UX Assumptions

1. **English-Only PoC**: All UI text and documentation is in English as specified. A production version would add Spanish localization.

2. **No Dark Mode Customization**: The app uses system colors which automatically adapt to light/dark mode, but we haven't done specific dark mode design work.

3. **No Accessibility Audit**: Standard SwiftUI accessibility is inherited (VoiceOver reads labels), but no dedicated accessibility testing has been performed.

4. **No Onboarding Flow**: The app assumes the user understands the offline-first concept. A production version would include an onboarding tutorial.
