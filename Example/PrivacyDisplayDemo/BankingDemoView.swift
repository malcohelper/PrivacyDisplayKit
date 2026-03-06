import SwiftUI
import PrivacyDisplayKit

struct BankingDemoView: View {
    @State private var isPrivacyEnabled = true
    @State private var balance = "$12,458.90"
    @State private var showTransfer = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Balance Card
                    VStack(spacing: 12) {
                        Text("Total Balance")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(balance)
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                            .privacySensitive()
                        
                        HStack(spacing: 16) {
                            Button(action: { showTransfer = true }) {
                                Label("Transfer", systemImage: "arrow.left.arrow.right")
                                    .font(.subheadline.bold())
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.white.opacity(0.2))
                            
                            Button(action: {}) {
                                Label("Pay", systemImage: "creditcard")
                                    .font(.subheadline.bold())
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.white.opacity(0.2))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .padding(.horizontal)
                    .background(
                        LinearGradient(
                            colors: [.blue, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // Recent Transactions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Transactions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            TransactionRow(
                                icon: "cart.fill",
                                title: "Apple Store",
                                subtitle: "Electronics",
                                amount: "-$999.00",
                                color: .red
                            )
                            .privacySensitive()
                            
                            Divider().padding(.leading, 56)
                            
                            TransactionRow(
                                icon: "briefcase.fill",
                                title: "Salary",
                                subtitle: "Monthly pay",
                                amount: "+$5,200.00",
                                color: .green
                            )
                            .privacySensitive()
                            
                            Divider().padding(.leading, 56)
                            
                            TransactionRow(
                                icon: "cup.and.saucer.fill",
                                title: "Starbucks",
                                subtitle: "Food & Drink",
                                amount: "-$6.50",
                                color: .red
                            )
                            .privacySensitive()
                            
                            Divider().padding(.leading, 56)
                            
                            TransactionRow(
                                icon: "house.fill",
                                title: "Rent",
                                subtitle: "Monthly rent",
                                amount: "-$1,800.00",
                                color: .red
                            )
                            .privacySensitive()
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Account Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Account Info")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            InfoRow(label: "Account Number", value: "****-****-****-4829")
                                .privacySensitive(style: .dim(opacity: 0.9))
                            
                            Divider()
                            
                            InfoRow(label: "Routing Number", value: "021000021")
                                .privacySensitive(style: .dim(opacity: 0.9))
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Bank")
        }
        .privacyDisplay(
            mode: .combined,
            overlay: .blurAndDim(blurRadius: 20, dimOpacity: 0.5),
            sensitivity: .high
        )
    }
}

// MARK: - Supporting Views

struct TransactionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let amount: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(amount)
                .font(.subheadline.bold())
                .foregroundColor(color)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }
}

#Preview {
    BankingDemoView()
}
