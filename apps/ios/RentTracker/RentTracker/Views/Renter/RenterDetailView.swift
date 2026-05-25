// Views/Renter/RenterDetailView.swift

import SwiftUI

struct RenterDetailView: View {
    @StateObject private var viewModel: RenterDetailViewModel
    
    init(renter: Renter) {
        _viewModel = StateObject(wrappedValue: RenterDetailViewModel(renter: renter))
    }
    
    var body: some View {
        List {
            // MARK: - Renter Info
            Section("Renter") {
                LabeledContent("Name", value: viewModel.renter.name)
                if let email = viewModel.renter.email {
                    LabeledContent("Email", value: email)
                }
                if let phone = viewModel.renter.phone {
                    LabeledContent("Phone", value: phone)
                }
            }
            
            // MARK: - Property & Lease
            if let lease = viewModel.activeLease {
                Section("Lease") {
                    if let property = lease.property {
                        LabeledContent("Property") {
                            Text(property.unit != nil
                                 ? "\(property.address), \(property.unit!)"
                                 : property.address)
                        }
                    }
                    LabeledContent("Rent", value: "$\(String(format: "%.2f", lease.rentAmount))")
                    LabeledContent("Due", value: "the \(ordinal(lease.dueDayOfMonth)) of each month")
                    LabeledContent("Status", value: lease.isActive ? "Active" : "Inactive")
                }
                
                // MARK: - Payment History
                Section("Payments") {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if viewModel.displayMonths.isEmpty {
                        Text("No months to display")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.displayMonths) { monthYear in
                            PaymentRow(
                                monthYear: monthYear,
                                isPaid: viewModel.isPaid(month: monthYear.month, year: monthYear.year),
                                onToggle: {
                                    Task {
                                        await viewModel.togglePayment(month: monthYear.month, year: monthYear.year)
                                    }
                                }
                            )
                        }
                    }
                }
            } else {
                Section {
                    Text("No active lease")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(viewModel.renter.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            await viewModel.fetchPayments()
        }
    }
    
    private func ordinal(_ n: Int) -> String {
        let suffix: String
        switch n {
        case 11, 12, 13: suffix = "th"
        default:
            switch n % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(n)\(suffix)"
    }
}

// MARK: - Payment Row

struct PaymentRow: View {
    let monthYear: MonthYear
    let isPaid: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isPaid ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isPaid ? .green : .gray)
                    .font(.title3)
                
                Text(monthYear.displayName)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text(isPaid ? "Paid" : "Unpaid")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(isPaid ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                    .foregroundStyle(isPaid ? .green : .gray)
                    .clipShape(Capsule())
            }
        }
    }
}
