//
//  ForecastView.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import SwiftUI
import Charts
import SwiftData


import SwiftUI
import Charts   // Include if you plan to show a chart later

// MARK: - Temperature Category
/// Categorizes temperatures for dynamic UI coloring and chart rendering.
enum TempCategory: String, CaseIterable {
    case cold = "Cold"
    case cool = "Cool"
    case warm = "Warm"
    case hot = "Hot"
    
    /// Returns a specific color for each category to be used in the Forecast Chart.
    var color: Color {
        switch self {
        case .cold:
            return .blue
        case .cool:
            return .cyan
        case .warm:
            return .orange
        case .hot:
            return .red
        }
    }
    
    /// Logic to convert a Celsius temperature into a category.
    /// These ranges ensure the UI adapts to different weather conditions.
    static func from(tempC: Double) -> TempCategory {
        if tempC <= 10 {
            return .cold
        } else if tempC > 10 && tempC <= 20 {
            return .cool
        } else if tempC > 20 && tempC <= 30 {
            return .warm
        } else {
            return .hot
        }
    }
}

// MARK: - Temperature Data Model
/// A single temperature reading for the chart or list.
private struct TempData: Identifiable {
    let id = UUID()
    let time: Date          // e.g., forecast date
    let type: String        // e.g., "High" or "Low"
    let value: Double       // numeric value
    let category: TempCategory
}

// MARK: - Forecast View
/// Stubbed Forecast View that includes an image placeholder to show
/// what the final view will look like. Replace the image once real data and charts are added.
struct ForecastView: View {
    @EnvironmentObject var vm: MainAppViewModel
    
    /// Converts forecast data into chart-friendly entries.
    private var chartData: [TempData] {
        vm.forecast.flatMap { day in
            [
                
                TempData(
                    time: DateFormatterUtils.convertToDate(from: Int(day.dt)),
                    type: "Low",
                    value: day.temp.min,
                    category: .from(tempC: day.temp.min)
                ),
                
                TempData(
                    time: DateFormatterUtils.convertToDate(from: Int(day.dt)),
                    type: "High",
                    value: day.temp.max,
                    category: .from(tempC: day.temp.max)
                )
            ]
        }
    }
    
    
    var body: some View {
        ZStack {
            
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.5),
                    Color.orange.opacity(0.4),
                    Color.purple.opacity(0.4),
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("8 Day Forecast - \(vm.activePlaceName)")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Daily Highs and Lows (°C)")
                            .font(.system(size: 16))
                            .foregroundStyle(.primary)
                    }
                    .padding(.top, 85)
                    
                    VStack {
                        Chart(chartData) { item in
                            BarMark(
                                x: .value("Day", item.time, unit: .day),
                                y: .value("Temp", item.value),
                                width: .fixed(12)
                            )
                            .foregroundStyle(item.category.color)
                            .position(by: .value("Type", item.type))
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { value in
                                
                                let label = value.as(Date.self).map {
                                    DateFormatterUtils.formattedDate(from: Int($0.timeIntervalSince1970), format: "E")
                                } ?? ""
                                
                                AxisValueLabel(label)
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                            }
                        }
                    }
                    .padding()
                    .frame(height: 260)
                    .background(.ultraThinMaterial.opacity(0.5))
                    .cornerRadius(18)
                    
                    
                    Text("Detailed Daily Summary")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(vm.forecast, id: \.dt) { day in
                            VStack(alignment: .leading, spacing: 8) {
                                
                                Text(DateFormatterUtils.formattedDate(
                                    from: Int(day.dt),
                                    format: "EEEE, MMM d"
                                ))
                                .fontWeight(.bold)
                                .padding(.top, 14)
                                
                                Text(day.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                
                                Text("Low: \(Int(day.temp.min))°C  High: \(Int(day.temp.max))°C")
                                    .font(.system(size: 13))
                                    .fontWeight(.medium)
                                
                                if day.dt == vm.forecast.last?.dt {
                                    Spacer()
                                        .frame(height: 15) // To add a space after the last item in the list
                                }
                                
                                if day.dt != vm.forecast.last?.dt {
                                    Divider()
                                        .padding(.bottom, 8)
                                }
                            }
                            .padding(.horizontal, 14)
                        }
                    }
                    .background(.ultraThinMaterial)
                    .cornerRadius(18)
                }
                .padding()
            }
        }
    }
}

#Preview {
    let vm = MainAppViewModel(context: ModelContext(ModelContainer.preview))
    ForecastView()
        .environmentObject(vm)
}
