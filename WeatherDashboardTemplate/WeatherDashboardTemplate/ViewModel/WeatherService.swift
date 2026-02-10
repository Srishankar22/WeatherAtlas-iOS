//
//  WeatherService.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import Foundation

@MainActor
final class WeatherService {
    
    private let apiKey = "PASTE_YOUR_API_KEY_TO_OPENWEATHER"
    
    func fetchWeather(lat: Double, lon: Double) async throws -> WeatherResponse {
        // Constructs a URL for the OpenWeatherMap OneCall API using the provided coordinates and API key.
        // Performs an asynchronous network request using URLSession.
        // Validates the HTTP response status code.
        // Decodes the received JSON data into a `WeatherResponse` object, using a specific date decoding strategy.
        // Handles and throws specific `WeatherMapError` types for invalid URL, network failure, invalid response, and decoding errors.
        
        let urlString : String = "https://api.openweathermap.org/data/3.0/onecall?lat=\(lat)&lon=\(lon)&exclude=minutely,hourly,alerts&units=metric&appid=\(apiKey)"
        
        guard let urlString = URL(string: urlString) else {
            throw WeatherMapError.invalidURL(urlString)
        }
        
        let (data, response) : (Data, URLResponse)
        
        do{
            (data, response) = try await URLSession.shared.data(from: urlString)
            
            guard let httpResponse = response as? HTTPURLResponse else{
                throw WeatherMapError.invalidResponse(statusCode: -1)
            }
            
            switch httpResponse.statusCode{
            case 200...299:
                let jsonDecoded = try JSONDecoder().decode(WeatherResponse.self, from: data)
                return jsonDecoded
                
            default:
                print("Server Error: \(httpResponse.statusCode)")
                throw WeatherMapError.invalidResponse(statusCode: httpResponse.statusCode)
            }
            
        }catch {
            throw WeatherMapError.networkError(error)
        }
        
    }
}
