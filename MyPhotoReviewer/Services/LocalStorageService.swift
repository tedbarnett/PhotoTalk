//
//  LocalStorageService.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 06/05/23.
//

import Foundation

/// LocalStorageService provides API to read and write simple application and user data/states to/from the device
class LocalStorageService {

    /// Wrapper for local storage keys
    private struct StorageKeys {
        static let isUserAuthenticated = "isUserAuthenticated"
        static let userName = "userName"
    }

    // MARK: Private Properties

    /// Instance of the iOS UserDefaults API
    private var userDefaults: UserDefaults?

    /// User defaults suite name for this app
    private let userDefaultsSuiteName = "com.BarnettLabs.PhotoReview"

    // MARK: Public Properties

    /// Boolean flag indicating, if user is authenticated successfully via the login screen
    var isUserAuthenticated: Bool {
        set {
            self.userDefaults?.setValue(newValue, forKey: StorageKeys.isUserAuthenticated)
        } get {
            let isAuthenticated = self.userDefaults?.bool(forKey: StorageKeys.isUserAuthenticated) ?? false
            return isAuthenticated
        }
    }
    
    /// This returns logged in user name
    var userName: String {
        set {
            self.userDefaults?.setValue(newValue, forKey: StorageKeys.userName)
        } get {
            let name = self.userDefaults?.string(forKey: StorageKeys.userName) ?? UserProfileModel.guestUserName
            return name
        }
    }

    // MARK: Initializer

    init() {
        self.userDefaults = UserDefaults.standard
    }

    // MARK: Public Methods

    // Delete locally saved user default settings
    func reset() {
        if let bundleID = Bundle.main.bundleIdentifier {
            self.userDefaults?.removePersistentDomain(forName: bundleID)
        }
    }
}
