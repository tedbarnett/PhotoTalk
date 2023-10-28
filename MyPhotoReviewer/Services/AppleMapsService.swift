//
//  AppleMapsService.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 28/10/23.
//

import Foundation
import CoreLocation

/**
 AppleMapsService helps in using services of Apple map services like searching for a location, etc
 */
class AppleMapsService: ObservableObject {
    
    // MARK: Public properties
    
    static let sharedInstance = AppleMapsService()
    @Published var places = [AppleMapLocation]()
    
    // MARK: - Private properties
    
    private let locationManager = CLLocationManager()
    
    // MARK: - Constructor
    
    private init() {}
    
    // MARK: - Public methods
    
    /**
     Requests user consent for access to device location service
     */
    func requestAuthorization() {
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    /**
     Attempts to find matching locations with given search string
     */
    func getLocations(for searchString: String) {
        var matchingLocations = [AppleMapLocation]()
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(searchString) { placemarks, error in
            guard error == nil, let locations = placemarks else {
                return
            }

            for location in locations {
                if let locationDetails = location.location, let name = location.name, let locality = location.locality, let country = location.country {
                    let location = AppleMapLocation(name: name, locality: locality, country: country, location: locationDetails)
                    matchingLocations.append(location)
                }
            }
            
            guard !matchingLocations.isEmpty else { return }
            self.places.removeAll()
            self.places.append(contentsOf: matchingLocations)
        }
    }
}

/**
 AppleMapLocation data object represent detaiils about a location
 */
struct AppleMapLocation {
    let id: String = UUID().uuidString
    let name: String
    let locality: String
    let country: String
    let location: CLLocation
}
