import SwiftUI

struct RenterCardView: View {
    let renter: Renter
    
    private var activeLease: Lease? {
        renter.leases?.first { $0.isActive }
    }
    
    private var statusColor: Color {
        guard let lease = activeLease else { return .gray }
        
        let now = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        let currentDay = calendar.component(.day, from: now)
        
        // Check if current month's payment exists and is paid
        if let payments = lease.payments,
           let currentPayment = payments.first(where: { $0.month == currentMonth && $0.year == currentYear }),
           currentPayment.isPaid {
            return .green
        }
        
        // Past due date and not paid = red
        if currentDay >= lease.dueDayOfMonth {
            return .red
        }
        
        // Before due date = neutral
        return .gray
    }
    
    private var statusText: String {
        switch statusColor {
        case .green: return "Paid"
        case .red: return "Overdue"
        default: return "Upcoming"
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(renter.name)
                    .font(.headline)
                
                if let lease = activeLease, let property = lease.property {
                    Text(property.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("$\(lease.rentAmount, specifier: "%.0f")/mo")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("· Due on the \(ordinal(lease.dueDayOfMonth))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Text(statusText)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(statusColor.opacity(0.15))
                .foregroundColor(statusColor)
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    private func ordinal(_ day: Int) -> String {
        let suffix: String
        switch day {
        case 1, 21: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        return "\(day)\(suffix)"
    }
}
