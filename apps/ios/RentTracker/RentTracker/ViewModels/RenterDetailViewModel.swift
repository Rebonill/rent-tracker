// ViewModels/RenterDetailViewModel.swift

import Foundation
internal import Combine

class RenterDetailViewModel: ObservableObject {
    @Published var renter: Renter
    @Published var payments: [Payment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // The months we display in the payment grid
    @Published var displayMonths: [MonthYear] = []
    
    var activeLease: Lease? {
        renter.leases?.first(where: { $0.isActive })
    }
    
    init(renter: Renter) {
        self.renter = renter
        generateDisplayMonths()
    }
    
    // MARK: - Fetch Payments
    
    func fetchPayments() async {
        guard let lease = activeLease else { return }
        isLoading = true
        
        do {
            let result: [Payment] = try await ApiClient.shared.request(
                path: "/payments/\(lease.id)"
            )
            payments = result
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Toggle Payment
    
    func togglePayment(month: Int, year: Int) async {
        guard let lease = activeLease else { return }
        
        do {
            let updated: Payment = try await ApiClient.shared.request(
                path: "/payments/toggle",
                method: "POST",
                body: [
                    "leaseId": lease.id,
                    "month": month,
                    "year": year
                ]
            )
            
            // Update local array
            if let index = payments.firstIndex(where: { $0.month == month && $0.year == year }) {
                payments[index] = updated
            } else {
                payments.append(updated)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Check if a month is paid
    
    func isPaid(month: Int, year: Int) -> Bool {
        payments.first(where: { $0.month == month && $0.year == year })?.isPaid ?? false
    }
    
    // MARK: - Generate display months
    
    private func generateDisplayMonths() {
        guard let lease = activeLease else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Parse lease start date
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let startDate = formatter.date(from: lease.startDate) else { return }
        
        var current = calendar.dateComponents([.year, .month], from: startDate)
        let end = calendar.dateComponents([.year, .month], from: now)
        
        var months: [MonthYear] = []
        
        while (current.year! < end.year!) ||
              (current.year! == end.year! && current.month! <= end.month!) {
            months.append(MonthYear(month: current.month!, year: current.year!))
            
            // Advance one month
            if current.month! == 12 {
                current.month = 1
                current.year = current.year! + 1
            } else {
                current.month = current.month! + 1
            }
        }
        
        displayMonths = months.reversed() // Most recent first
    }
}

// Simple struct for month/year pairs
struct MonthYear: Identifiable, Hashable {
    let month: Int
    let year: Int
    
    var id: String { "\(year)-\(month)" }
    
    var displayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        var components = DateComponents()
        components.month = month
        components.year = year
        components.day = 1
        let date = Calendar.current.date(from: components)!
        return formatter.string(from: date)
    }
}
