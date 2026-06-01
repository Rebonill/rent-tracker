import SwiftUI

struct EditRenterView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: RenterDetailViewModel

    // Renter fields
    @State private var name: String
    @State private var email: String
    @State private var phone: String

    // Property fields
    @State private var address: String
    @State private var unit: String
    @State private var city: String
    @State private var state: String
    @State private var zip: String

    // Lease fields
    @State private var rentAmount: String
    @State private var dueDay: Int
    @State private var isActive: Bool

    @State private var isSaving = false
    @State private var showDiscardAlert = false

    init(viewModel: RenterDetailViewModel) {
        self.viewModel = viewModel

        let renter = viewModel.renter
        let lease = viewModel.activeLease
        let property = lease?.property

        _name = State(initialValue: renter.name)
        _email = State(initialValue: renter.email ?? "")
        _phone = State(initialValue: renter.phone ?? "")

        _address = State(initialValue: property?.address ?? "")
        _unit = State(initialValue: property?.unit ?? "")
        _city = State(initialValue: property?.city ?? "")
        _state = State(initialValue: property?.state ?? "")
        _zip = State(initialValue: property?.zip ?? "")

        _rentAmount = State(initialValue: lease != nil ? String(format: "%.2f", lease!.rentAmount) : "")
        _dueDay = State(initialValue: lease?.dueDayOfMonth ?? 1)
        _isActive = State(initialValue: lease?.isActive ?? true)
    }

    private var hasChanges: Bool {
        let renter = viewModel.renter
        let lease = viewModel.activeLease
        let property = lease?.property

        return name != renter.name
            || email != (renter.email ?? "")
            || phone != (renter.phone ?? "")
            || address != (property?.address ?? "")
            || unit != (property?.unit ?? "")
            || city != (property?.city ?? "")
            || state != (property?.state ?? "")
            || zip != (property?.zip ?? "")
            || rentAmount != (lease != nil ? String(format: "%.2f", lease!.rentAmount) : "")
            || dueDay != (lease?.dueDayOfMonth ?? 1)
            || isActive != (lease?.isActive ?? true)
    }

    private var isValid: Bool {
        !name.isEmpty && !address.isEmpty && !city.isEmpty && !state.isEmpty && !zip.isEmpty
    }

    var body: some View {
        Form {
                Section("Renter Info") {
                    TextField("Name", text: $name)
                    TextField("Email (optional)", text: $email)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("Phone (optional)", text: $phone)
                        .textContentType(.telephoneNumber)
                }

                if viewModel.activeLease?.property != nil {
                    Section("Property") {
                        TextField("Address", text: $address)
                        TextField("Unit (optional)", text: $unit)
                        TextField("City", text: $city)
                        TextField("State", text: $state)
                        TextField("ZIP", text: $zip)
                            .textContentType(.postalCode)
                    }
                }

                if viewModel.activeLease != nil {
                    Section("Lease") {
                        TextField("Rent Amount ($)", text: $rentAmount)
                            .keyboardType(.decimalPad)
                        Picker("Due Day of Month", selection: $dueDay) {
                            ForEach(1...28, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                        Toggle("Active", isOn: $isActive)
                    }
                }
            }
            .navigationTitle("Edit Renter")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasChanges {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(!isValid || isSaving)
                }
            }
            .alert("Discard Changes?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("You have unsaved changes that will be lost.")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
    }

    private func save() async {
        isSaving = true

        let renterOk = await viewModel.updateRenter(
            name: name,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone
        )

        if renterOk, viewModel.activeLease != nil {
            let leaseOk = await viewModel.updateLease(
                rentAmount: Double(rentAmount) ?? 0,
                dueDayOfMonth: dueDay,
                isActive: isActive
            )

            if leaseOk, viewModel.activeLease?.property != nil {
                _ = await viewModel.updateProperty(
                    address: address,
                    unit: unit.isEmpty ? nil : unit,
                    city: city,
                    state: state,
                    zip: zip
                )
            }
        }

        isSaving = false
        dismiss()
    }
}
