//
//  AuthViewModel.swift
//  RentTracker
//
//  Created by Rene Bonilla on 5/3/26.
//

import Foundation
import SwiftUI
internal import Combine

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated =  false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentLandlord: Landlord?
    
    init(){
        // Check if we have a saved token on launch
        checkExistingToken()
    }
    
    private func checkExistingToken() {
        if KeychainHelper.shared.getToken() != nil {
            isAuthenticated = true
        }
    }
    
    func register(name: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: AuthResponse = try await ApiClient.shared.request(
                path: "/register",
                method: "POST",
                body: ["name": name, "email": email, "password": password],
                authenticated: false
            )
            
            KeychainHelper.shared.saveToken(response.token)
            currentLandlord = response.landlord
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: AuthResponse = try await ApiClient.shared.request(
                path: "/login",
                method: "POST",
                body: ["email": email, "password": password],
                authenticated: false
            )
            
            KeychainHelper.shared.saveToken(response.token)
            currentLandlord = response.landlord
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func logout(){
        KeychainHelper.shared.deleteToken()
        currentLandlord = nil
        isAuthenticated = false
    }
}
