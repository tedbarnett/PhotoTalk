//
//  FirebaseDatabaseServiceError.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 29/05/23.
//

import Foundation

/*
 FirebaseDatabaseServiceError enumeration defines possible
 databse read/write/update related errrors
 */
enum FirebaseDatabaseServiceError: String, Error {
    case userAuthenticationError = "Firebase user not authenticated for database operations"
    case noRecordFound = "No record found for the user"
    case databaseReadError = "Error loading records from the firebase database"
    case databaseWriteError = "Error saving records in the firebase database"
    case databaseUpdateError = "Error updating record template"
    
    var description: String {
        return self.rawValue
    }
}
