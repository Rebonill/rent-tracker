//
//  HomeView.swift
//  RentTracker
//
//  Created by Rene Bonilla on 5/3/26.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Welcome to RentTracker!")
                    .font(.title)
            }
            .navigationTitle("Home")
            .toolbar {
                Button("Logout") {
                    authViewModel.logout()
                }
            }
        }
    }
}
