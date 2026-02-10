//
//  WikiService.swift
//  WeatherDashboardTemplate
//
//  Created by Srishankar Sumatharan on 2026-01-06.
//


import Foundation

@MainActor
final class WikiService {
    
    func fetchSummary(for name: String) async throws -> WikipediaSummary {
        
        let formattedName = name.replacingOccurrences(of: " ", with: "_")  //When passing name this will replace the space with underscore
        
        let urlString: String = "https://en.wikipedia.org/api/rest_v1/page/summary/\(formattedName)"
        
        guard let urlString = URL(string: urlString) else {
            throw WeatherMapError.invalidURL(urlString)
        }
        
        let (data, response): (Data, URLResponse)
        
        do {
            (data, response) = try await URLSession.shared.data(from: urlString)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WeatherMapError.invalidResponse(statusCode: -1)
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                return try JSONDecoder().decode(
                    WikipediaSummary.self,
                    from: data
                )
                
            default:
                throw WeatherMapError.invalidResponse(
                    statusCode: httpResponse.statusCode
                )
            }
            
        } catch {
            throw WeatherMapError.networkError(error)
        }
    }
}

