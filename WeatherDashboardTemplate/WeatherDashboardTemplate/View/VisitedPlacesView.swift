//
//  VisitedPLacesView.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import SwiftUI
import SwiftData

struct VisitedPlacesView: View {
    @EnvironmentObject var vm: MainAppViewModel
    @Environment(\.modelContext) private var context // Not used in body, but kept for completeness
    
    var body: some View {
        ZStack {
            // MARK: Visual Consistency Requirement
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.teal.opacity(0.5),
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                
                Text("Visited Places 📍")
                    .font(.system(size: 32, weight: .bold))
                    .padding(.horizontal)
                    .padding(.top, 25)
                    .padding(.bottom, 15)
                
                
                if vm.visited.isEmpty {
                    
                    VStack(spacing: 15) {
                        Spacer()
                        
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        
                        Text("No Visited Places")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("Saved places will appear here after you search for them.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    
                } else {
                    
                    List {
                        ForEach(vm.visited) { place in
                            VStack(alignment: .leading, spacing: 10) {
                                
                                HStack {
                                    Text(place.name)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                                
                                HStack(spacing: 15) {
                                    Text("Lat: \(place.latitude, specifier: "%.2f")°")
                                    Text("Lon: \(place.longitude, specifier: "%.2f")°")
                                }
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                                
                                Divider().opacity(0.3)
                                
                                HStack {
                                    Image(systemName: "clock")
                                    Text("Last Viewed: \(DateFormatterUtils.formattedDateTime(from: place.lastUsedAt.timeIntervalSince1970))")
                                }
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.blue.opacity(0.8))
                            }
                            .padding(16)
                            .background(.ultraThinMaterial.opacity(0.5))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                Task { await vm.loadLocation(fromPlace: place) }
                            }
                            .onLongPressGesture {
                                vm.openGoogleSearch(for: place.name)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                vm.delete(place: vm.visited[index])
                            }
                        }
                    }
                    .listStyle(.plain)
                    .padding(.bottom, 20)
                }
            }
            .padding(.top, 85)
        }
        .alert("Location Loaded", isPresented: $vm.showLoadAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(vm.activePlaceName) is now your active location.")
        }
    }
}

#Preview {
    let vm = MainAppViewModel(context: ModelContext(ModelContainer.preview))
    VisitedPlacesView()
        .environmentObject(vm)
}
