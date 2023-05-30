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
                    print("[Firebase Database] Failed to save user details to database")
                    responseHandler(false)
                    return
                }
                print("[Firebase Database] Successfully saved user details to database - \(userDetails)")
                responseHandler(true)
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
