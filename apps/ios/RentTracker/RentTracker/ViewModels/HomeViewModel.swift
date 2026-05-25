//
//  HomeViewModels.swift
//  RentTracker
//
//  Created by Rene Bonilla on 5/10/26.
//

import Foundation
internal import Combine

class HomeViewModel: ObservableObject {
    @Published var renters: [Renter] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchRenters() async {
        isLoading = true
        errorMessage = nil
        do {
            let result: [Renter] = try await ApiClient.shared.request(path: "/renters")
            renters = result
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteRenter(id: String) async {
        do {
            try await ApiClient.shared.requestNoContent(
                path: "/renters/\(id)",
                method: "DELETE"
            )
            renters.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
