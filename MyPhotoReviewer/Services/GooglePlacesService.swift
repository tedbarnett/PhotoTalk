//
//  GooglePlacesService.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 08/07/23.
//

import Foundation
import GooglePlaces
import CoreLocation


/**
 GooglePlacesService communicates with the Google places API to fetch
 locations to suggest based on user entered string
 */
class GooglePlacesService: ObservableObject {
    
    // MARK: Public properties
    
    @Published var places = [GooglePlace]()
    
    // MARK: Private properties
    
    private let client = GMSPlacesClient.shared()
    
    // MARK: Public methods
    
    /**
     Calls GMSPlacesClient to find places based on given query string.
     Based on the Google places API response, it generates the list of
     location objects to show in UI
     */
    func findPlaces(query: String) {
        let filter = GMSAutocompleteFilter()
        filter.type = .geocode
        self.client.findAutocompletePredictions(
            fromQuery: query,
            filter: filter,
            sessionToken: nil) { gmsResult, error in
                guard let result = gmsResult, error == nil else { return }
                let places = result.compactMap({
                    GooglePlace(id: $0.placeID, name: $0.attributedFullText.string)
                })
                self.places.removeAll()
                self.places.append(contentsOf: places)
            }
    }
}

/**
 GooglePlace object contains details about the locations fetched from
 Google places API
 */
struct GooglePlace {
    let name: String
    let id: String
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    func getCordinates(responseHandler: @escaping ResponseHandler<CLLocation?>)  {
        guard !self.id.isEmpty else {
            responseHandler(nil)
            return
        }
        GMSPlacesClient.shared().lookUpPlaceID(self.id) { place, error in
            guard let googlePlace = place, error == nil else {
                responseHandler(nil)
                return
            }
            let location = CLLocation.init(
                latitude: googlePlace.coordinate.latitude,
                longitude: googlePlace.coordinate.longitude
            )
            responseHandler(location)
        }
    }
}
