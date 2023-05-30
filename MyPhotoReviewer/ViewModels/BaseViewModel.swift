//
//  BaseViewModel.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 06/05/23.
//

import Foundation

protocol BaseViewModel {
    /// Instance of local storage service. It provides API to read and write simple application and user
    /// data/states to/from the device.
    var localStorageService: LocalStorageService { get }

    /// Boolean flag to check if the current user is authenticated
    var isUserAuthenticated: Bool { get }
}

/// Implementation of the common properties
extension BaseViewModel {
    
    var localStorageService: LocalStorageService {
        return LocalStorageService()
    }

    var isUserAuthenticated: Bool {
        return self.localStorageService.isUserAuthenticated
    }
}
