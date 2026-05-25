import SwiftUI

struct AddRenterView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: () -> Void = {}
    
    // Renter fields
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    
    // Property fields
    @State private var address = ""
    @State private var unit = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    
    // Lease fields
    @State private var rentAmount = ""
    @State private var dueDayOfMonth = 1
    @State private var startDate = Date()
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private var isValid: Bool {
        !name.isEmpty && !address.isEmpty && !city.isEmpty &&
        !state.isEmpty && !zip.isEmpty && !rentAmount.isEmpty
    }
    
    var body: some View {
        NavigationStack {
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
                
                Section("Property Info") {
                    TextField("Address", text: $address)
                    TextField("Unit (optional)", text: $unit)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("ZIP", text: $zip)
                        .textContentType(.postalCode)
                }
                
                Section("Lease Info") {
                    TextField("Rent Amount ($)", text: $rentAmount)
                        .keyboardType(.decimalPad)
                    Picker("Due Day of Month", selection: $dueDayOfMonth) {
                        ForEach(1...28, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Renter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(!isValid || isLoading)
                }
            }
        }
    }
    
    private func save() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Create the renter
            let renter: Renter = try await ApiClient.shared.request(
                path: "/renters",
                method: "POST",
                body: [
                    "name": name,
                    "email": email.isEmpty ? nil : email,
                    "phone": phone.isEmpty ? nil : phone
                ].compactMapValues { $0 }
            )
            
            // 2. Create the property
            var propertyBody: [String: Any] = [
                "address": address,
                "city": city,
                "state": state,
                "zip": zip
            ]
            if !unit.isEmpty { propertyBody["unit"] = unit }
            
            let property: Property = try await ApiClient.shared.request(
                path: "/properties",
                method: "POST",
                body: propertyBody
            )
            
            // 3. Create the lease
            let formatter = ISO8601DateFormatter()
            let _: Lease = try await ApiClient.shared.request(
                path: "/leases",
                method: "POST",
                body: [
                    "renterId": renter.id,
                    "propertyId": property.id,
                    "rentAmount": Double(rentAmount) ?? 0,
                    "dueDayOfMonth": dueDayOfMonth,
                    "startDate": formatter.string(from: startDate)
                ] as [String: Any]
            )
            
            onSave()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
