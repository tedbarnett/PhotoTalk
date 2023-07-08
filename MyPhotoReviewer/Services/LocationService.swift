//
//  LocationService.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 07/07/23.
//

import Foundation
import Combine
import MapKit

/**
 LocationService suggests locations based on user entered text so that user could
 pick recommended location for the photo. It uses MapKit framework to fetch location
 recommendation.
 */
class LocationService: NSObject, ObservableObject {

    // MARK: Public properties
    
    @Published var queryFragment: String = ""
    @Published private(set) var status: LocationServiceStatus = .idle
    @Published private(set) var searchResults: [MKLocalSearchCompletion] = []

    // MARK: Private properties
    
    private var queryCancellable: AnyCancellable?
    private let searchCompleter: MKLocalSearchCompleter!

    // MARK: Initializer
    
    init(searchCompleter: MKLocalSearchCompleter = MKLocalSearchCompleter()) {
        self.searchCompleter = searchCompleter
        super.init()
        self.searchCompleter.delegate = self

        queryCancellable = $queryFragment
            .receive(on: DispatchQueue.main)
            // we're debouncing the search, because the search completer is rate limited.
            // feel free to play with the proper value here
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main, options: nil)
            .sink(receiveValue: { fragment in
                self.status = .isSearching
                if !fragment.isEmpty {
                    self.searchCompleter.queryFragment = fragment
                } else {
                    self.status = .idle
                    self.searchResults = []
                }
        })
    }
}

extension LocationService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Depending on what you're searching, you might need to filter differently or
        // remove the filter altogether. Filtering for an empty Subtitle seems to filter
        // out a lot of places and only shows cities and countries.
        self.searchResults = completer.results.filter({ $0.subtitle == "" })
        self.status = completer.results.isEmpty ? .noResults : .result
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        self.status = .error(error.localizedDescription)
    }
}

/**
 LocationServiceStatus defines different states relate to communicating with MapKit and
 location recommendations
 */
enum LocationServiceStatus: Equatable {
    case idle
    case noResults
    case isSearching
    case error(String)
    case result
}
