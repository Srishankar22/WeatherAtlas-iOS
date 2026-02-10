//
//  MainAppViewModel.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import SwiftUI
import SwiftData
import MapKit

@MainActor
final class MainAppViewModel: ObservableObject {
    @Published var query = ""
    @Published var currentWeather: Current?
    @Published var forecast: [Daily] = []
    @Published var pois: [AnnotationModel] = []
    @Published var mapRegion = MKCoordinateRegion()
    @Published var visited: [Place] = []
    @Published var isLoading = false
    @Published var appError: WeatherMapError?
    @Published var activePlaceName: String = ""
    private let defaultPlaceName = "London"
    
    @Published var selectedTab: Int = 0
    @Published var showLoadAlert: Bool = false
    @Published var showSavedAlert: Bool = false
    private let wikiService = WikiService()


    private var errorMessage : String?
    
    /// Create and use a WeatherService model (class) to manage fetching and decoding weather data
    private let weatherService = WeatherService()
    
    /// Create and use a LocationManager model (class) to manage address conversion and tourist places
    private let locationManager = LocationManager()
    
    /// Use a context to manage database operations
    private let context: ModelContext
    
    init(context: ModelContext) {
        // Initialize the ModelContext and attempt to fetch previously visited places from SwiftData, sorted by most recent use.
        // If no visited places exist (first launch), load the default location.
        // Otherwise, load the most recently used place.
        self.context = context
        
        // Corrected FetchDescriptor to include sorting by 'lastUsedAt' in reverse order.
        if let results = try? context.fetch(
            FetchDescriptor<Place>(sortBy: [SortDescriptor(\Place.lastUsedAt, order: .reverse)])
        ) {
            self.visited = results
        }
        
        // First launch: no data → perform full London setup
        if visited.isEmpty {
            Task {
                await loadDefaultLocation()
            }
        } else if let mostRecent = visited.first {
            // Otherwise, load most recently used place
            Task {
                await loadLocation(fromPlace: mostRecent)
            }
        }
    }
    
    func submitQuery() {
        let city = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !city.isEmpty else {
            appError = .missingData(message: "Please enter a valid location.")
            return
        }
        Task {
            do {
                // MARK: call loadLocation(byName:)
                try await loadLocation(byName: city)
                query = ""
            } catch {
                appError = .networkError(error)
            }
        }
    }
    
    func loadDefaultLocation() async {
        // Attempts to select and load the hardcoded default location name.
        // If an error occurs during selection, sets an app error.
        
        isLoading = true
        
        if let existingDefault = visited.first(where: { $0.name.localizedCaseInsensitiveContains(defaultPlaceName) }) {
            do {
                try await loadAll(for: existingDefault)
                existingDefault.lastUsedAt = Date.now
                try context.save()
            } catch {
                self.appError = .networkError(error)
            }
        } else {
            do {
                let (name, lat, lon) = try await locationManager.geocodeAddress(defaultPlaceName)
                let defaultPlace = Place(name: name, latitude: lat, longitude: lon)
                defaultPlace.lastUsedAt = Date.now
                
                context.insert(defaultPlace)
                visited.insert(defaultPlace, at: 0)
                
                try await loadAll(for: defaultPlace)
                try context.save()
            } catch {
                
                if let weatherError = error as? WeatherMapError {
                    self.appError = weatherError
                } else {
                    self.appError = .networkError(error)
                }
            }
        }
        
        isLoading = false
    }
    
    func search() async throws {
        // If the query is not empty, calls `select(placeNamed:)` with the current query string.
        let cityName = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cityName.isEmpty else {
            appError = .missingData(message: "Please enter a location name.")
            return
        }
        
        try await loadLocation(byName: cityName)
        query = ""
    }
    
