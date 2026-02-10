//
//  MapView.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//
//

import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    
    @EnvironmentObject var vm: MainAppViewModel
    
    @State private var activeLocationID: UUID?
    @State private var wikiSummary: String? = nil
    
    var body: some View {
        ZStack {
            
            
            LinearGradient(
                colors: [
                    Color.teal.opacity(0.5),
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)
            
            VStack(spacing: 0) {
                
                
                Map(
                    coordinateRegion: $vm.mapRegion,
                    annotationItems: vm.pois
                ) { poi in
                    MapAnnotation(
                        coordinate: CLLocationCoordinate2D(
                            latitude: poi.latitude,
                            longitude: poi.longitude
                        )
                    ) {
                        VStack(spacing: 4) {
                            
                            if activeLocationID == poi.id {
                                if let summary = wikiSummary {
                                    if summary.isEmpty == false {
                                        
                                        VStack(alignment: .trailing, spacing: 0) {
                                            Button {
                                                withAnimation {
                                                    wikiSummary = nil
                                                }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.blue)
                                                    .font(.system(size: 16))
                                            }
                                            .padding(.top, 5)
                                            .padding(.trailing, 5)
                                            
                                            Text(summary)
                                                .font(.system(size: 10))
                                                .multilineTextAlignment(.leading)
                                                .padding(.horizontal, 10)
                                                .padding(.bottom, 10)
                                        }
                                        .frame(width: 240)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(10)
                                        .shadow(radius: 3)
                                        
                                    }
                                }
                            }
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                                .shadow(radius: 2)
                            
                            Text(poi.name)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(0.9))
                                )
                                .fixedSize()
                        }
                        .onTapGesture {
                            activeLocationID = poi.id
                            wikiSummary = nil
                            
                            vm.focus(
                                on: CLLocationCoordinate2D(
                                    latitude: poi.latitude,
                                    longitude: poi.longitude
                                ),
                                zoom: 0.005
                            )
                            
                            Task {
                                let result = await vm.getPOIInfo(for: poi.name)
                                if !result.isEmpty {
                                    wikiSummary = result
                                }
                            }
                            
                        }
                        .onLongPressGesture {
                            vm.openGoogleSearch(for: poi.name)
                        }
                    }
                }
                .frame(height: 300)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 30,
                        topTrailingRadius: 30
                    )
                )
                
                Text("Tap on a map pin to see a summary of the place")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.3))
                
                
                Text("Top 5 Tourist Attractions in \(vm.activePlaceName)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.cyan)
                
                
                ZStack {
                    GeometryReader { geo in
                        Image("MapViewBg")
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width,
                                   height: geo.size.height)
                            .blur(radius: 2.5)
                            .clipped()
                    }
                    
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(vm.pois) { poi in
                                HStack(spacing: 14) {
                                    
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(
                                            activeLocationID == poi.id
                                            ? .blue
                                            : .orange
                                        )
                                    
                                    Text(poi.name)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(
                                            activeLocationID == poi.id
                                            ? .yellow
                                            : .white
                                        )
                                        .shadow(
                                            color: .black.opacity(0.8),
                                            radius: 1,
                                            x: 1,
                                            y: 1
                                        )
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 30)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeInOut) {
                                        activeLocationID = poi.id
                                        wikiSummary = nil
                                    }
                                    
                                    vm.focus(
                                        on: CLLocationCoordinate2D(
                                            latitude: poi.latitude,
                                            longitude: poi.longitude
                                        ),
                                        zoom: 0.005
                                    )
                                }
                            }
                        }
                        .padding(.top, 25)
                        .padding(.bottom, 20)
                    }
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .padding(.top, 85)
        }
    }
}

#Preview {
    let vm = MainAppViewModel(
        context: ModelContext(
            ModelContainer.preview
        )
    )
    
    MapView()
        .environmentObject(vm)
}
