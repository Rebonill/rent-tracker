import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = HomeViewModel()
    @State private var showAddRenter = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.renters.isEmpty {
                    ProgressView("Loading renters...")
                } else if viewModel.renters.isEmpty {
                    ContentUnavailableView(
                        "No Renters Yet",
                        systemImage: "person.badge.plus",
                        description: Text("Tap the + button to add your first renter.")
                    )
                } else {
                    List {
                        ForEach(viewModel.renters) { renter in
                            NavigationLink(value: renter) {
                                RenterCardView(renter: renter)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    await viewModel.deleteRenter(id: viewModel.renters[index].id)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .navigationDestination(for: Renter.self) { renter in
                        RenterDetailView(renter: renter)
                    }
                    .refreshable {
                        await viewModel.fetchRenters()
                    }
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Logout") {
                        authViewModel.logout()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddRenter = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddRenter) {
                AddRenterView(onSave: {
                    Task { await viewModel.fetchRenters() }
                })
            }
            .task {
                await viewModel.fetchRenters()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}
