//
//  LocationManager.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import Foundation
import CoreLocation
@preconcurrency import MapKit


@MainActor
final class LocationManager {
    
    func geocodeAddress(_ address: String) async throws -> (name: String, lat: Double, lon: Double) {
        
        let geocoder = CLGeocoder()
        
        let placemarks = try await geocoder.geocodeAddressString(address)
        
        guard
            let firstPlacemark = placemarks.first,
            let location = firstPlacemark.location,
            let name = firstPlacemark.name
        else {
            throw WeatherMapError.geocodingFailed(address)
        }
        
        let coordinate = location.coordinate
        
        let lat = coordinate.latitude
        let long = coordinate.longitude
        
        return (name: name, lat: lat, lon: long)
        
    }
    
    func findPOIs(lat: Double, lon: Double, limit: Int = 5) async throws -> [AnnotationModel] {
        
        var foundAttractions: [AnnotationModel] = []
        
        let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        let searchRegion = MKCoordinateRegion(
            center: location,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) //0.05 degrees is roughly 5.5km
        )
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "Tourist Attractions"
        request.region = searchRegion
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        for place in response.mapItems.prefix(limit) {
            if let name = place.name {
                let annotation = AnnotationModel(
                    name: name,
                    latitude: place.placemark.coordinate.latitude,
                    longitude: place.placemark.coordinate.longitude
                )
                foundAttractions.append(annotation)
            }
        }
        
        return foundAttractions
    }
}
