//
//  Models.swift
//  RentTracker
//
//  Created by Rene Bonilla on 5/3/26.
//

import Foundation

struct Landlord: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
}

struct AuthResponse: Codable {
    let token: String
    let landlord: Landlord
}

struct Renter: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let email: String?
    let phone: String?
    let landlordId: String
    let leases: [Lease]?
}

struct Property: Codable, Identifiable, Hashable {
    let id: String
    let address: String
    let unit: String?
    let city: String
    let state: String
    let zip: String
}

struct Lease: Codable, Identifiable, Hashable {
    let id: String
    let rentAmount: Double
    let dueDayOfMonth: Int
    let startDate: String
    let endDate: String?
    let isActive: Bool
    let property: Property?
    let payments: [Payment]?
}

struct Payment: Codable, Identifiable, Hashable {
    let id: String
    let month: Int
    let year: Int
    let isPaid: Bool
    let amountPaid: Double?
    let paidDate: String?
    let notes: String?
    let partialPayments: [PartialPayment]?
}

struct PartialPayment: Codable, Identifiable, Hashable {
    let id: String
    let amount: Double
    let note: String?
    let createdAt: String
}
