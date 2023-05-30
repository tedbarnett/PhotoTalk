//
//  HomeViewModel.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 30/05/23.
//

import Foundation

/**
 HomeViewModel manages data and states for HomeView and helps communicate with the backend APIs.
 */
class HomeViewModel: BaseViewModel, ObservableObject {
    
    // MARK: Public properties
    
    // List of photo albums as loaded from user selected media source
    @Published var photoAlbums = [PhotoAlbum]()
    
    // List of photos (not part of any album) as loaded from user selected media source
    @Published var photos = [Photo]()
    
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
    
    
    // MARK: Public methods
    
    /**
     Presents user consent popups based on user selected media source
     */
    func presentMediaSelectionConsent(for mediaSource: MediaSource) {
        print("Present consent popup for \(mediaSource.name)")
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
