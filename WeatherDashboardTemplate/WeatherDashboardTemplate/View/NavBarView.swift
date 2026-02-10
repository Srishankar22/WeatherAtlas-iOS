//
//  NavBarView.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 19/10/2025.
//

import SwiftUI
import SwiftData

struct NavBarView: View {
    @EnvironmentObject var vm: MainAppViewModel
    
    var body: some View {
        ZStack(alignment: .top) {
            
            // 🌤 Tabs
            TabView(selection: $vm.selectedTab) {
                CurrentWeatherView()
                    .tabItem { Label("Now", systemImage: "sun.max.fill") }
                    .tag(0)
                
                ForecastView()
                    .tabItem { Label("Forecast", systemImage: "calendar") }
                    .tag(1)
                
                MapView()
                    .tabItem { Label("Map", systemImage: "map") }
                    .tag(2)
                
                VisitedPlacesView()
                    .tabItem { Label("Saved", systemImage: "globe") }
                    .tag(3)
            }
            .accentColor(.blue)
            .ignoresSafeArea()
            
            // 🔍 Search Bar
            VStack(spacing: 0) {
                HStack {
                    TextField("Enter location", text: $vm.query)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.search)
                        .onSubmit { vm.submitQuery() }
                        .overlay(alignment: .trailing) {
                            if !vm.query.isEmpty {
                                Button {
                                    vm.query = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.trailing, 4)
                            }
                        }
                    
                    Button {
                        vm.submitQuery()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                        
                    }
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 90))
                .shadow(radius: 3, y: 2)
                .padding(.horizontal)
                .padding(.top, 10) //Space after the camera
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        
        .overlay {
            if vm.isLoading {
                ProgressView("Loading…")
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .alert(item: $vm.appError) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.localizedDescription),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert("Alert", isPresented: $vm.showSavedAlert) {
            Button("OK") {}
        } message: {
            Text("Fetched and saved: \(vm.activePlaceName)")
        }
    }
}

#Preview {
    let vm = MainAppViewModel(context: ModelContext(ModelContainer.preview))
    NavBarView()
        .environmentObject(vm)
}

