import SwiftUI

struct RenterDetailView: View {
    @StateObject private var viewModel: RenterDetailViewModel
    @State private var showPartialPaymentSheet = false
    @State private var selectedMonthYear: MonthYear?
    @State private var showPastMonths = false

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
                if let property = lease.property {
                    Section("Property") {
                        LabeledContent("Address") {
                            Text(property.unit != nil
                                 ? "\(property.address), \(property.unit!)"
                                 : property.address)
                        }
                        LabeledContent("City", value: property.city)
                        LabeledContent("State", value: property.state)
                        LabeledContent("ZIP", value: property.zip)
                    }
                }

                Section("Lease") {
                    LabeledContent("Rent", value: "$\(String(format: "%.2f", lease.rentAmount))")
                    LabeledContent("Due", value: "the \(ordinal(lease.dueDayOfMonth)) of each month")
                    LabeledContent("Status", value: lease.isActive ? "Active" : "Inactive")

                    NavigationLink {
                        PaymentHistoryView(
                            lease: lease,
                            payments: viewModel.payments,
                            displayMonths: viewModel.displayMonths
                        )
                    } label: {
                        Label("Payment History", systemImage: "clock.arrow.circlepath")
                    }
                }

                // MARK: - Current Month
                if viewModel.isLoading {
                    Section("Current Month") {
                        ProgressView()
                    }
                } else {
                    if let current = viewModel.currentMonth {
                        Section("Current Month") {
                            paymentRow(for: current, rentAmount: lease.rentAmount)
                        }
                    }

                    // MARK: - Pay in Advance
                    let future = viewModel.futureMonths
                    if !future.isEmpty {
                        Section {
                            ForEach(future) { monthYear in
                                paymentRow(for: monthYear, rentAmount: lease.rentAmount)
                            }
                        } header: {
                            Text("Upcoming")
                        } footer: {
                            Stepper("Show \(viewModel.monthsAhead) month\(viewModel.monthsAhead == 1 ? "" : "s") ahead",
                                    value: $viewModel.monthsAhead, in: 1...12, step: 1)
                                .onChange(of: viewModel.monthsAhead) { _, newValue in
                                    viewModel.setMonthsAhead(newValue)
                                }
                        }
                    } else {
                        Section {
                            Stepper("Show \(viewModel.monthsAhead) month\(viewModel.monthsAhead == 1 ? "" : "s") ahead",
                                    value: $viewModel.monthsAhead, in: 1...12, step: 1)
                                .onChange(of: viewModel.monthsAhead) { _, newValue in
                                    viewModel.setMonthsAhead(newValue)
                                }
                        }
                    }

                    // MARK: - Past Months (collapsible)
                    let past = viewModel.pastMonths
                    if !past.isEmpty {
                        Section {
                            Button {
                                withAnimation {
                                    showPastMonths.toggle()
                                }
                            } label: {
                                HStack {
                                    Text("Past Months (\(past.count))")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: showPastMonths ? "chevron.up" : "chevron.down")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                            }

                            if showPastMonths {
                                ForEach(past) { monthYear in
                                    paymentRow(for: monthYear, rentAmount: lease.rentAmount)
                                }
                            }
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink("Edit") {
                    EditRenterView(viewModel: viewModel)
                }
            }
        }
        .sheet(isPresented: $showPartialPaymentSheet) {
            if let monthYear = selectedMonthYear, let lease = viewModel.activeLease {
                let payment = viewModel.payment(for: monthYear.month, year: monthYear.year)
                AddPartialPaymentView(
                    monthYear: monthYear,
                    rentAmount: lease.rentAmount,
                    amountPaid: payment?.amountPaid ?? 0,
                    onSave: { amount, note in
                        Task {
                            await viewModel.addPartialPayment(
                                month: monthYear.month,
                                year: monthYear.year,
                                amount: amount,
                                note: note
                            )
                        }
                    }
                )
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            await viewModel.fetchPayments()
        }
    }

    // MARK: - Shared payment row builder

    @ViewBuilder
    private func paymentRow(for monthYear: MonthYear, rentAmount: Double) -> some View {
        let payment = viewModel.payment(for: monthYear.month, year: monthYear.year)
        PaymentRow(
            monthYear: monthYear,
            payment: payment,
            rentAmount: rentAmount,
            onToggle: {
                Task {
                    await viewModel.togglePayment(month: monthYear.month, year: monthYear.year)
                }
            },
            onAddPartial: {
                selectedMonthYear = monthYear
                showPartialPaymentSheet = true
            }
        )
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
    let payment: Payment?
    let rentAmount: Double
    let onToggle: () -> Void
    let onAddPartial: () -> Void

    private var isPaid: Bool { payment?.isPaid ?? false }
    private var amountPaid: Double { payment?.amountPaid ?? 0 }
    private var hasPartials: Bool { amountPaid > 0 && !isPaid }
    private var progress: Double { min(amountPaid / rentAmount, 1.0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: isPaid ? "checkmark.circle.fill" : hasPartials ? "circle.lefthalf.filled" : "circle")
                    .foregroundStyle(isPaid ? .green : hasPartials ? .orange : .gray)
                    .font(.title3)

                Text(monthYear.displayName)
                    .foregroundStyle(.primary)

                Spacer()

                if isPaid {
                    Text("Paid")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                } else if hasPartials {
                    Text("$\(String(format: "%.0f", amountPaid))/$\(String(format: "%.0f", rentAmount))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                } else {
                    Text("Unpaid")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.15))
                        .foregroundStyle(.gray)
                        .clipShape(Capsule())
                }
            }

            if hasPartials {
                ProgressView(value: progress)
                    .tint(.orange)
            }

            if !isPaid {
                HStack(spacing: 12) {
                    Button {
                        onAddPartial()
                    } label: {
                        Label("Add Payment", systemImage: "plus.circle")
                            .font(.caption)
                    }

                    Divider().frame(height: 14)

                    Button {
                        onToggle()
                    } label: {
                        Label("Mark Paid", systemImage: "checkmark")
                            .font(.caption)
                    }
                }
                .padding(.top, 2)
            } else {
                Button {
                    onToggle()
                } label: {
                    Label("Mark Unpaid", systemImage: "arrow.uturn.backward")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}
