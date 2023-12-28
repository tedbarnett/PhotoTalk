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
    @Published var isPlaybackPaused: Bool = false
    
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
    private var assetsForVideoExport = [AssetForVideoExport]()
    
    // MARK: Public methods
    
    /**
     Calls Firebase storeage service to get ids of audio recorded and uploaded to Firebase storage by the user.
     After getting the audio ids, it then finds out the photo ids for which audio recordings are saved in the Firebase storage.
     */
    func getPhotoIdsWithUserUploadedAudio(responseHandler: @escaping ResponseHandler<Bool>) {
        guard let profile = self.userProfile,
              let assets = self.photoAssets,
              !assets.isEmpty else {
            responseHandler(false)
            return
        }
        self.storageService?.getPhotoAudioFor(userId: profile.id) { ids in
            guard let audioIds = ids else {
                responseHandler(false)
                return
            }
            
            let photoIds = audioIds.map {
                // Audio ids are in `{photo-id}.m4a` format. Hence to pick photo id from audio file names,
                // we need to split the audio id and pick the first part
                let audioNameParts = $0.split(separator: ".")
                return audioNameParts[0]
            }
            
            guard !photoIds.isEmpty else {
                responseHandler(false)
                return
            }
            
            // Picking up the image assets for which an audio annotation is saved in Firebase storage
            self.assetsForVideoExport.removeAll()
            for asset in assets {
                if let photoId = asset.photoId, photoIds.first(where: { $0 == photoId }) != nil {
                    let videoAsset = AssetForVideoExport(id: photoId, image: nil, audioUrl: nil)
                    self.assetsForVideoExport.append(videoAsset)
                }
            }
            responseHandler(true)
        }
    }
    
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
        
        self.invalidateTimer()
        self.startTimer()
        
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
                    
                    print("Loaded image for photo: \(details.id)")
                    loadStatus.didLoadImage = true
                    details.image = photo
                    
                    // Setting image for the video export asset
                    if let videoAsset = self.assetsForVideoExport.first(where: { $0.id == asset.photoId }) {
                        videoAsset.image = photo
                    }
                    
                    DispatchQueue.main.async {
                        if self.photoDetails.first(where: { $0.id == asset.photoId }) == nil {
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
                    
                    print("Loaded audio for photo: \(details.id)")
                    loadStatus.didLoadAudio = true
                    details.audioUrl = audioURL
                    
                    // Setting audio for the video export asset
                    if let videoAsset = self.assetsForVideoExport.first(where: { $0.id == asset.photoId }) {
                        videoAsset.audioUrl = audioURL
                    }
                    
                    if self.photoDetails.first(where: { $0.id == asset.photoId }) == nil {
                        self.photoDetails.append(details)
                    }
                    
                    self.checkPhotoDetailsLoadProgress()
                }
            }
        }
    }
    
    /**
     Downloads image, details (datec location, etc) and audio for the assets to be included in the exported slideshow video
     */
    func loadAssetDetailsForVideoExport(responseHandler: @escaping ResponseHandler<Bool>) {
        guard !self.assetsForVideoExport.isEmpty,
              let photoAssets = self.photoAssets else {
            responseHandler(false)
            return
        }
        
        // Pausing slide show playback till the process of video export/share is completed
        //self.isPlaybackPaused = true
        //self.invalidateTimer()
        
        if self.areAllAssetDetailsLoaded() {
            responseHandler(true)
            return
        }
        
        for asset in self.assetsForVideoExport {
            if !asset.areDetailsLoaded, let photoAsset = photoAssets.first(where: { $0.photoId == asset.id }) {
                // Loading photo details like location, date time, is favourite, etc
                self.loadDetails(for: photoAsset) { photoDetails in
                    guard let details = photoDetails else {
                        print("Error loading details for photo: \(asset.id)")
                        return
                    }
                    
                    print("Loaded details for photo: \(details.id)")
                    asset.location = details.location
                    asset.dateString = details.dateAndTime?.photoNodeFormattedDateString
                    
                    // Loading actual image
                    Task {
                        guard let photo = await photoAsset.downloadPhoto(ofSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)) else {
                            print("Error loading image for photo: \(details.id)")
                            return
                        }
                        
                        print("Loaded image for photo: \(details.id)")
                        asset.image = photo
                        
                        if self.areAllAssetDetailsLoaded() {
                            responseHandler(true)
                        }
                    }
                    
                    // Loading audio recording
                    self.loadAudio(for: photoAsset) { response in
                        guard let audioLoadResponse = response,
                              let audioURL = audioLoadResponse.audioLocalUrl else {
                            print("Error loading audio for photo: \(details.id)")
                            return
                        }
                        
                        print("Loaded audio for photo: \(details.id)")
                        asset.audioUrl = audioURL
                        if let videoAsset = self.assetsForVideoExport.first(where: { $0.id == photoAsset.photoId }) {
                            videoAsset.audioUrl = audioURL
                        }
                        
                        if self.areAllAssetDetailsLoaded() {
                            responseHandler(true)
                        }
                    }
                }
            }
        }
    }
    
    /**
     Calls VideoService to generate an MP4 video with the asset details (photo and audio url)
     */
    func generateVideoFromAssets(responseHandler: @escaping ResponseHandler<URL?>) {
        guard !self.assetsForVideoExport.isEmpty else {
            responseHandler(nil)
            return
        }
        
        let videoService = VideoService()
        let images = self.assetsForVideoExport.compactMap({ $0.image })
        let audioUrls = self.assetsForVideoExport.compactMap({ $0.audioUrl })
        videoService.exportVideo(with: images, audioURL: audioUrls) { videoUrl in
            guard let url = videoUrl else { return }
            print("Yeah! successfully exported slide show video at URL: \(url.absoluteString)")
            responseHandler(url)
        }
    }
    
    /**
     Checks if the details (image and audio) are loaded for all video assets
     */
    private func areAllAssetDetailsLoaded() -> Bool {
        for asset in self.assetsForVideoExport {
            if !asset.areDetailsLoaded {
                return false
            }
        }
        return true
    }
    
    private func startTimer() {
        guard self.photoDetailsLoadTimer == nil else { return }
        self.photoDetailsLoadTimer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(self.onTimerRunCycle),
            userInfo: nil,
            repeats: true
        )
    }
    
    private func invalidateTimer() {
        self.photoDetailsLoadTimer?.invalidate()
        self.photoDetailsLoadTimer = nil
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
            
            self.sortPhotos()
            self.photoDetailsLoadResponseHandler?(true)
            self.photoDetailsLoadResponseHandler = nil
        } else {
            if self.timeElapsedSincePhotoDetailsLoadStart >= 25 {
                self.invalidateTimer()
                
                self.photoDetailsLoadResponseHandler?(false)
                self.photoDetailsLoadResponseHandler = nil
            }
        }
    }
    
    private func sortPhotos() {
        let sortedPhotoIds = self.photoDetailsLoadStatus.map { $0.id }
        var sortedPhotos = [Photo]()
        for id in sortedPhotoIds {
            if let photo = self.photoDetails.first(where: {$0.id == id}) {
                sortedPhotos.append(photo)
            }
        }
        
        self.photoDetails = sortedPhotos
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

/**
 AssetForVideoExport contains details about an image and its annotation audio
 that have to be included in the exported video for slide show
 */
class AssetForVideoExport {
    var id: String = ""
    var image: UIImage?
    var audioUrl: URL?
    var location: String?
    var dateString: String?
    
    var areDetailsLoaded: Bool {
        return self.image != nil && self.audioUrl != nil
    }
    
    init(id: String, image: UIImage?, audioUrl: URL?) {
        self.id = id
        self.image = image
        self.audioUrl = audioUrl
    }
}