    /// Validate weather before saving a new place; create POI children once.
    func loadLocation(byName: String) async throws {
        // Sets loading state, then attempts to load data for the given place name.
        isLoading = true
        
        // 1. Checks if the place is already in `visited` and, if so, loads all data for the existing `Place` object, updates its `lastUsedAt`, and saves the context.
        
        if let placeExists = visited.first(where: { $0.name.localizedCaseInsensitiveContains(byName) }) {
            try await loadAll(for: placeExists)
            placeExists.lastUsedAt = Date.now
            try context.save()
        }else{
            do{
                let (name, lat, lon) = try await locationManager.geocodeAddress(byName) // 2. Otherwise, geocodes the fresh place name using `locationManager`.
                
                // 3. Fetches weather data using `weatherService` as a fail-fast check.
                _ =  try await weatherService.fetchWeather(lat: lat, lon: lon)
                
                let requestedPlace = Place(name: name, latitude: lat, longitude: lon)
                requestedPlace.lastUsedAt = Date.now
                context.insert(requestedPlace)
                
                try await loadAll(for: requestedPlace)
                showSavedAlert =  true
            }catch{
                
                if let weatherError = error as? WeatherMapError {
                    errorMessage = weatherError.errorDescription
                } else {
                    // 2. If it's a generic system error (like a URL timeout), wrap it
                    errorMessage = "Could not find '\(byName)'. Please try a more specific city name."
                    
                }
                
                isLoading = false
                
                await revertToDefaultWithAlert(message: errorMessage ?? "Unknown error")
                
            }
            
        }
        
        // 4. Finds Points of Interest (POIs) using `locationManager`, converts them to `AnnotationModel`s, and associates them with the new `Place`.
        // 5. Inserts the new `Place` into the `visited` array and saves the context.
        // 6. Updates UI by setting `pois`, `activePlaceName`, and focusing the map.
        // 7. If any step fails, logs the error and reverts to the default location with an alert.
    }
    
    func loadLocation(fromPlace place: Place) async{
        
        // Sets loading state, then attempts to load all data for an existing `Place` object.
        // Updates the place's `lastUsedAt` and saves the context upon success.
        isLoading =  true
        do{
            try await loadAll(for: place)
            place.lastUsedAt = Date.now
            try context.save()
            
            self.showLoadAlert = true
            self.selectedTab = 0
            
        }catch { // Catches and sets `appError` for any failure during the load process.
            if let weatherError = error as? WeatherMapError {
                self.appError = weatherError
            } else {
                self.appError = .networkError(error)
            }
        }
        isLoading = false
    }
    
    private func revertToDefaultWithAlert(message: String) async {
        // Sets an `appError` with the given message, then calls `loadDefaultLocation()` to switch back to the default.
        self.appError = .missingData(message: message)
        await loadDefaultLocation()
    }
    
    func focus(on coordinate: CLLocationCoordinate2D, zoom: Double = 0.02) {
        // Animates the map region to center on the given coordinate with a specified zoom level (span).
        
        let zoomLevel = MKCoordinateSpan(latitudeDelta: zoom, longitudeDelta: zoom)
        let mapArea = MKCoordinateRegion(center: coordinate, span: zoomLevel)
        
        // Wrapping the update in withAnimation makes the map glide smoothly
        withAnimation(.easeInOut(duration: 2.0)) {
            mapRegion = mapArea
        }
    }
    
    private func loadAll(for place: Place) async throws {
        
        // Sets `activePlaceName` and prints a loading message.
        activePlaceName = place.name
        print("Active place set to: \(place.name)")
        isLoading = true
        
        // Always refreshes weather data from the API.
        let weatherResponse = try await weatherService.fetchWeather(lat: place.latitude, lon: place.longitude)
        currentWeather = weatherResponse.current
        forecast = weatherResponse.daily
        
        // Checks if the `Place` object has existing annotations (POIs).
        // If annotations are empty, fetches new POIs via `MKLocalSearch`, converts them to `AnnotationModel`s, adds them to the `Place`, saves the context, and sets `self.pois`.
        if place.annotations.isEmpty {
            let pointOfInterests = try await locationManager.findPOIs(lat: place.latitude, lon: place.longitude)
            place.annotations = pointOfInterests
            self.pois = pointOfInterests
            try context.save()
        }else{
            self.pois = place.annotations   // If annotations exist, uses the cached list for `self.pois`.
        }
        
        // Calls `focus(on:zoom:)` to update the map view.
        let coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
        focus(on: coordinate)
        
        // Ensures the place is at the top of the `visited` list (if not already).
        if let indexOfPlace = visited.firstIndex(of: place) {
            if indexOfPlace != 0 {
                visited.remove(at: indexOfPlace)
                visited.insert(place, at: 0)
            }
        } else {
            visited.insert(place, at: 0)
        }
        
        isLoading = false
    }
    
    func delete(place: Place) {
        // Deletes the given `Place` object from the ModelContext and removes it from the `visited` array.
        // Attempts to save the context.
        
        visited.removeAll(where: {$0.id == place.id})
        context.delete(place)
        try? context.save()
    }
    
    
    func openGoogleSearch(for cityName: String) {
        guard let encodedName = cityName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.google.com/search?q=\(encodedName)"),
              UIApplication.shared.canOpenURL(url) else {
            return
        }
        
        UIApplication.shared.open(url)
    }
  
    func getPOIInfo(for name: String) async -> String {
        do {
            let result = try await wikiService.fetchSummary(for: name)
            return result.extract
        } catch {
            return "" //empty string to skip if no info is found from the api
        }
    }
    
}
