# Scope Definition

## In Scope (Delivered)

### Core Features
- [x] **Offline transaction creation**: Create payment transactions without internet connectivity
- [x] **Local persistence**: All transactions saved to SwiftData (survives app restarts and crashes)
- [x] **Auto-sync on reconnection**: NWPathMonitor detects connectivity changes and triggers processing
- [x] **Developer offline toggle**: In-app switch to simulate offline mode for testing
- [x] **Transaction state machine**: queued → processing → approved/declined/failed
- [x] **Mock payment gateway**: Simulated latency (0.5-2s) with realistic outcome distribution (70/20/10)

### Dashboard
- [x] **Transaction list**: Scrollable list of all transactions with status badges
- [x] **Status filters**: Filter by All/Queued/Processing/Approved/Declined/Failed
- [x] **Sort options**: Newest first, oldest first, amount high-to-low, amount low-to-high
- [x] **Search**: Find transactions by customer name, description, or ID
- [x] **Stats bar**: Real-time count of transactions by status
- [x] **Pull-to-refresh**: Manual sync trigger

### Payment Features
- [x] **Multi-currency**: GTQ, COP, PEN, USD with locale-aware formatting
- [x] **Multiple payment methods**: Credit card, debit card, cash, bank transfer, mobile wallet
- [x] **Retry failed transactions**: One-tap retry with new idempotency key
- [x] **Idempotency**: Duplicate detection via unique keys per transaction

### Stretch Goals (Delivered)
- [x] **Exponential backoff**: Automatic retry with increasing delays (base * 2^retryCount + jitter)
- [x] **Duplicate detection**: MockPaymentService caches results by idempotency key

### Documentation
- [x] **README.md**: Setup instructions, demo walkthrough, production notes
- [x] **docs/architecture.md**: System architecture, data flow, component descriptions
- [x] **docs/decisions.md**: Technical decision rationale
- [x] **docs/assumptions.md**: Business and technical assumptions
- [x] **docs/scope.md**: This document

## Out of Scope (Not Delivered)

### Backend Integration
- Real Yuno SDK integration (replaced by MockPaymentService)
- Server-side idempotency validation
- Webhook handling for async payment status updates
- Real payment processing and settlement

### Authentication & Security
- User login / merchant authentication
- Data encryption at rest (beyond iOS default encryption)
- Certificate pinning
- PCI DSS compliance
- Biometric authentication for transactions

### Advanced Features
- Multi-device sync and conflict resolution
- Background sync (BGTaskScheduler)
- Push notifications for processed transactions
- Receipt generation and sharing
- Transaction export (CSV/PDF)
- Barcode/QR code scanning
- Partial payments and installments
- Refund/void operations

### Production Operations
- Analytics and telemetry
- Crash reporting integration
- Remote configuration
- A/B testing
- Performance monitoring
- Rate limiting

### UI/UX Polish
- Custom app icon
- Onboarding tutorial
- Spanish localization
- Custom animations and transitions
- iPad-optimized layout
- Comprehensive accessibility audit
- Haptic feedback

### Testing
- Unit test suite
- UI test suite
- Snapshot tests
- Performance benchmarks
- Network condition simulation (beyond toggle)

## Future Iterations

If this PoC moves to production, the recommended priority order is:

1. **Yuno SDK Integration**: Replace mock with real payment processing
2. **Authentication**: Merchant login and transaction ownership
3. **Data Security**: Encryption, certificate pinning, PCI compliance
4. **Background Sync**: Process queued transactions even when app is backgrounded
5. **Localization**: Spanish for Guatemala, Colombia, Peru markets
6. **Testing**: Comprehensive test suite
7. **Analytics**: Track sync reliability and payment success rates
