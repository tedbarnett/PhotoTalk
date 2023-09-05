//
//  PhotoSlideShowViewModel.swift
//  MyPhotoReviewer-Development
//
//  Created by Prem Pratap Singh on 15/08/23.
//

import UIKit

/**
 PhotoSlideShowViewModel manages data, state and business logic for PhotoSlideShowView
 */
class PhotoSlideShowViewModel: BaseViewModel, ObservableObject {
    
    // MARK: Public properties
    
    @Published var arePhotoDetailsDownloaded = false
    @Published var photoDetails: [Photo] = []
    @Published var canSlideToLeft: Bool = false
    @Published var canSlideToRight: Bool = true
    
    var userProfile: UserProfileModel?
    var photoAssets: [CloudAsset]?
    var selectedPhotoAsset: CloudAsset? {
        didSet {
            guard let assets = self.photoAssets,
                  let selectedAsset = selectedPhotoAsset else {
                self.currentPhotoIndex = 0
                return
            }
            self.currentPhotoIndex = assets.firstIndex(where: { $0.id == selectedAsset.id }) ?? 0
        }
    }
    var currentPhotoIndex: Int = 0
    
    var currentEnvironment: Environment = .dev {
        didSet {
            self.storageService = FirebaseStorageService(environment: self.currentEnvironment)
            self.databaseService = FirebaseDatabaseService(environment: self.currentEnvironment)
        }
    }
    
    // MARK: Private properties
    
    private var numberOfPhotosToLoadDetailsFor = 3
    private var storageService: FirebaseStorageService?
    private var databaseService: FirebaseDatabaseService?
    
    private var photoDetailsLoadResponseHandler: ResponseHandler<Bool>? = nil
    private var photoDetailsLoadTimer: Timer? = nil
    private var timeElapsedSincePhotoDetailsLoadStart = 0
    private var photoDetailsLoadStatus: [PhotoDetailsLoadStatus] = []
    
    
    // MARK: Public methods
    
