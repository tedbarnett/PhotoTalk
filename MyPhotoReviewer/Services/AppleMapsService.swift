//
//  AppleMapsService.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 28/10/23.
//

import Foundation
import MapKit
import Combine

/**
 AppleMapsService helps in using services of Apple map services like searching for a location, etc
 */
class AppleMapsService: NSObject, ObservableObject {
    
    // MARK: Public properties
    
    static let sharedInstance = AppleMapsService()
    @Published var places = [AppleMapLocation]()
    
    // MARK: - Private properties
    
    @Published private var searchQuery = ""
    private var cancellable: AnyCancellable?
    private var completer: MKLocalSearchCompleter
    
    
    // MARK: - Constructor
    
    override private init() {
        self.completer = MKLocalSearchCompleter()
        
        super.init()
        
        self.cancellable = self.$searchQuery.assign(to: \.queryFragment, on: self.completer)
        self.completer.delegate = self
        self.completer.resultTypes = .address
    }
    
    // MARK: - Public methods
    
    /**
     Attempts to find matching locations with given search string
     */
    func getLocations(for searchString: String) {
        self.searchQuery = searchString
    }
    
    /**
     Clears list of searched locations
     */
    func clearSearchResults() {
        self.places.removeAll()
    }
}

// MARK: - MKLocalSearchCompleterDelegate methods

extension AppleMapsService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        var mapLocations = completer.results.map { result in
            AppleMapLocation(title: result.title, subTitle: result.subtitle)
        }
        mapLocations.sort(by: { $0.title < $1.title })
        self.places.removeAll()
        self.places.append(contentsOf: mapLocations)
    }
}

/**
 AppleMapLocation data object represent detaiils about a location
 */
struct AppleMapLocation {
    let id: String = UUID().uuidString
    let title: String
    let subTitle: String
    
    func getLocation() async throws -> CLLocation? {
        return try await withCheckedThrowingContinuation { continuation in
            let geocoder = CLGeocoder()
            let locationString = "\(self.title), \(self.subTitle)"
            geocoder.geocodeAddressString(locationString) { placemarks, error in
                guard error == nil,
                      let placeMarks = placemarks,
                      let firstPlacemark = placeMarks.first,
                      let location = firstPlacemark.location else {
                    if let err = error {
                        return continuation.resume(throwing: err)
                    }
                    return
                }
                return continuation.resume(returning: location)
            }
        }
    }
}
