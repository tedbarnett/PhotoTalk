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
        static let authenticationServiceProvider = "authenticationServiceProvider"
        static let userId = "userId"
        static let appleUserId = "appleUserId"
        static let userName = "userName"
        static let userEmail = "userEmail"
        static let appleIdToken = "appleIdToken"
        static let googleIdToken = "googleIdToken"
        static let googleAccessToken = "googleAccessToken"
        static let nonceUserdForAppleAuthentication = "nonceUserdForAppleAuthentication"
        static let didUserAllowPhotoAccess = "didUserAllowPhotoAccess"
        static let userSelectedMediaSource = "userSelectedMediaSource"
        static let userSelectedGoogleDriveFolders = "userSelectedGoogleDriveFolders"
        static let userSelectedIcloudAlbums = "userSelectedIcloudAlbums"
        static let googleDriveFoldersForUser = "googleDriveFoldersForUser"
        static let idsOfUpdatedPhotosByUser = "idsOfUpdatedPhotosByUser"
        static let iCloudAlbumsForUser = "iCloudAlbumsForUser"
        static let photoAudios = "photoAudio"
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
    
    /// This returns logged in user id
    var authenticationServiceProvider: UserAuthenticationServiceProvider? {
        set {
            guard let authProvider = newValue else { return }
            self.userDefaults?.setValue(authProvider.rawValue, forKey: StorageKeys.authenticationServiceProvider)
        } get {
            let provider = self.userDefaults?.string(forKey: StorageKeys.authenticationServiceProvider) ?? ""
            let authProvider = UserAuthenticationServiceProvider(rawValue: provider) ?? nil
            return authProvider
        }
    }
    
    /// Boolean flag indicating, if user granted permission for accessing user photos
    var didUserAllowPhotoAccess: Bool {
        set {
            self.userDefaults?.setValue(newValue, forKey: StorageKeys.didUserAllowPhotoAccess)
        } get {
            let didAllow = self.userDefaults?.bool(forKey: StorageKeys.didUserAllowPhotoAccess) ?? false
            return didAllow
        }
    }
    
    /// This returns logged in user id
    var userId: String {
        set {
            self.userDefaults?.setValue(newValue, forKey: StorageKeys.userId)
        } get {
            let id = self.userDefaults?.string(forKey: StorageKeys.userId) ?? ""
            return id
        }
    }
    
    /// This returns logged in user's Apple id
    var appleUserId: String {
        set {
            self.userDefaults?.setValue(newValue, forKey: StorageKeys.appleUserId)
        } get {
            let id = self.userDefaults?.string(forKey: StorageKeys.appleUserId) ?? ""
            return id
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

    /// This returns logged in user email
    var userEmail: String {
        set {
            self.userDefaults?.setValue(newValue, forKey: StorageKeys.userEmail)
        } get {
            let email = self.userDefaults?.string(forKey: StorageKeys.userEmail) ?? ""
            return email
        }
    }
    
    /// This returns id token obtained after successful user authentication with Apple
    var appleIdToken: String {
        set {
            self.userDefaults?.setValue(newValue, forKey: StorageKeys.appleIdToken)
        } get {
            let token = self.userDefaults?.string(forKey: StorageKeys.appleIdToken) ?? ""
            return token
        }
    }
    
    /// This returns id token obtained after successful user authentication with Google
    var googleIdToken: String {
        set {
            self.userDefaults?.setValue(newValue, forKey: StorageKeys.googleIdToken)
        } get {
            let token = self.userDefaults?.string(forKey: StorageKeys.googleIdToken) ?? ""
            return token
        }
    }
    
    /// This returns access token obtained after successful user authentication with Google
    var googleAccessToken: String {
        set {
            self.userDefaults?.setValue(newValue, forKey: StorageKeys.googleAccessToken)
        } get {
            let token = self.userDefaults?.string(forKey: StorageKeys.googleAccessToken) ?? ""
            return token
        }
    }
    
    /// This returns nonce string used for successful authentication with Apple
    var nonceUserdForAppleAuthentication: String {
        set {
            self.userDefaults?.setValue(newValue, forKey: StorageKeys.nonceUserdForAppleAuthentication)
        } get {
            let nonce = self.userDefaults?.string(forKey: StorageKeys.nonceUserdForAppleAuthentication) ?? ""
            return nonce
        }
    }
    
    /// Returns the media source selected by user for photo access
    var userSelectedMediaSource: String {
        set {
            self.userDefaults?.setValue(newValue, forKey: StorageKeys.userSelectedMediaSource)
        } get {
            let mediaSource = self.userDefaults?.string(forKey: StorageKeys.userSelectedMediaSource) ?? ""
            return mediaSource
        }
    }
    
    /// Returns list of Google Drive folders for logged in user
    var googleDriveFoldersForUser: [PhotoAlbum]? {
        set {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(newValue)
                self.userDefaults?.set(data, forKey: StorageKeys.googleDriveFoldersForUser)
            } catch {
                print("Error saving user user's drive folders to local database - (\(error))")
            }
        } get {
            if let data = UserDefaults.standard.data(forKey: StorageKeys.googleDriveFoldersForUser) {
                do {
                    let decoder = JSONDecoder()
                    let folders = try decoder.decode([PhotoAlbum].self, from: data)
                    return folders
                } catch {
                    print("Error loading user's drive folders from local database - (\(error))")
                    return nil
                }
            } else {
                return nil
            }
        }
    }
    
    /// Returns list of user albums from Apple device local photo gallery album
    var iCloudAlbumsForUser: [PhotoAlbum]? {
        set {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(newValue)
                self.userDefaults?.set(data, forKey: StorageKeys.iCloudAlbumsForUser)
            } catch {
                print("Error saving user's Apple device photo albums to local database - (\(error))")
            }
        } get {
            if let data = UserDefaults.standard.data(forKey: StorageKeys.iCloudAlbumsForUser) {
                do {
                    let decoder = JSONDecoder()
                    let folders = try decoder.decode([PhotoAlbum].self, from: data)
                    return folders
                } catch {
                    print("Error loading user's Apple device photo albums from local database - (\(error))")
                    return nil
                }
            } else {
                return nil
            }
        }
    }
    
    /// Returns user selected Google Drive folders list
    var userSelectedGoogleDriveFolders: [PhotoAlbum]? {
        set {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(newValue)
                self.userDefaults?.set(data, forKey: StorageKeys.userSelectedGoogleDriveFolders)
            } catch {
                print("Error saving user selected folders to local database - (\(error))")
            }
        } get {
            if let data = UserDefaults.standard.data(forKey: StorageKeys.userSelectedGoogleDriveFolders) {
                do {
                    let decoder = JSONDecoder()
                    let folders = try decoder.decode([PhotoAlbum].self, from: data)
                    return folders
                } catch {
                    print("Error loading user selected folders from local database - (\(error))")
                    return nil
                }
            } else {
                return nil
            }
        }
    }
    
    /// Returns user selected Apple device photo gallery album
    var userSelectedIcloudAlbums: [PhotoAlbum]? {
        set {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(newValue)
                self.userDefaults?.set(data, forKey: StorageKeys.userSelectedIcloudAlbums)
            } catch {
                print("Error saving user selected Apple device photo albums to local database - (\(error))")
            }
        } get {
            if let data = UserDefaults.standard.data(forKey: StorageKeys.userSelectedIcloudAlbums) {
                do {
                    let decoder = JSONDecoder()
                    let folders = try decoder.decode([PhotoAlbum].self, from: data)
                    return folders
                } catch {
                    print("Error loading user selected Apple device photo albums from local database - (\(error))")
                    return nil
                }
            } else {
                return nil
            }
        }
    }
    
    /// Returns list of photo audio details saved in local storage
    var photoAudios: [PhotoAudio] {
        set {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(newValue)
                self.userDefaults?.set(data, forKey: StorageKeys.photoAudios)
            } catch {
                print("Error saving user audio files to local database - (\(error))")
            }
        } get {
            if let data = UserDefaults.standard.data(forKey: StorageKeys.photoAudios) {
                do {
                    let decoder = JSONDecoder()
                    let audios = try decoder.decode([PhotoAudio].self, from: data)
                    return audios
                } catch {
                    print("Error loading user's audio files from local database - (\(error))")
                    return [PhotoAudio]()
                }
            } else {
                return [PhotoAudio]()
            }
        }
    }
    
    var idsOfUpdatedPhotosByUser: [String] {
        set {
            self.userDefaults?.set(newValue, forKey: StorageKeys.idsOfUpdatedPhotosByUser)
        } get {
            let ids = self.userDefaults?.object(forKey: StorageKeys.idsOfUpdatedPhotosByUser) as? [String] ?? []
            return ids
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