    func loadPhotoDetails(responseHandler: @escaping ResponseHandler<Bool>) {
        // load details for current slideIndex and next 2 photos
        // load audio for current slideIndex and next 2 photos
        
        guard let assets = self.photoAssets, !assets.isEmpty else { return }
        
        var indexOfPhotoDetailsToLoad: [Int] = [self.currentPhotoIndex]
        for i in 1..<self.numberOfPhotosToLoadDetailsFor {
            let nextAssetIndex = self.currentPhotoIndex + i
            if nextAssetIndex < assets.count {
                indexOfPhotoDetailsToLoad.append(nextAssetIndex)
            }
        }
        
        print("Loading details for photo assets at index: \(indexOfPhotoDetailsToLoad)")
        
        // Resetting photo details load status
        self.photoDetailsLoadResponseHandler = responseHandler
        self.photoDetailsLoadStatus.removeAll()
        
        if self.photoDetailsLoadTimer == nil {
            self.invalidateTimer()
            self.photoDetailsLoadTimer = Timer.scheduledTimer(
                timeInterval: 1.0,
                target: self,
                selector: #selector(self.onTimerRunCycle),
                userInfo: nil,
                repeats: true
            )
        }
        
        for index in indexOfPhotoDetailsToLoad {
            let asset = assets[index]
            
            // Check if photo details are already loaded for the asset
            // If yes, skip downloading the details
            let arePhotoDetailsAlreadyLoadedForAsset = self.photoDetails.first(where: { $0.id == asset.id }) != nil
            if arePhotoDetailsAlreadyLoadedForAsset {
                print("Photo details are already loaded for asset \(asset.id). Skipping load flow...")
                continue
            }
            
            // Continue with photo details load, if not already loaded
            let loadStatus = PhotoDetailsLoadStatus()
            loadStatus.id = asset.id
            self.photoDetailsLoadStatus.append(loadStatus)
            
            // Loading photo details like location, date time, is favourite, etc
            self.loadDetails(for: asset) { photoDetails in
                guard let details = photoDetails else {
                    loadStatus.didLoadDetails = false
                    print("Error loading details for photo: \(asset.id)")
                    return
                }
                loadStatus.didLoadDetails = true
                print("Loaded details for photo: \(details.id)")
                
                // Loading actual image
                Task {
                    guard let photo = await asset.downloadPhoto(ofSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)) else {
                        loadStatus.didLoadImage = false
                        print("Error loading image for photo: \(details.id)")
                        return
                    }
                    
                    details.image = photo
                    loadStatus.didLoadImage = true
                    print("Loaded image for photo: \(details.id)")
                    
                    DispatchQueue.main.async {
                        if self.photoDetails.first(where: { $0.id == details.id }) == nil {
                            self.photoDetails.append(details)
                        }
                        
                        self.checkPhotoDetailsLoadProgress()
                    }
                }
                
                // Loading audio recording
                self.loadAudio(for: asset) { response in
                    guard let audioLoadResponse = response,
                          let audioURL = audioLoadResponse.audioLocalUrl else {
                        guard let loadResponse = response,
                              let errorCode = loadResponse.errorCode else {
                            loadStatus.didLoadAudio = false
                            return
                        }
                        
                        /**
                         404 error code means that the audio for this photo hasn't been recorded/saved yet
                         therefore it doesn't exist at Firebase storage.
                         Therefore setting `loadStatus.didLoadAudio = true` so that the check for
                         photo details load could succeed.
                         */
                        loadStatus.didLoadAudio = errorCode == 404
                        print("Error loading audio for photo: \(details.id), error code: \(errorCode)")
                        return
                    }
                    details.audioUrl = audioURL
                    loadStatus.didLoadAudio = true
                    print("Loaded audio for photo: \(details.id)")
                    
                    if self.photoDetails.first(where: { $0.id == details.id }) == nil {
                        self.photoDetails.append(details)
                    }
                    
                    self.checkPhotoDetailsLoadProgress()
                }
            }
        }
    }
    
    /**
     On every run cycle of the timer, it checks if the required details for selected photos
     are loaded or not, and responds back to the view via the `photoDetailsLoadResponseHandler`
     */
    @objc private func onTimerRunCycle() {
        self.timeElapsedSincePhotoDetailsLoadStart += 1
        self.checkPhotoDetailsLoadProgress()
    }
    
    private func checkPhotoDetailsLoadProgress() {
        if self.didLoadAllPhotoDetails() {
            self.invalidateTimer()
            
            self.sortPhotosByDate()
            self.photoDetailsLoadResponseHandler?(true)
            self.photoDetailsLoadResponseHandler = nil
        } else {
            if self.timeElapsedSincePhotoDetailsLoadStart >= 12 {
                self.invalidateTimer()
                
                self.photoDetailsLoadResponseHandler?(false)
                self.photoDetailsLoadResponseHandler = nil
            }
        }
    }
    
    private func sortPhotosByDate() {
        self.photoDetails.sort(by: {
            guard let dateOne = $0.dateAndTime, let dateTwo = $1.dateAndTime else { return false }
            return dateOne < dateTwo
        })
    }
    
    private func invalidateTimer() {
        self.photoDetailsLoadTimer?.invalidate()
        self.photoDetailsLoadTimer = nil
    }
    
    /**
     Checks if all of the required details for the selected photos are loaded
     */
    private func didLoadAllPhotoDetails() -> Bool {
        for status in self.photoDetailsLoadStatus {
            if status.didLoadDetails == false || status.didLoadImage == false || status.didLoadAudio == false {
                return false
            }
        }
        return true
    }
    
    func onSlidePhotoTo(index: Int) {
        self.canSlideToLeft = index > 0
        self.canSlideToRight = index < self.photoDetails.count - 1
        
        //let photo = photos[index]
        //self.viewModel.selectedPhoto = photo
        //self.downloadPhotoDetails()
    }
    
    func resetToDefault() {
        self.currentPhotoIndex = 0
        self.invalidateTimer()
        self.photoDetailsLoadResponseHandler = nil
        self.photoDetailsLoadStatus.removeAll()
        self.photoDetails.removeAll()
    }

    
    // MARK: Private methods
    
    private func loadDetails(for asset: CloudAsset, responseHandler: @escaping ResponseHandler<Photo?>) {
        guard let profile = self.userProfile,
              let photoId = asset.photoId,
              let service = self.databaseService else { return }
        service.loadPhotoDetailsFromDatabase(userId: profile.id, photoId: photoId) { response in
            guard let photoDetails = response.photo else {
                responseHandler(nil)
                return
            }
            
            let photo = Photo()
            photo.id = asset.id
            photo.location = photoDetails.location
            photo.dateAndTime = photoDetails.dateAndTime
            photo.isFavourite = photoDetails.isFavourite
            photo.didChangeDetails = photoDetails.didChangeDetails
            responseHandler(photo)
        }
    }
    
    private func loadAudio(for asset: CloudAsset, responseHandler: @escaping ResponseHandler<PhotoAudioLoadResponse?>) {
        guard let profile = self.userProfile,
              let photoId = asset.photoId,
              let service = self.storageService else {
            responseHandler(nil)
            return
        }
        
        // Load photo URL from Firebase storage, if not found in local storage
        service.downloadPhotoAudioFor(userId: profile.id, photoId: photoId) { response in
            responseHandler(response)
        }
    }
}

/**
 PhotoDetailsLoadStatus helps in tracking load progress status for
 details like location, date, actual image, audio, etc. This helps in
 updating the UI state when all required details for the selected photos
 are loaded.
 */
class PhotoDetailsLoadStatus {
    var id: String = ""
    var didLoadDetails = false
    var didLoadImage = false
    var didLoadAudio = false
}
