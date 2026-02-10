//
//  CurrentWeatherView.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import SwiftUI
import SwiftData

struct CurrentWeatherView: View {
    @EnvironmentObject var vm: MainAppViewModel
    
    var body: some View {
        ZStack {
            
            LinearGradient(
                gradient: Gradient(colors: [
                    weatherTheme.color.opacity(0.6),
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.4)
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .ignoresSafeArea(.all)
            .animation(.easeInOut(duration: 0.8), value: weatherTheme)
            
            if vm.isLoading {
                ProgressView("Loading..")
                    .tint(.black)
                
            } else if let currentWeatherData = vm.currentWeather {
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 25) {
                        
                        HStack(alignment: .center) {
                            Text(vm.activePlaceName)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text(DateFormatterUtils.formattedCurrentDate(format: "EEEE, MMM d"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fontWeight(.semibold)
                        }
                        .padding(.top, 85)
                        
                        VStack(alignment: .leading, spacing: 25) {
                            
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("\(Int(currentWeatherData.temp))°C")
                                        .font(.system(size: 60, weight: .bold))
                                    
                                    Text(currentWeatherData.weather.first?.description.capitalized ?? "")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .padding(.top, 23)
                                }
                                
                                Spacer()
                                
                                Image(systemName: WeatherAdviceCategory.from(
                                    temp: currentWeatherData.temp,
                                    description: currentWeatherData.weather.first?.description ?? ""
                                ).icon)
                                .font(.system(size: 55))
                            }
                            
                            if let todayForecast = vm.forecast.first {
                                HStack(spacing: 16) {
                                    Label("\(Int(todayForecast.temp.max))°C", systemImage: "arrow.up")
                                    Label("\(Int(todayForecast.temp.min))°C", systemImage: "arrow.down")
                                }
                                .font(.headline)
                            }
                            
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Details")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.blue)
                                        .frame(width: 25)
                                    Text("Pressure")
                                    Spacer()
                                    Text("\(currentWeatherData.pressure) hPa")
                                        .fontWeight(.medium)
                                }
                                
                                HStack {
                                    Image(systemName: "sunrise.fill")
                                        .foregroundColor(.blue)
                                        .frame(width: 25)
                                    Text("Sunrise")
                                    Spacer()
                                    Text(DateFormatterUtils.formattedDate(
                                        from: currentWeatherData.sunrise,
                                        format: "HH:mm"
                                    ))
                                    .fontWeight(.medium)
                                }
                                
                                HStack {
                                    Image(systemName: "sunset.fill")
                                        .foregroundColor(.blue)
                                        .frame(width: 25)
                                    Text("Sunset")
                                    Spacer()
                                    Text(DateFormatterUtils.formattedDate(
                                        from: currentWeatherData.sunset,
                                        format: "HH:mm"
                                    ))
                                    .fontWeight(.medium)
                                }
                            }
                            .padding(.top, 16)
                            
                            HStack(spacing: 20) {
                                Image(systemName: weatherTheme.icon)
                                    .font(.system(size: 40))
                                    .foregroundColor(weatherTheme.color)
                                
                                Text(weatherTheme.adviceText)
                                    .font(.callout)
                                    .fontWeight(.medium)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(15)
                            .padding(.top, 20)
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .cornerRadius(30)
                        .shadow(
                            color: .black.opacity(0.1),
                            radius: 10,
                            x: 0,
                            y: 5
                        )
                    }
                    .padding()
                }
                
            } else {
                Text("No weather data available")
                    .foregroundColor(.black)
            }
        }
    }
    
    private var weatherTheme: WeatherAdviceCategory {
        guard let data = vm.currentWeather else { return .unknown }
        return WeatherAdviceCategory.from(
            temp: data.temp,
            description: data.weather.first?.description ?? ""
        )
    }
}

#Preview {
    let vm = MainAppViewModel(context: ModelContext(ModelContainer.preview))
    CurrentWeatherView()
        .environmentObject(vm)
}
