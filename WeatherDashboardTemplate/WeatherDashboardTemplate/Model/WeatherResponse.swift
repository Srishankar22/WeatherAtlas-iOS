//
//  WeatherResponse.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import Foundation

struct WeatherResponse: Codable {
    let lat, lon: Double
    let current: Current
    let daily: [Daily]

    enum CodingKeys: String, CodingKey {
        case lat, lon
        case current, daily
    }
}

struct Current: Codable {
    let dt, sunrise, sunset: Int
    let temp: Double
    let pressure: Int
    let weather: [Weather]
}

struct Weather: Codable {
    let id: Int
    let description, icon: String
}


struct Daily: Codable {
    let dt, sunrise, sunset, moonrise: Int
    let summary: String
    let temp: Temp
}

struct Temp: Codable {
    let day, min, max, night: Double
    let eve, morn: Double
}
