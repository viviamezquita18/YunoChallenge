import Foundation
import Network
import Observation

@Observable
final class ConnectivityManager {
    static let shared = ConnectivityManager()

    private(set) var isConnected: Bool = true
    private(set) var connectionType: String = "WiFi"

    /// Developer toggle to simulate offline mode
    var isSimulatingOffline: Bool = false {
        didSet {
            updateEffectiveConnectivity()
        }
    }

    /// The effective connectivity state considering both real network and simulation
    var isEffectivelyOnline: Bool {
        isConnected && !isSimulatingOffline
    }

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.tiendarapida.connectivity")

    /// Callback fired when connectivity changes to online
    var onConnectivityRestored: (() -> Void)?

    private var wasEffectivelyOnline: Bool = true

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self else { return }
                let wasOnline = self.isEffectivelyOnline
                self.isConnected = path.status == .satisfied

                if path.usesInterfaceType(.wifi) {
                    self.connectionType = "WiFi"
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = "Cellular"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = "Ethernet"
                } else {
                    self.connectionType = "Unknown"
                }

                self.checkConnectivityTransition(wasOnline: wasOnline)
            }
        }
        monitor.start(queue: monitorQueue)
    }

    private func updateEffectiveConnectivity() {
        let wasOnline = wasEffectivelyOnline
        checkConnectivityTransition(wasOnline: wasOnline)
    }

    private func checkConnectivityTransition(wasOnline: Bool) {
        let isNowOnline = isEffectivelyOnline
        if !wasOnline && isNowOnline {
            onConnectivityRestored?()
        }
        wasEffectivelyOnline = isNowOnline
    }

    deinit {
        monitor.cancel()
    }
}
