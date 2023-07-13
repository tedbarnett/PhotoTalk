//
//  PhotoDetailsViewModel.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 24/06/23.
//

import Foundation

/**
 PhotoDetailsViewModel provides data, state and required backend integration for
 1. Saving/loading audio recorded for the photo
 2. Saving/Loading of location details
 3. Saving/Loading of date details
 */
class PhotoDetailsViewModel: BaseViewModel, ObservableObject {
    
    // MARK: Public properties
    
    @Published var arePhotoDetailsDownloaded = false
    @Published var photoAudioLocalFileUrl: URL?
    @Published var isRecoringInProgress = false
    @Published var didRecordAudio = false
    @Published var isPlayingAudio = false
    @Published var audioDuration: Double = 0
    @Published var audioPlaybackTime: Double = 0
    @Published var audioPlaybackPercent: Double = 0.001
    @Published var photoLocation: String? = ""
    @Published var photoDateString: String? = ""
    @Published var isFavourite: Bool = false
    
    var photos: [CloudAsset]?
    var selectedPhoto: CloudAsset?
    var userProfile: UserProfileModel?
    
    // Application run environment - prod or dev
    var currentEnvironment: Environment = .dev {
        didSet {
            self.storatgeService = FirebaseStorageService(environment: self.currentEnvironment)
            self.databaseService = FirebaseDatabaseService(environment: self.currentEnvironment)
        }
    }
    
    // MARK: Private properties
    
    private var storatgeService: FirebaseStorageService?
    private var databaseService: FirebaseDatabaseService?
    
    // Initializer
    
    init() {
        AudioService.instance.delegate = self
    }
    
    // MARK: Public methods
    
    /**
     Loads details of the photo like location, date, time, etc from server
     */
    func loadPhotoDetails() {
        guard let profile = self.userProfile,
              let photoId = self.selectedPhoto?.photoId,
              let service = self.databaseService else { return }
        service.loadPhotoDetailsFromDatabase(userId: profile.id, photoId: photoId) { details in
            guard let photoDetails = details else {
                self.photoLocation = nil
                return
            }
            self.photoLocation = photoDetails.location
            self.photoDateString = photoDetails.dateAndTime?.photoNodeFormattedDateString
            self.isFavourite = photoDetails.isFavourite
        }
    }
    
    /**
     Initiates the workflow to start user audio recording for the photo
     */
    func startAudioRecording() {
        AudioService.instance.startUserAudioRecording { didStartRecording in
            self.isRecoringInProgress = didStartRecording
            self.didRecordAudio = false
        }
    }
    
    /**
     Attempts to stop user audio recording
     */
    func stopAudioRecording() {
        AudioService.instance.stopUserAudioRecording()
        if self.isRecoringInProgress {
            self.isRecoringInProgress = false
            self.didRecordAudio = true
        }
    }
    
    /**
     It deletes audio recording temporarily saved in local storage so that user
     could record a new audio, if needed.
     */
    func deleteAudioRecordingFromLocal() {
        AudioService.instance.deleteUserAudioRecording()
        
        self.photoAudioLocalFileUrl = nil
        AudioService.instance.audioFileUrl = nil
        self.didRecordAudio = false
        self.audioDuration = 0
        self.audioPlaybackTime = 0
        self.audioPlaybackPercent = 0
    }
    
    /**
     Connects to Firebase storage service to save user recording to the backend
     */
    func saveUserRecordingToServer(responseHandler: @escaping ResponseHandler<Bool>) {
        guard let audioUrl = AudioService.instance.audioFileUrl,
              let profile = self.userProfile,
              let photoId = self.selectedPhoto?.photoId,
              let service = self.storatgeService else {
            responseHandler(false)
            return
        }
        
        service.uploadPhotoAudioFor(userId: profile.id, photoId: photoId, audioUrl: audioUrl) { audioFileName in
            guard let fileName = audioFileName else {
                responseHandler(false)
                return
            }
            print("Saved user audio recording with filename: \(fileName)")
            self.loadPhotoAudio(responseHandler: responseHandler)
        }
    }
    
    /**
     It deletes the audio recording file from backend
     */
    func deleteAudioRecordingFromServer(responseHandler: @escaping ResponseHandler<Bool>) {
        guard let audioUrl = AudioService.instance.audioFileUrl,
              let profile = self.userProfile,
              let photoId = self.selectedPhoto?.photoId,
              let service = self.storatgeService else {
            responseHandler(false)
            return
        }
        
        service.deletePhotoAudioFor(userId: profile.id, photoId: photoId, audioUrl: audioUrl) { didDelete in
            guard didDelete else {
                responseHandler(false)
                return
            }
            print("Deleted user audio recording with filename")
            self.deleteAudioRecordingFromLocal()
            responseHandler(false)
        }
    }
    
