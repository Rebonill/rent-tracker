import SwiftUI

struct PaymentHistoryView: View {
    let lease: Lease
    let payments: [Payment]
    let displayMonths: [MonthYear]

    @State private var selectedYear: Int

    private var availableYears: [Int] {
        let years = Set(displayMonths.map { $0.year })
        return years.sorted(by: >)
    }

    private var filteredMonths: [MonthYear] {
        displayMonths.filter { $0.year == selectedYear }
    }

    private var paidCount: Int {
        filteredMonths.filter { payment(for: $0)?.isPaid == true }.count
    }

    private var unpaidCount: Int {
        filteredMonths.count - paidCount
    }

    private var totalCollected: Double {
        Double(paidCount) * lease.rentAmount
    }

    private var totalOutstanding: Double {
        Double(unpaidCount) * lease.rentAmount
    }

    init(lease: Lease, payments: [Payment], displayMonths: [MonthYear]) {
        self.lease = lease
        self.payments = payments
        self.displayMonths = displayMonths

        let currentYear = Calendar.current.component(.year, from: Date())
        _selectedYear = State(initialValue: currentYear)
    }

    var body: some View {
        List {
            // MARK: - Year Picker
            Section {
                Picker("Year", selection: $selectedYear) {
                    ForEach(availableYears, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.segmented)
            }

            // MARK: - Summary
            Section("Summary") {
                LabeledContent("Rent Amount", value: "$\(String(format: "%.2f", lease.rentAmount))/mo")

                HStack {
                    SummaryCard(
                        title: "Collected",
                        amount: totalCollected,
                        count: paidCount,
                        color: .green
                    )
                    SummaryCard(
                        title: "Outstanding",
                        amount: totalOutstanding,
                        count: unpaidCount,
                        color: unpaidCount > 0 ? .red : .gray
                    )
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .padding(.horizontal, 10)
            }

            // MARK: - Monthly Breakdown
            Section("Monthly Breakdown") {
                if filteredMonths.isEmpty {
                    Text("No payment records for \(String(selectedYear))")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredMonths) { monthYear in
                        HistoryRow(
                            monthYear: monthYear,
                            payment: payment(for: monthYear),
                            rentAmount: lease.rentAmount
                        )
                    }
                }
            }
        }
        .navigationTitle("Payment History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func payment(for monthYear: MonthYear) -> Payment? {
        payments.first { $0.month == monthYear.month && $0.year == monthYear.year }
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let amount: Double
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("$\(String(format: "%.2f", amount))")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text("\(count) month\(count == 1 ? "" : "s")")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - History Row

struct HistoryRow: View {
    let monthYear: MonthYear
    let payment: Payment?
    let rentAmount: Double

    private var isPaid: Bool {
        payment?.isPaid ?? false
    }

    private var paidDateFormatted: String? {
        guard let dateString = payment?.paidDate else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = isoFormatter.date(from: dateString) else { return nil }
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        return displayFormatter.string(from: date)
    }

    var body: some View {
        HStack {
            Image(systemName: isPaid ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(isPaid ? .green : .red)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(monthYear.displayName)
                    .font(.body)
                if isPaid, let dateStr = paidDateFormatted {
                    Text("Paid on \(dateStr)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if !isPaid {
                    Text("Not paid")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            Text("$\(String(format: "%.2f", rentAmount))")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isPaid ? .primary : .secondary)
        }
        .padding(.vertical, 2)
    }
}
