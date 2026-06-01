// ViewModels/RenterDetailViewModel.swift

import Foundation
internal import Combine

class RenterDetailViewModel: ObservableObject {
    @Published var renter: Renter
    @Published var payments: [Payment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var monthsAhead = 1

    // All generated months (past + current + future)
    @Published var displayMonths: [MonthYear] = []

    var activeLease: Lease? {
        renter.leases?.first(where: { $0.isActive })
    }

    // MARK: - Computed month groups

    var currentMonthYear: MonthYear {
        let cal = Calendar.current
        let now = Date()
        return MonthYear(month: cal.component(.month, from: now), year: cal.component(.year, from: now))
    }

    var currentMonth: MonthYear? {
        displayMonths.first { $0 == currentMonthYear }
    }

    var futureMonths: [MonthYear] {
        displayMonths.filter {
            ($0.year > currentMonthYear.year) ||
            ($0.year == currentMonthYear.year && $0.month > currentMonthYear.month)
        }
    }

    var pastMonths: [MonthYear] {
        displayMonths.filter {
            ($0.year < currentMonthYear.year) ||
            ($0.year == currentMonthYear.year && $0.month < currentMonthYear.month)
        }.sorted { a, b in
            // Most recent first
            if a.year != b.year { return a.year > b.year }
            return a.month > b.month
        }
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

            if let index = payments.firstIndex(where: { $0.month == month && $0.year == year }) {
                payments[index] = updated
            } else {
                payments.append(updated)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Add Partial Payment

    func addPartialPayment(month: Int, year: Int, amount: Double, note: String?) async {
        guard let lease = activeLease else { return }

        do {
            var body: [String: Any] = [
                "leaseId": lease.id,
                "month": month,
                "year": year,
                "amount": amount
            ]
            if let note = note, !note.isEmpty { body["note"] = note }

            let updated: Payment = try await ApiClient.shared.request(
                path: "/payments/partial",
                method: "POST",
                body: body
            )

            if let index = payments.firstIndex(where: { $0.month == month && $0.year == year }) {
                payments[index] = updated
            } else {
                payments.append(updated)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Get payment for a month

    func payment(for month: Int, year: Int) -> Payment? {
        payments.first(where: { $0.month == month && $0.year == year })
    }

    // MARK: - Check if a month is paid

    func isPaid(month: Int, year: Int) -> Bool {
        payments.first(where: { $0.month == month && $0.year == year })?.isPaid ?? false
    }

    // MARK: - Update months ahead

    func setMonthsAhead(_ count: Int) {
        monthsAhead = count
        generateDisplayMonths()
    }

    // MARK: - Update Renter

    func updateRenter(name: String, email: String?, phone: String?) async -> Bool {
        do {
            var body: [String: Any] = ["name": name]
            if let email = email, !email.isEmpty { body["email"] = email }
            if let phone = phone, !phone.isEmpty { body["phone"] = phone }

            let updated: Renter = try await ApiClient.shared.request(
                path: "/renters/\(renter.id)",
                method: "PUT",
                body: body
            )
            renter = Renter(
                id: updated.id,
                name: updated.name,
                email: updated.email,
                phone: updated.phone,
                landlordId: updated.landlordId,
                leases: renter.leases
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Update Lease

    func updateLease(rentAmount: Double, dueDayOfMonth: Int, isActive: Bool) async -> Bool {
        guard let lease = activeLease else { return false }
        do {
            let _: Lease = try await ApiClient.shared.request(
                path: "/leases/\(lease.id)",
                method: "PUT",
                body: [
                    "rentAmount": rentAmount,
                    "dueDayOfMonth": dueDayOfMonth,
                    "isActive": isActive
                ] as [String: Any]
            )
            let refreshed: Renter = try await ApiClient.shared.request(
                path: "/renters/\(renter.id)"
            )
            renter = refreshed
            generateDisplayMonths()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Update Property

    func updateProperty(address: String, unit: String?, city: String, state: String, zip: String) async -> Bool {
        guard let lease = activeLease, let property = lease.property else { return false }
        do {
            var body: [String: Any] = [
                "address": address,
                "city": city,
                "state": state,
                "zip": zip
            ]
            if let unit = unit, !unit.isEmpty { body["unit"] = unit }

            let _: Property = try await ApiClient.shared.request(
                path: "/properties/\(property.id)",
                method: "PUT",
                body: body
            )
            let refreshed: Renter = try await ApiClient.shared.request(
                path: "/renters/\(renter.id)"
            )
            renter = refreshed
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Generate display months

    private func generateDisplayMonths() {
        guard let lease = activeLease else { return }

        let calendar = Calendar.current
        let now = Date()

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let startDate = formatter.date(from: lease.startDate) else { return }

        // Calculate end: current month + monthsAhead
        guard let futureDate = calendar.date(byAdding: .month, value: monthsAhead, to: now) else { return }

        var current = calendar.dateComponents([.year, .month], from: startDate)
        let end = calendar.dateComponents([.year, .month], from: futureDate)

        var months: [MonthYear] = []

        while (current.year! < end.year!) ||
              (current.year! == end.year! && current.month! <= end.month!) {
            months.append(MonthYear(month: current.month!, year: current.year!))

            if current.month! == 12 {
                current.month = 1
                current.year = current.year! + 1
            } else {
                current.month = current.month! + 1
            }
        }

        displayMonths = months
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

    var shortName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        var components = DateComponents()
        components.month = month
        components.year = year
        components.day = 1
        let date = Calendar.current.date(from: components)!
        return formatter.string(from: date)
    }
}
