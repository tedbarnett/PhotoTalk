//
//  HomeViewModel.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 30/05/23.
//

import UIKit
import GoogleSignIn

/**
 HomeViewModel manages data and states for HomeView and helps communicate with the backend APIs.
 */
class HomeViewModel: BaseViewModel, ObservableObject {
    
    // MARK: Public properties
    
    // List of photo albums as loaded from user selected media source
    @Published var photoAlbums = [PhotoAlbum]()
    
    // List of photos (not part of any album) as loaded from user selected media source
    //@Published var photos = [Photo]()
    
    @Published var shouldShowFolderSelectionView = false
    @Published var folders = [CloudAsset]()
    @Published var selectedFolders: [CloudAsset]? = nil
    @Published var photos = [CloudAsset]()
    
    @Published var shouldShowProgressIndicator = false
    
    // Application run environment - prod or dev
    var currentEnvironment: Environment = .dev {
        didSet {
            self.databaseService = FirebaseDatabaseService(environment: self.currentEnvironment)
        }
    }
    
    // User details like id, name, email, photo albums, photos, audio, etc
    var userProfile: UserProfileModel?
    
    
    // MARK: Private properties
    
    // Database service that helps perfrom CRUD operations with Firebase database
    private var databaseService: FirebaseDatabaseService?
    private var userPhotoService = UserPhotoService()
    private var authenticationViewModel = UserAuthenticationViewModel()
    
    
    // MARK: Public methods
    
    /**
     Presents user consent popups based on user selected media source
     */
    func presentMediaSelectionConsent(for mediaSource: MediaSource, responseHandler: @escaping ResponseHandler<Bool>) {
        switch mediaSource {
        case .iCloud: self.userPhotoService.requestAccessToUserICloud { didGrantAccess in
            DispatchQueue.main.async {
                self.localStorageService.didUserAllowPhotoAccess = true
                self.localStorageService.userSelectedMediaSource = mediaSource.rawValue
                responseHandler(didGrantAccess)
            }
        }
        case .googleDrive:
            self.authenticationViewModel.authenticateUserWithGoogle { authToken in
                guard let token = authToken, !token.isEmpty else {
                    responseHandler(false)
                    return
                }
                
                self.localStorageService.didUserAllowPhotoAccess = true
                self.localStorageService.userSelectedMediaSource = mediaSource.rawValue
                responseHandler(true)
            }
        }
    }
    
    /**
     Connects to user selected Cloud services to fetch list of assets like phots, folders.
     */
    func downloadCloudAssets(for mediaSource: MediaSource, responseHandler: @escaping ResponseHandler<Bool>) {
        switch mediaSource {
        case .iCloud:
            DispatchQueue.global().async {
                self.userPhotoService.downloadUserPhotosFromICloud { userPhotos in
                    DispatchQueue.main.async {
                        self.photos.removeAll()
                        self.photos.append(contentsOf: userPhotos)
                        responseHandler(true)
                    }
                }
            }
        case .googleDrive:
            if let selectedFolders = self.localStorageService.userSelectedGoogleDriveFolders {
                var assets = [CloudAsset]()
                for folder in selectedFolders {
                    let asset = CloudAsset()
                    asset.googleDriveFolderId = folder.id
                    asset.isSelected = true
                    assets.append(asset)
                }
                self.selectedFolders = assets
                self.downloadPhotosFromFolders(assets, responseHandler: responseHandler)
            } else {
                DispatchQueue.global().async {
                    self.userPhotoService.downloadUserFoldersFromGoogleDrive { userFolders in
                        DispatchQueue.main.async {
                            self.folders.removeAll()
                            self.folders.append(contentsOf: userFolders)
                            
                            // If user doesn't have any folder, download the photos from root level
                            if userFolders.isEmpty {
                                self.userPhotoService.downloadUserPhotosFromGoogleDrive { userPhotos in
                                    DispatchQueue.main.async {
                                        self.photos.removeAll()
                                        self.photos.append(contentsOf: userPhotos)
                                        responseHandler(true)
                                    }
                                }
                            } else {
                                self.shouldShowFolderSelectionView = true
                                responseHandler(true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    /**
     Connects to Google drive sdk to download photos from the given folder reference
     */
    func downloadPhotosFromFolders(_ folders: [CloudAsset], responseHandler: @escaping ResponseHandler<Bool>) {
        guard !folders.isEmpty else { return }
        self.selectedFolders = folders
        
        var photoAlbums = [PhotoAlbum]()
        for folder in folders {
            if let id = folder.googleDriveFolderId, let name = folder.googleDriveFolderName {
                let photoAlbum = PhotoAlbum(id: id, name: name)
                photoAlbums.append(photoAlbum)
            }
        }
        self.localStorageService.userSelectedGoogleDriveFolders = photoAlbums
        
        for folder in folders {
            if let folderId = folder.googleDriveFolderId {
                DispatchQueue.global(qos: .background).async {
                    self.userPhotoService.downloadPhotosFromGoogleDriveFolder(folderId: folderId) { userPhotos in
                        DispatchQueue.main.async {
                            self.photos.append(contentsOf: userPhotos)
                            responseHandler(true)
                        }
                    }
                }
            }
        }
    }
    
    /**
     Calls database service to fetch user details (name, email, photo albums, audio, etc) from Firebase database.
     If user details aren't found in database, it adds save user details in the database
     */
    func loadUserDetailsFromDatabase(responseHandler: @escaping ResponseHandler<Bool>) {
        guard let databaseService = self.databaseService, let userProfile = self.userProfile else {
            responseHandler(false)
            return
        }
        
        databaseService.areUserDetailsSavedToDatabase(forUserId: userProfile.id) { areDetailsSaved in
            // Loading user details if available in the database
            if areDetailsSaved {
                print("load user details")
                responseHandler(true)
            }
            // Else, saving user details to the database for the first time
            else {
                databaseService.saveUserDetailsToDatabase(userProfile) { didSaveDetails in
                    print("Saved user details to the database")
                    responseHandler(false)
                }
            }
        }
    }
}
