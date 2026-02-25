import SwiftUI

struct ConnectivityBannerView: View {
    let connectivity: ConnectivityManager

    var body: some View {
        if !connectivity.isEffectivelyOnline {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if connectivity.isSimulatingOffline {
                    Text("Offline Mode (Simulated)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    Text("No Internet Connection")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                Text("Transactions will sync when online")
                    .font(.caption)
                    .opacity(0.8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.orange)
            .foregroundStyle(.white)
        }
    }
}
