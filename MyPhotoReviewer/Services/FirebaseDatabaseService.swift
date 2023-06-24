//
//  FirebaseDatabaseService.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 23/05/23.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase

/**
 FirebaseDatabaseService helps in setting up connection to the application Firebase database and
 perform CRUD operations (read, write, update, delete operations) for the data objects used in the app
 like user, photo albums, photo, photo audio, location, etc
 */
class FirebaseDatabaseService {
    
    // MARK: Private Properties
    
    private var environment: Environment = .dev
    
    // MARK: Initializers
    
    init(environment: Environment) {
        self.environment = environment
        print("Connecting to Firebase databse - \(self.environment.databaseUrl)")
    }
}

// MARK: User profile related database operations
extension FirebaseDatabaseService {
    
    /**
     Checks if user details are already saved in the database
     */
    func areUserDetailsSavedToDatabase(
        forUserId: String,
        responseHandler: @escaping ResponseHandler<Bool>) {
            let databaseReference: DatabaseReference = Database.database().reference(fromURL: self.environment.databaseUrl)
            let userDirectory = databaseReference.child(UserNodeProperties.nodeName).child(forUserId)
            
            userDirectory.getData { error, snapshot in
                guard error == nil,
                      let dataSnapshot = snapshot else {
                    print("[Firebase Database] User details aren't saved to the database")
                    responseHandler(false)
                    return
                }
                
                let areDetailsSaved = dataSnapshot.exists()
                print("[Firebase Database] User details \(areDetailsSaved ? "are" : "aren't") saved to the database")
                responseHandler(areDetailsSaved)
            }
        }
    
    /// Saves user details to the database for the authenticated user
    func saveUserDetailsToDatabase(
        _ userProfile: UserProfileModel,
        responseHandler: @escaping ResponseHandler<Bool>) {
            
            let databaseReference: DatabaseReference = Database.database().reference(fromURL: self.environment.databaseUrl)
            let userDirectory = databaseReference.child(UserNodeProperties.nodeName).child(userProfile.id)
            
            var userDetails: [String: Any] = [
                DatabaseNodeCommonProperties.id: userProfile.id,
                DatabaseNodeCommonProperties.name: userProfile.name
            ]
            
            if let userEmail = userProfile.email {
                userDetails[UserNodeProperties.email] = userEmail
            }
            
            if let authenticationServiceProvider = userProfile.authenticationServiceProvider {
                userDetails[UserNodeProperties.authenticationServiceProvider] = authenticationServiceProvider.rawValue
            }
            
            if let mediaSource = userProfile.mediaSource {
                userDetails[UserNodeProperties.mediaSource] = mediaSource.rawValue
            } else {
                userDetails[UserNodeProperties.mediaSource] = nil
            }
            
            userDirectory.setValue(userDetails) { error, reference in
                guard error == nil else {
                    print("[Firebase Database] Failed to save user details for user \(userProfile.id)")
                    responseHandler(false)
                    return
                }
                print("[Firebase Database] Successfully saved user details for user \(userProfile.id)")
                responseHandler(true)
            }
        }
    
    /// Saves user details to the database for the authenticated user
    func loadUserDetailsFromDatabase(
        _ userProfile: UserProfileModel,
        responseHandler: @escaping ResponseHandler<Bool>) {
            let databaseReference: DatabaseReference = Database.database().reference(fromURL: self.environment.databaseUrl)
            let userDirectory = databaseReference.child(UserNodeProperties.nodeName).child(userProfile.id)
            userDirectory.getData { error, snapshot in
                guard error == nil,
                      let dataSnapshot = snapshot,
                      dataSnapshot.exists(),
                      let userDetails = dataSnapshot.value as? [String: Any] else {
                    print("[Firebase Database] Failed to load user details for user \(userProfile.id)")
                    responseHandler(false)
                    return
                }
                
                if let userName = userDetails[DatabaseNodeCommonProperties.name] as? String {
                    userProfile.name = userName
                }
                
                if let email = userDetails[UserNodeProperties.email] as? String {
                    userProfile.email = email
                }
                
                if let authProvider = userDetails[UserNodeProperties.authenticationServiceProvider] as? String {
                    userProfile.authenticationServiceProvider = UserAuthenticationServiceProvider(rawValue: authProvider)
                }
                
                if let mediaSource = userDetails[UserNodeProperties.mediaSource] as? String {
                    userProfile.mediaSource = MediaSource(rawValue: mediaSource)
                }
                print("[Firebase Database] Successfully loaded user details for user \(userProfile.id)")
                responseHandler(true)
            }
        }
    
    /**
     Checks if Firebase `PhotoAudio` folder has a sub folder with name matching user id
     */
    func doesUserFolderExistUnderPhotoAudioFolder(
        forUserId: String,
        responseHandler: @escaping ResponseHandler<Bool>) {
            let databaseReference: DatabaseReference = Database.database().reference(fromURL: self.environment.databaseUrl)
            let userDirectory = databaseReference.child(PhotoAudioNodeProperties.nodeName).child(forUserId)
            
            userDirectory.getData { error, snapshot in
                guard error == nil,
                      let dataSnapshot = snapshot else {
                    print("[Firebase Database] User folder doesn't exist under photo audio folder")
                    responseHandler(false)
                    return
                }
                
                let areDetailsSaved = dataSnapshot.exists()
                print("[Firebase Database] User folder exists under photo audio folder")
                responseHandler(areDetailsSaved)
            }
    }
    
    /**
     Checks if user details are already saved in the database
     */
    func doesAudioExistInDatabase(
        forUserId: String,
        forPhotoId: String,
        responseHandler: @escaping ResponseHandler<Bool>) {
            let databaseReference: DatabaseReference = Database.database().reference(fromURL: self.environment.databaseUrl)
            let userDirectory = databaseReference.child(PhotoAudioNodeProperties.nodeName).child(forUserId).child(forPhotoId)
            
            userDirectory.getData { error, snapshot in
                guard error == nil,
                      let dataSnapshot = snapshot else {
                    print("[Firebase Database] User photo audio aren't saved to the database")
                    responseHandler(false)
                    return
                }
                
                let areDetailsSaved = dataSnapshot.exists()
                print("[Firebase Database] User details \(areDetailsSaved ? "are" : "aren't") saved to the database")
                responseHandler(areDetailsSaved)
            }
        }
}

// MARK: Photo albums related database operations
extension FirebaseDatabaseService {
}

// MARK: Photos related database operations
extension FirebaseDatabaseService {
}

// MARK: Photo audios related database operations
extension FirebaseDatabaseService {
}

// MARK: Photo locations related database operations
extension FirebaseDatabaseService {
}
