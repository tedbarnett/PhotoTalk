//
//  FirebaseDatabaseService.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 23/05/23.
//

import FirebaseDatabase
import Firebase
import Foundation
import FirebaseAuth

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
    
    /**
     Checks if Firebase `Photo` folder has a sub folder with name matching user id
     */
    func doesUserFolderExistUnderPhotoFolder(
        forUserId: String,
        responseHandler: @escaping ResponseHandler<Bool>) {
            let databaseReference: DatabaseReference = Database.database().reference(fromURL: self.environment.databaseUrl)
            let userDirectory = databaseReference.child(PhotoNodeProperties.nodeName).child(forUserId)
            
            userDirectory.getData { error, snapshot in
                guard error == nil,
                      let dataSnapshot = snapshot else {
                    print("[Firebase Database] User folder doesn't exist under photo folder")
                    responseHandler(false)
                    return
                }
                
                let areDetailsSaved = dataSnapshot.exists()
                print("[Firebase Database] User folder exists under photo folder")
                responseHandler(areDetailsSaved)
            }
    }
    
    /// Saves user details to the database for the authenticated user
    func loadPhotoDetailsFromDatabase(
        userId: String,
        photoId: String,
        responseHandler: @escaping ResponseHandler<Photo?>) {
            let databaseReference: DatabaseReference = Database.database().reference(fromURL: self.environment.databaseUrl)
            let userDirectory = databaseReference.child(PhotoNodeProperties.nodeName).child(userId)
            let photoReference = userDirectory.child(photoId)
            photoReference.getData { error, snapshot in
                guard error == nil,
                      let dataSnapshot = snapshot,
                      dataSnapshot.exists(),
                      let userDetails = dataSnapshot.value as? [String: Any] else {
                    print("[Firebase Database] Failed to load photo details for id \(photoId)")
                    responseHandler(nil)
                    return
                }
                
                let photo = Photo()
                if let id = userDetails[DatabaseNodeCommonProperties.id] as? String {
                    photo.id = id
                }
                
                if let location = userDetails[PhotoNodeProperties.location] as? String {
                    photo.location = location
                }
                
                if let dateAndTimeString = userDetails[PhotoNodeProperties.dateAndTime] as? String {
                    photo.dateAndTime = dateAndTimeString.photoNodeDateFromString
                }
                
                if let isFavourite = userDetails[PhotoNodeProperties.isFavourite] as? String {
                    photo.isFavourite = isFavourite == "1"
                }
                
                print("[Firebase Database] Successfully loaded photo details for id \(photoId)")
                responseHandler(photo)
            }
        }
    
    /**
     Checks if Firebase `Photo` folder has a sub folder with name matching user id
     */
    func getUserPhotosFromServer(
        forUserId: String,
        responseHandler: @escaping ResponseHandler<[Photo]?>) {
            let databaseReference: DatabaseReference = Database.database().reference(fromURL: self.environment.databaseUrl)
            let userDirectory = databaseReference.child(PhotoNodeProperties.nodeName).child(forUserId)
            
            userDirectory.getData { error, snapshot in
                guard error == nil,
                      let dataSnapshot = snapshot,
                      dataSnapshot.exists(),
                      let photos = dataSnapshot.value as? [String: [String: Any]] else {
                    print("[Firebase Database] Error loading User photos from server")
                    responseHandler(nil)
                    return
                }
                
                var userPhotos = [Photo]()
                for (key, _) in photos {
                    let photo = Photo()
                    photo.id = key
                    userPhotos.append(photo)
                }
                print("[Firebase Database] Successfully loaded user photos from server")
                responseHandler(userPhotos)
            }
    }
    
    /**
     Adds a new database node for each user selected photo
     */
    func saveUserPhotosToDatabase(
        userId: String,
        photos: [CloudAsset],
        responseHandler: @escaping ResponseHandler<Bool>) {
            let databaseReference: DatabaseReference = Database.database().reference(fromURL: self.environment.databaseUrl)
            let userDirectory = databaseReference.child(PhotoNodeProperties.nodeName).child(userId)
            
            for photo in photos {
                if let id = photo.photoId {
                    let photoNode = userDirectory.child(id)
                    
                    // Checking if a photo node with the same id already exist
                    // Saving photos to database shouldn't overide already saved photo details
                    photoNode.getData { error, snapshot in
                        guard error == nil,
                              let dataSnapshot = snapshot,
                              !dataSnapshot.exists() else {
                            return
                        }
                        var photoDetails: [String: Any] = [
                            DatabaseNodeCommonProperties.id: id,
                            UserNodeProperties.mediaSource: photo.source.rawValue
                        ]
                        photoDetails[PhotoNodeProperties.dateAndTime] = nil
                        photoDetails[PhotoNodeProperties.location] = nil
                        photoNode.setValue(photoDetails) { error, reference in
                            guard error == nil else {
                                print("[Firebase Database] Failed to save photo details for photo \(id)")
                                return
                            }
                            print("[Firebase Database] Successfully saved photo details for photo \(id)")
                        }
                    }
                }
            }
            
            responseHandler(true)
    }
    
    /**
     Removes database node for the given photos
     */
    func removeUserPhotosFromDatabase(
        userId: String,
        photos: [Photo],
        responseHandler: @escaping ResponseHandler<Bool>) {
            let databaseReference: DatabaseReference = Database.database().reference(fromURL: self.environment.databaseUrl)
            let userDirectory = databaseReference.child(PhotoNodeProperties.nodeName).child(userId)
            
            for photo in photos {
                let photoNode = userDirectory.child(photo.id)
                photoNode.removeValue { error, _ in
                    guard error == nil else {
                        print("[Firebase Database] error deleting photo with id \(photo.id)")
                        return
                    }
                    print("[Firebase Database] Successfuly deleted photo with id \(photo.id)")
                }
            }
            responseHandler(true)
    }
    
    /**
     Saves given location for the useer photo with given user id and photo id
     */
    func saveLocationForUserPhoto(
        userId: String,
        photoId: String,
        location: String,
        responseHandler: @escaping ResponseHandler<Bool>) {
            let databaseReference: DatabaseReference = Database.database().reference(fromURL: self.environment.databaseUrl)
            let userDirectory = databaseReference.child(PhotoNodeProperties.nodeName).child(userId)
            let photoReference = userDirectory.child(photoId)
            
            let locationDetails: [String: Any] = [
                PhotoNodeProperties.location: location
            ]
            
            photoReference.updateChildValues(locationDetails) { error, reference in
                guard error == nil else {
                    print("[Firebase Database] Failed to save location for photo \(photoId)")
                    responseHandler(false)
                    return
                }
                print("[Firebase Database] Successfully saved location for photo \(photoId)")
                responseHandler(true)
            }
    }
    
    /**
     Saves given date/time details for the user photo with given user id and photo id
     */
    func saveDateAndTimeForUserPhoto(
        userId: String,
        photoId: String,
        dateAndTimeString: String,
        responseHandler: @escaping ResponseHandler<Bool>) {
            let databaseReference: DatabaseReference = Database.database().reference(fromURL: self.environment.databaseUrl)
            let userDirectory = databaseReference.child(PhotoNodeProperties.nodeName).child(userId)
            let photoReference = userDirectory.child(photoId)
            
            let dateAndTimeDetails: [String: Any] = [
                PhotoNodeProperties.dateAndTime: dateAndTimeString
            ]
            
            photoReference.updateChildValues(dateAndTimeDetails) { error, reference in
                guard error == nil else {
                    print("[Firebase Database] Failed to save date and time for photo \(photoId)")
                    responseHandler(false)
                    return
                }
                print("[Firebase Database] Successfully saved date and time for photo \(photoId)")
                responseHandler(true)
            }
    }
    
    /**
     Saves favourite state for the user photo with given user id and photo id
     */
    func saveFavouriteStateForUserPhoto(
        userId: String,
        photoId: String,
        isFavourite: Bool,
        responseHandler: @escaping ResponseHandler<Bool>) {
            let databaseReference: DatabaseReference = Database.database().reference(fromURL: self.environment.databaseUrl)
            let userDirectory = databaseReference.child(PhotoNodeProperties.nodeName).child(userId)
            let photoReference = userDirectory.child(photoId)
            
            let favouriteStateDetails: [String: Any] = [
                PhotoNodeProperties.isFavourite: isFavourite ? "1" : "0"
            ]
            
            photoReference.updateChildValues(favouriteStateDetails) { error, reference in
                guard error == nil else {
                    print("[Firebase Database] Failed to save favourite state for photo \(photoId)")
                    responseHandler(false)
                    return
                }
                print("[Firebase Database] Successfully saved favourite state for photo \(photoId)")
                responseHandler(true)
            }
    }
}

// MARK: Photo audios related database operations
extension FirebaseDatabaseService {
}

// MARK: Photo locations related database operations
extension FirebaseDatabaseService {
}
