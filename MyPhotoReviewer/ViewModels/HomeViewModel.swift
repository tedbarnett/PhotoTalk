//
//  HomeViewModel.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 30/05/23.
//

import UIKit
import GoogleSignIn
import PhotosUI
import Photos
import SwiftUI

/**
 HomeViewModel manages data and states for HomeView and helps communicate with the backend APIs.
 */
class HomeViewModel: BaseViewModel, ObservableObject {
    
    // MARK: Public properties
    
    // List of photo albums as loaded from user selected media source
    @Published var photoAlbums = [PhotoAlbum]()
    
    var photoGridColumns: [GridItem] {
        let itemCount = UIDevice.isIpad ? 4 : 2
        var gridItems = [GridItem]()
        for _ in 0..<itemCount {
            gridItems.append(GridItem(.flexible()))
        }
        return gridItems
    }
    
    var photoGridColumnWidth: CGFloat {
        let itemCount = CGFloat(UIDevice.isIpad ? 4 : 2)
        let spacing: CGFloat = 16
        let unitWidth =  (UIScreen.main.bounds.width - (((itemCount - 1) + 2) * spacing)) / itemCount
        return unitWidth
    }
    
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
                databaseService.loadUserDetailsFromDatabase(userProfile, responseHandler: responseHandler)
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
    
    func loadGoogleDriveFoldersFromDatabaseIfAny() {
        let driveFolders = self.loadFoldersFromLocalDatabase(targetFolders: .allFolders)
        let userSelectedFolders = self.loadFoldersFromLocalDatabase(targetFolders: .userSelectedFolders)
        
        guard !driveFolders.isEmpty else { return }
        self.folders.removeAll()
        self.folders.append(contentsOf: driveFolders)
    }
    
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
            self.authenticationViewModel.authenticateUserWithGoogleDrive { authToken in
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
    
    func presentICloudPhotoPicker() {
        guard let rootViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {
            return
        }
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: rootViewController) { _ in
            self.downloadCloudAssets(for: .iCloud) {_ in }
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
            let selectedFolders = self.loadFoldersFromLocalDatabase(targetFolders: .userSelectedFolders)
            if !selectedFolders.isEmpty {
                self.selectedFolders = selectedFolders
                self.downloadPhotosFromFolders(selectedFolders, responseHandler: responseHandler)
            } else {
                DispatchQueue.global().async {
                    self.userPhotoService.downloadUserFoldersFromGoogleDrive { userFolders in
                        DispatchQueue.main.async {
                            self.folders.removeAll()
                            self.folders.append(contentsOf: userFolders)
                            
                            self.saveFoldersToLocalDatabase(userFolders: userFolders)
                            
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
    
    private func saveFoldersToLocalDatabase(userFolders: [CloudAsset]) {
        var driveFolder = [PhotoAlbum]()
        for folder in userFolders {
            if let id = folder.googleDriveFolderId, let name = folder.googleDriveFolderName {
                let album = PhotoAlbum(id: id, name: name)
                album.isSelected = folder.isSelected
                driveFolder.append(album)
            }
        }
        self.localStorageService.googleDriveFoldersForUser = driveFolder
    }
    
    private func loadFoldersFromLocalDatabase(targetFolders: GoogleDriveFoldersTarget) -> [CloudAsset] {
        var driveFolders = [CloudAsset]()
        var localDatabaseFolders = [PhotoAlbum]()
        
        if targetFolders == .allFolders, let allDriveFolders = self.localStorageService.googleDriveFoldersForUser {
            localDatabaseFolders.append(contentsOf: allDriveFolders)
        } else if targetFolders == .userSelectedFolders, let selectedFolders = self.localStorageService.userSelectedGoogleDriveFolders {
            localDatabaseFolders.append(contentsOf: selectedFolders)
        }
        
        for folder in localDatabaseFolders {
            let asset = CloudAsset()
            asset.googleDriveFolderId = folder.id
            asset.googleDriveFolderName = folder.name
            asset.isSelected = folder.isSelected
            driveFolders.append(asset)
        }
        return driveFolders
    }
    
    /**
     Connects to Google drive sdk to download photos from the given folder reference
     */
    func downloadPhotosFromFolders(_ folders: [CloudAsset], responseHandler: @escaping ResponseHandler<Bool>) {
        guard !folders.isEmpty else {
            responseHandler(false)
            return
        }
        self.selectedFolders = folders
        
        var photoAlbums = [PhotoAlbum]()
        for folder in folders {
            if let id = folder.googleDriveFolderId, let name = folder.googleDriveFolderName {
                let photoAlbum = PhotoAlbum(id: id, name: name)
                photoAlbum.isSelected = true
                photoAlbums.append(photoAlbum)
            }
        }
        self.localStorageService.userSelectedGoogleDriveFolders = photoAlbums
        
        self.photos.removeAll()
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
}

enum GoogleDriveFoldersTarget {
    case allFolders, userSelectedFolders
}
