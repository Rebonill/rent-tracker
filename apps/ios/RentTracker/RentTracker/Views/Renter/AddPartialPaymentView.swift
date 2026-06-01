import SwiftUI

struct AddPartialPaymentView: View {
    @Environment(\.dismiss) var dismiss

    let monthYear: MonthYear
    let rentAmount: Double
    let amountPaid: Double
    let onSave: (Double, String?) -> Void

    @State private var amount = ""
    @State private var note = ""

    private var remaining: Double {
        rentAmount - amountPaid
    }

    private var parsedAmount: Double? {
        // Handle both period and comma decimal separators
        let normalized = amount.replacingOccurrences(of: ",", with: ".")
        guard let val = Double(normalized), val > 0 else { return nil }
        return val
    }

    private var isValid: Bool {
        guard let val = parsedAmount else { return false }
        return val <= remaining
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Month", value: monthYear.displayName)
                    LabeledContent("Rent Due", value: "$\(String(format: "%.2f", rentAmount))")
                    LabeledContent("Already Paid", value: "$\(String(format: "%.2f", amountPaid))")
                    LabeledContent("Remaining") {
                        Text("$\(String(format: "%.2f", remaining))")
                            .foregroundStyle(remaining > 0 ? .red : .green)
                    }
                }

                Section("Payment") {
                    TextField("Amount ($)", text: $amount)
                        .keyboardType(.decimalPad)
                    TextField("Note (optional)", text: $note)
                }

                if let val = parsedAmount, val > remaining {
                    Section {
                        Text("Amount exceeds remaining balance of $\(String(format: "%.2f", remaining))")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button {
                        if let val = parsedAmount {
                            onSave(val, note.isEmpty ? nil : note)
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if let val = parsedAmount {
                                let newTotal = amountPaid + val
                                if newTotal >= rentAmount {
                                    Label("Pay $\(String(format: "%.2f", val)) — Fully Paid", systemImage: "checkmark.circle.fill")
                                } else {
                                    Label("Pay $\(String(format: "%.2f", val)) — $\(String(format: "%.2f", remaining - val)) left", systemImage: "plus.circle")
                                }
                            } else {
                                Text("Enter an amount")
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle("Add Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
