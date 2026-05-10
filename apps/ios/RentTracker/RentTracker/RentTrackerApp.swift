//
//  RentTrackerApp.swift
//  RentTracker
//
//  Created by Rene Bonilla on 4/12/26.
//

import SwiftUI

@main
struct RentTrackerApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated{
                    HomeView()
                } else{
                    LoginView()
                }
            }
            .environmentObject(authViewModel)
        }
    }
}
