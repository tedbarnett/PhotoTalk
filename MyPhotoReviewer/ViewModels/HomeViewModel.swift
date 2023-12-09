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
        let itemCount = UIDevice.isIpad ? 6 : 3
        var gridItems = [GridItem]()
        for _ in 0..<itemCount {
            gridItems.append(GridItem(.flexible()))
        }
        return gridItems
    }
    
    var photoGridColumnWidth: CGFloat {
        let itemCount = CGFloat(UIDevice.isIpad ? 6 : 3)
        let spacing: CGFloat = 8
        let unitWidth =  (UIScreen.main.bounds.width - (((itemCount - 1) + 2) * spacing)) / itemCount
        return unitWidth
    }
    
    var isCheckboxSelectedToShowOnlySlideShowPhotos = false
    
    @Published var shouldShowFolderSelectionView = false
    @Published var folders = [CloudAsset]()
    @Published var selectedFolders: [CloudAsset]? = nil
    @Published var photos = [CloudAsset]()
    @Published var filteredPhotos = [CloudAsset]()
    @Published var shouldShowProgressIndicator = false
    
    // Application run environment - prod or dev
    var currentEnvironment: Environment = .dev {
        didSet {
            self.databaseService = FirebaseDatabaseService(environment: self.currentEnvironment)
            self.storageService = FirebaseStorageService(environment: self.currentEnvironment)
        }
    }
    
    var photosUpdatedByUser: [CloudAsset] {
        let idsOfUpdatedPhotos = self.localStorageService.idsOfUpdatedPhotosByUser
        let photos = self.filteredPhotos.filter({
            guard let photoId = $0.photoId else { return false }
            return idsOfUpdatedPhotos.contains(photoId)
        })
        return photos
    }
    
    var photosIncludedInSlideShowByUser: [CloudAsset] {
        let idsOfPhotosToIncludeInSlideShow = self.localStorageService.idsOfPhotosToIncludeInSlideShow
        let photos = self.filteredPhotos.filter({
            guard let photoId = $0.photoId else { return false }
            return idsOfPhotosToIncludeInSlideShow.contains(photoId)
        })
        return photos
    }
    
    // User details like id, name, email, photo albums, photos, audio, etc
    var userProfile: UserProfileModel?
    
    
    // MARK: Private properties
    
    // Database service that helps perfrom CRUD operations with Firebase database
    private var databaseService: FirebaseDatabaseService?
    private var storageService: FirebaseStorageService?
    private var userPhotoService = UserPhotoService()
    private var authenticationViewModel = UserAuthenticationViewModel()
    
    
    // MARK: Public methods
    
    /**
     Loads ids of updated photos from database
     */
    func loadIdsOfUpdatedPhotos() {
        guard let databaseService = self.databaseService, let userProfile = self.userProfile else {
            return
        }
        databaseService.getIdsOfUpdatedPhotosByUser(userId: userProfile.id) { ids in
            self.localStorageService.idsOfUpdatedPhotosByUser = ids
        }
    }
    
    /**
     Calls Firebase database service to get ids of those photos which user marks to include in the slide show
     */
    func loadIdsOfPhotosThoseAreIncludedInSlideShow() {
        guard let databaseService = self.databaseService, let userProfile = self.userProfile else {
            return
        }
        databaseService.getIdsOfPhotosThoseAreIncludedInSlideShow(userId: userProfile.id) { ids in
            self.localStorageService.idsOfPhotosToIncludeInSlideShow = ids
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
    
    func loadUserFoldersFromDatabaseIfAny() {
        guard let mediaSource = self.userProfile?.mediaSource else {
            return
        }
        let driveFolders = self.loadFoldersFromLocalDatabase(targetFolders: .allFolders, mediaSource: mediaSource)
        let userSelectedFolders = self.loadFoldersFromLocalDatabase(targetFolders: .userSelectedFolders, mediaSource: mediaSource)
        
        if !driveFolders.isEmpty {
            self.folders.removeAll()
            self.folders.append(contentsOf: driveFolders)
        }
        
        if !userSelectedFolders.isEmpty {
            self.selectedFolders?.removeAll()
            self.selectedFolders?.append(contentsOf: userSelectedFolders)
        }
    }
    
    /**
     Presents user consent popups based on user selected media source
     */
    func presentMediaSelectionConsent(for mediaSource: MediaSource, responseHandler: @escaping ResponseHandler<Bool>) {
        switch mediaSource {
        case .iCloud: self.userPhotoService.requestAccessToUserICloud { didGrantAccess in
            DispatchQueue.main.async {
                guard didGrantAccess else {
                    responseHandler(false)
                    return
                }
                
                self.localStorageService.didUserAllowPhotoAccess = true
                self.localStorageService.userSelectedMediaSource = mediaSource.rawValue
                responseHandler(true)
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
    
    /**
     Connects to user selected Cloud services to fetch list of assets like phots, folders.
     */
    func downloadCloudAssets(for mediaSource: MediaSource, responseHandler: @escaping ResponseHandler<Bool>) {
        switch mediaSource {
        case .iCloud:
            DispatchQueue.global().async {
                let selectedFolders = self.loadFoldersFromLocalDatabase(targetFolders: .userSelectedFolders, mediaSource: .iCloud)
                if !selectedFolders.isEmpty {
                    DispatchQueue.main.async {
                        self.selectedFolders = selectedFolders
                        self.downloadPhotosFromICloudAlbums(selectedFolders, responseHandler: responseHandler)
                    }
                } else {
                    self.userPhotoService.fetchPhotoAlbumsFromUserDevice { photoAlbums in
                        DispatchQueue.main.async {
                            if !photoAlbums.isEmpty {
                                self.folders.removeAll()
                                self.folders.append(contentsOf: photoAlbums)
                                self.saveFoldersToLocalDatabase(userFolders: photoAlbums, mediaSource: .iCloud)
                                self.shouldShowFolderSelectionView = true
                            } else {
                                self.shouldShowFolderSelectionView = false
                                self.userPhotoService.fetchPhotosFromUserDevice { userPhotos in
                                    self.syncUserSelectedPhotosWithServerPhotos(newlySelectedPhotos: userPhotos)
                                    self.photos.removeAll()
                                    self.photos.append(contentsOf: userPhotos)
                                    self.filteredPhotos.removeAll()
                                    self.filteredPhotos.append(contentsOf: userPhotos)
                                    self.updateSlideShowIncludedPhotoIds()
                                }
                            }
                            responseHandler(true)
                        }
                    }
                }
            }
        case .googleDrive:
            DispatchQueue.global().async {
                self.userPhotoService.downloadUserFoldersFromGoogleDrive { userFolders in
                    
                    guard !userFolders.isEmpty else {
                        self.reauthenticateWithGoogleDriveAndDownloadFolders(responseHandler: responseHandler)
                        return
                    }
                    DispatchQueue.main.async {
                        self.folders.removeAll()
                        self.folders.append(contentsOf: userFolders)
                        
                        self.saveFoldersToLocalDatabase(userFolders: userFolders, mediaSource: .googleDrive)
                        
                        let selectedFolders = self.loadFoldersFromLocalDatabase(targetFolders: .userSelectedFolders, mediaSource: .googleDrive)
                        self.selectedFolders = selectedFolders
                        
                        if selectedFolders.isEmpty {
                            self.shouldShowFolderSelectionView = true
                            responseHandler(true)
                        } else {
                            self.downloadPhotosFromGoogleDriveFolders(selectedFolders, responseHandler: responseHandler)
                        }
                    }
                }
            }
        }
    }
    
    private func reauthenticateWithGoogleDriveAndDownloadFolders(responseHandler: @escaping ResponseHandler<Bool>) {
        let authenticationViewModel = UserAuthenticationViewModel()
        authenticationViewModel.authenticateUserWithGoogleDrive { authToken in
            guard let token = authToken, !token.isEmpty else {
                responseHandler(false)
                return
            }
            
            self.localStorageService.didUserAllowPhotoAccess = true
            self.localStorageService.userSelectedMediaSource = MediaSource.googleDrive.rawValue
            
            self.userPhotoService.downloadUserFoldersFromGoogleDrive { userFolders in
                DispatchQueue.main.async {
                    self.folders.removeAll()
                    self.folders.append(contentsOf: userFolders)
                    
                    self.saveFoldersToLocalDatabase(userFolders: userFolders, mediaSource: .googleDrive)
                    
                    // If user doesn't have any folder, download the photos from root level
                    if userFolders.isEmpty {
                        self.userPhotoService.downloadUserPhotosFromGoogleDrive { userPhotos in
                            self.syncUserSelectedPhotosWithServerPhotos(newlySelectedPhotos: userPhotos)
                            DispatchQueue.main.async {
                                self.photos.removeAll()
                                self.photos.append(contentsOf: userPhotos)
                                self.filteredPhotos.removeAll()
                                self.filteredPhotos.append(contentsOf: userPhotos)
                                self.updateSlideShowIncludedPhotoIds()
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
    
    private func saveFoldersToLocalDatabase(userFolders: [CloudAsset], mediaSource: MediaSource) {
        var albums = [PhotoAlbum]()
        for folder in userFolders {
            var id: String?
            var name: String?
            
            if mediaSource == .iCloud {
                id = folder.iCloudAlbumId
                name = folder.iCloudAlbumTitle
            } else if mediaSource == .googleDrive {
                id = folder.googleDriveFolderId
                name = folder.googleDriveFolderName
            }
            
            if let folderId = id, let folderName = name {
                let album = PhotoAlbum(id: folderId, name: folderName)
                album.isSelected = folder.isSelected
                albums.append(album)
            }
        }
        
        if mediaSource == .iCloud {
            self.localStorageService.iCloudAlbumsForUser = albums
        } else if mediaSource == .googleDrive {
            self.localStorageService.googleDriveFoldersForUser = albums
        }
    }
    
    private func loadFoldersFromLocalDatabase(targetFolders: UserFoldersTarget, mediaSource: MediaSource) -> [CloudAsset] {
        var localDatabaseFolders = [PhotoAlbum]()
        
        if targetFolders == .allFolders {
            if mediaSource == .iCloud, let iCloudAlbums = self.localStorageService.iCloudAlbumsForUser {
                localDatabaseFolders.append(contentsOf: iCloudAlbums)
            } else if mediaSource == .googleDrive, let gDriveFolders = self.localStorageService.googleDriveFoldersForUser {
                localDatabaseFolders.append(contentsOf: gDriveFolders)
            }
        } else if targetFolders == .userSelectedFolders {
            if mediaSource == .iCloud, let iCloudAlbums = self.localStorageService.userSelectedIcloudAlbums {
                localDatabaseFolders.append(contentsOf: iCloudAlbums)
            } else if mediaSource == .googleDrive, let gDriveFolders = self.localStorageService.userSelectedGoogleDriveFolders {
                localDatabaseFolders.append(contentsOf: gDriveFolders)
            }
        }
        
        var driveFolders = [CloudAsset]()
        for folder in localDatabaseFolders {
            let asset = CloudAsset()
            if mediaSource == .iCloud {
                asset.source = .iCloud
                asset.iCloudAlbumId = folder.id
                asset.iCloudAlbumTitle = folder.name
                
                // Fetching thumbnail image for the photo album
                let assetCollections = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [folder.id], options: PHFetchOptions())
                if let collection = assetCollections.firstObject {
                    let albumPhotos = PHAsset.fetchAssets(in: collection, options: nil)
                    if albumPhotos.count > 0 {
                        asset.iCloudAlbumPreviewImage = albumPhotos.firstObject?.getAssetThumbnail()
                    }
                }
            } else if mediaSource == .googleDrive {
                asset.source = .googleDrive
                asset.googleDriveFolderId = folder.id
                asset.googleDriveFolderName = folder.name
            }
            
            asset.isSelected = folder.isSelected
            driveFolders.append(asset)
        }
        
        return driveFolders
    }
    
    func setFoldersAsSelectedIfAny() {
        guard let allSelectedFolders = self.selectedFolders else { return }
        for folder in self.folders {
            if allSelectedFolders.first(where: {
                guard let id1 = $0.albumId, let id2 = folder.albumId else {
                    return false
                }
                return id1 == id2
            }) != nil {
                folder.isSelected = true
            }
        }
    }
    
    /**
     Connects to Google drive sdk to download photos from the given folder reference
     */
    func downloadPhotosFromGoogleDriveFolders(_ folders: [CloudAsset], responseHandler: @escaping ResponseHandler<Bool>) {
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
        self.filteredPhotos.removeAll()
        for folder in folders {
            if let folderId = folder.googleDriveFolderId {
                DispatchQueue.global(qos: .background).async {
                    self.userPhotoService.downloadPhotosFromGoogleDriveFolder(folderId: folderId) { userPhotos in
                        DispatchQueue.main.async {
                            self.photos.append(contentsOf: userPhotos)
                            self.filteredPhotos.append(contentsOf: userPhotos)
                            self.updateSlideShowIncludedPhotoIds()
                            responseHandler(true)
                        }
                    }
                }
            }
        }
        self.syncUserSelectedPhotosWithServerPhotos(newlySelectedPhotos: self.photos)
    }
    
    /**
     Fetches photos from user selected Apple device photo albums
     */
    func downloadPhotosFromICloudAlbums(_ albums: [CloudAsset], responseHandler: @escaping ResponseHandler<Bool>) {
        guard !albums.isEmpty else {
            responseHandler(false)
            return
        }
        
        self.selectedFolders = albums
        
        var photoAlbums = [PhotoAlbum]()
        for album in albums {
            if let id = album.iCloudAlbumId, let name = album.iCloudAlbumTitle {
                let photoAlbum = PhotoAlbum(id: id, name: name)
                photoAlbum.isSelected = true
                photoAlbums.append(photoAlbum)
            }
        }
        self.localStorageService.userSelectedIcloudAlbums = photoAlbums
        
        let iCloudAlbumIds = albums.compactMap { $0.iCloudAlbumId }
        
        guard iCloudAlbumIds.count > 0 else {
            responseHandler(false)
            return
        }
        
        self.photos.removeAll()
        self.filteredPhotos.removeAll()
        let assetCollections = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: iCloudAlbumIds, options: PHFetchOptions())
        for i in 0..<assetCollections.count {
            let collection =  assetCollections[i]
            let assetFetchOptions = PHFetchOptions()
            assetFetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            let fetchResult: PHFetchResult = PHAsset.fetchAssets(in: collection, options: assetFetchOptions)
            
            if fetchResult.count > 0 {
                fetchResult.enumerateObjects { asset, _, _ in
                    let photo = CloudAsset()
                    photo.source = .iCloud
                    photo.iCloudAssetId = asset.localIdentifier
                    photo.width = asset.pixelWidth
                    photo.height = asset.pixelHeight
                    photo.iCloudAsset = asset
                    photo.iCloudPhotoLocation = asset.location
                    photo.iCloudPhotoCreationDate = asset.creationDate
                    photo.date = asset.creationDate
                    self.photos.append(photo)
                    self.filteredPhotos.append(photo)
                }
            }
        }
        
        self.syncUserSelectedPhotosWithServerPhotos(newlySelectedPhotos: self.photos)
        self.updateSlideShowIncludedPhotoIds()
        responseHandler(true)
    }
    
    /**
     Checks if currently loaded/presented photos ids' are part of photos ids' those have been updated
     by the user
     */
    func checkIfAnyOfTheLoadedPhotosUpdatedByUser() {
        let idsOfUpdatedPhotos = self.localStorageService.idsOfUpdatedPhotosByUser
        var didUpdatePhoto = false
        for photo in self.photos {
            if let id = photo.photoId, idsOfUpdatedPhotos.contains(id) {
                didUpdatePhoto = true
                break
            }
        }
        self.userProfile?.didUpdatePhotoDetails = didUpdatePhoto
    }
    
    /**
     It filters list of photos based on the selection state of "Show only slide show photos" checkbox
     */
    func filterPhotosBasedOnCheckBoxSelectionChange(isSelected: Bool) {
        self.isCheckboxSelectedToShowOnlySlideShowPhotos = isSelected
        
        self.filteredPhotos.removeAll()
        if isSelected {
            let idsOfPhotosToIncludeInSlideShow = self.localStorageService.idsOfPhotosToIncludeInSlideShow
            let photos = self.photos.filter({
                guard let photoId = $0.photoId else { return false }
                return idsOfPhotosToIncludeInSlideShow.contains(photoId)
            })
            self.filteredPhotos.append(contentsOf: photos)
        } else {
            self.filteredPhotos.append(contentsOf: self.photos)
        }
    }
    
    /**
     It compares newly selected user photos with previously selected photos and
     1. Adds a new database node for any new selected photo
     2. Removes database node for a unselected photo
     */
    private func syncUserSelectedPhotosWithServerPhotos(newlySelectedPhotos: [CloudAsset]) {
        guard let profile = self.userProfile,
              let service = self.databaseService else { return }
        
        service.doesUserFolderExistUnderPhotoFolder(forUserId: profile.id) { userFolderExists in
            if userFolderExists {
                // Compare newly selected photos with previously selected ones and
                // as needed, add/remove photo node from server database
                service.getUserPhotosFromServer(forUserId: profile.id) { photos in
                    guard let userPhotosOnServer = photos else { return }
                    let serverPhotoIds = userPhotosOnServer.map { $0.id }
                    let newlySelectedPhotoIds = newlySelectedPhotos.map { $0.photoId ?? "" }
                    let newPhotosToSaveOnServer = newlySelectedPhotoIds.filter { serverPhotoIds.contains($0) == false }
                    
                    // Saving newly selected photos to server
                    if !newPhotosToSaveOnServer.isEmpty {
                        let newPhotos = newlySelectedPhotos.filter { newPhotosToSaveOnServer.contains($0.photoId ?? "") }
                        service.saveUserPhotosToDatabase(userId: profile.id, photos: newPhotos) { didSavePhotos in
                            print("Saved user photos to Firebase database")
                        }
                    }
                }
            } else {
                // Save user selected photos to server database
                service.saveUserPhotosToDatabase(userId: profile.id, photos: self.photos) { didSavePhotos in
                    print("Saved user photos to Firebase database")
                }
            }
        }
    }
    
    /**
     It synchronizes locally saved photo ids of slide show included photos with the actual photos
     loaded and showing. This is required because there is a chance of some of the server returning ids
     of slide show included photos (as included in previous app run cycle) may not be included in the
     current list of photos being shown
     */
    private func updateSlideShowIncludedPhotoIds() {
        guard !self.photos.isEmpty else { return }
        let idsOfPhotosToIncludeInSlideShow = self.localStorageService.idsOfPhotosToIncludeInSlideShow
        let idsOfCurrentlyShowingPhotos = self.photos.map { $0.photoId }
        let idsOfCurrentPhotoIncludedInSlideShow = idsOfPhotosToIncludeInSlideShow.filter({ idsOfCurrentlyShowingPhotos.contains($0) })
        
        self.localStorageService.idsOfPhotosToIncludeInSlideShow = idsOfCurrentPhotoIncludedInSlideShow
        self.userProfile?.didAddPhotosToSlideShow = !idsOfCurrentPhotoIncludedInSlideShow.isEmpty
    }
}

enum UserFoldersTarget {
    case allFolders, userSelectedFolders
}

/**
 DropViewDelegate provides drag and drop implementation for home view photos
 */
struct DropViewDelegate: DropDelegate {
    
    let destinationPhoto: CloudAsset
    @Binding var photos: [CloudAsset]
    @Binding var draggedPhoto: CloudAsset?
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        draggedPhoto = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        if let draggedPhoto {
            let fromIndex = photos.firstIndex(of: draggedPhoto)
            if let fromIndex {
                let toIndex = photos.firstIndex(of: destinationPhoto)
                if let toIndex, fromIndex != toIndex {
                    withAnimation {
                        self.photos.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: (toIndex > fromIndex ? (toIndex + 1) : toIndex))
                    }
                }
            }
        }
    }
}
