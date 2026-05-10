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

struct Renter: Codable, Identifiable {
    let id: String
    let name: String
    let email: String?
    let phone: String?
    let kandlordId: String
    let leases: [Lease]?
}

struct Property: Codable, Identifiable {
    let id: String
    let address: String
    let unit: String?
    let city: String
    let state: String
    let zip: String
}

struct Lease: Codable, Identifiable {
    let id: String
    let rentAmount: Double
    let dueDayOfMonth: Int
    let startDate: String
    let endDate: String?
    let isActive: Bool
    let property: Property?
    let payments: [Payment]?
}

struct Payment: Codable, Identifiable {
    let id: String
    let month: Int
    let year: Int
    let isPaid: Bool
    let paidDate: String?
    let notes: String?
}