    /**
     Connects with Firebase backend to check if user recorded and saved a photo audio for
     the selected photo. If so, it downloads the photo audio content for playback.
     */
    func loadPhotoAudio(responseHandler: @escaping ResponseHandler<Bool>) {
        guard let profile = self.userProfile,
              let photoId = self.selectedPhoto?.photoId,
              let service = self.storatgeService else {
            responseHandler(false)
            return
        }
        
        // Load photo URL from Firebase storage, if not found in local storage
        service.downloadPhotoAudioFor(userId: profile.id, photoId: photoId) { localFileUrl in
            self.isPlayingAudio = false
            self.photoAudioLocalFileUrl = localFileUrl
            self.arePhotoDetailsDownloaded = true
            self.audioDuration = 0
            responseHandler(true)
        }
    }
    
    /**
     Attempts to play available photo audio
     */
    func playAudio() {
        guard let url = self.photoAudioLocalFileUrl else { return }
        self.isPlayingAudio = true
        AudioService.instance.playAudio(url)
    }
    
    /**
     Attempts to pause available photo audio playback
     */
    func pauseAudio() {
        AudioService.instance.pauseAudio()
        self.isPlayingAudio = false
    }
    
    /**
     Attempts to stop available photo audio playback
     */
    func stopAudio() {
        AudioService.instance.stopAudio()
        self.isPlayingAudio = false
    }
    
    /**
     Saves photo location on the server
     */
    func savePhotoLocation(_ location: String, responseHandler: @escaping ResponseHandler<Bool>) {
        guard let profile = self.userProfile,
              let photoId = self.selectedPhoto?.photoId,
              let service = self.databaseService else {
            responseHandler(false)
            return
        }
        
        service.saveLocationForUserPhoto(userId: profile.id, photoId: photoId, location: location) { didSave in
            guard didSave else {
                responseHandler(false)
                return
            }
            self.photoLocation = location
            responseHandler(true)
        }
    }
    
    /**
     Saves photo date and time on the server
     */
    func savePhotoDateAndTime(_ date: Date, responseHandler: @escaping ResponseHandler<Bool>) {
        guard let profile = self.userProfile,
              let photoId = self.selectedPhoto?.photoId,
              let service = self.databaseService else {
            responseHandler(false)
            return
        }
        
        let dateAndTimeString = date.photoNodeFormattedDateString
        service.saveDateAndTimeForUserPhoto(
            userId: profile.id,
            photoId: photoId,
            dateAndTimeString: dateAndTimeString) { didSave in
                guard didSave else {
                    responseHandler(false)
                    return
                }
                self.photoDateString = dateAndTimeString
                responseHandler(true)
            }
    }
    
    /**
     Saves photo date and time on the server
     */
    func updateFavouriteState(responseHandler: @escaping ResponseHandler<Bool>) {
        guard let profile = self.userProfile,
              let photoId = self.selectedPhoto?.photoId,
              let service = self.databaseService else {
            responseHandler(false)
            return
        }
        
        service.saveFavouriteStateForUserPhoto(
            userId: profile.id,
            photoId: photoId,
            isFavourite: !self.isFavourite) { didSave in
                guard didSave else {
                    responseHandler(false)
                    return
                }
                self.isFavourite = !self.isFavourite
                responseHandler(true)
            }
    }
    
    /**
     Resets state and properties to default
     */
    func invalidateViewModel() {
        AudioService.instance.invalidate()
        self.photoAudioLocalFileUrl = nil
    }
}

// MARK: AudioServiceDelegate delegate methods

extension PhotoDetailsViewModel: AudioServiceDelegate {
    func isPlayingAudio(currentTime: Double) {
        self.audioDuration = AudioService.instance.audioDuration
        self.audioPlaybackTime = currentTime
        if self.audioPlaybackTime > 0 && self.audioDuration > 0 {
            self.audioPlaybackPercent = self.audioPlaybackTime/self.audioDuration
        }
    }
    
    func didFinishPlayingAudio() {
        self.isPlayingAudio = false
    }
    
    func didPausePlayingAudio() {
        self.isPlayingAudio = false
    }
    
    func didStopPlayingAudio() {
        self.isPlayingAudio = false
    }
    
    func didResumePlayingAudio() {
        self.isPlayingAudio = true
    }
    
    func didFailPlayingAudio() {
        self.isPlayingAudio = false
    }
}
