import SwiftUI
import PrivacyDisplayKit

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            BankingDemoView()
                .tabItem {
                    Label("Banking", systemImage: "building.columns")
                }
                .tag(0)
            
            MessageDemoView()
                .tabItem {
                    Label("Messages", systemImage: "message.fill")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .tint(.blue)
    }
}

// MARK: - Message Demo

struct MessageDemoView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Conversations") {
                    MessageRow(name: "Alice", message: "Hey, did you send the payment?", time: "2m ago")
                    MessageRow(name: "Bob", message: "Meeting at 3pm tomorrow", time: "15m ago")
                    MessageRow(name: "Charlie", message: "Your OTP code is 482910", time: "1h ago")
                        .privacySensitive()
                    MessageRow(name: "Bank Alert", message: "Transfer of $5,000 completed", time: "2h ago")
                        .privacySensitive(style: .blur(radius: 20))
                }
            }
            .navigationTitle("Messages")
        }
        .privacyDisplay(
            mode: .combined,
            overlay: .blur(),
            sensitivity: .medium
        )
    }
}

struct MessageRow: View {
    let name: String
    let message: String
    let time: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay {
                    Text(String(name.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name)
                        .font(.headline)
                    Spacer()
                    Text(time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
