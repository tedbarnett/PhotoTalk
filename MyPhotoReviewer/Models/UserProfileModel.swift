//
//  UserProfileModel.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 04/05/23.
//

import Foundation

/// Data object for containing logged in user details
class UserProfileModel: ObservableObject {

    // MARK: Public properties

    var id: String
    var email: String
    var name: String
    
    @Published var isAuthenticated: Bool = false

    // MARK: Initializer

    init(
        id: String,
        email: String,
        name: String
    ) {
        self.id = id
        self.email = email
        self.name = name
    }
}

extension UserProfileModel {

    /// Returns default email for the user
    static var defaultEmail: String {
        return "invalid@email.com"
    }
    
    // Returns default name for the user
    static var defaultName: String {
        return "Guest"
    }

    /// Returns default/test user profile for debugging/testing purpose
    static var defaultUserProfile: UserProfileModel {
        return UserProfileModel(
            id: "",
            email: UserProfileModel.defaultEmail,
            name: UserProfileModel.defaultName
        )
    }
}