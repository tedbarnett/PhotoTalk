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
    
    static let guestUserName: String = NSLocalizedString("Guest", comment: "Guest user name")

    /// `id` points to acrtual user id in the user selected authentication system
    var id: String
    
    /// `email` is either user selected email during registration
    /// Or email value provided by the user selected authentication sytem like Google, Apple.
    /// This value could be optional for Apple authentication system, if user doesn't wish to share email.
    var email: String?
    
    var name: String
    
    /// Authentication system selected by the user - `firebase, google, apple`
    var authenticationServiceProvider: UserAuthenticationServiceProvider?
    
    /// User selected media source
    var mediaSource: MediaSource?
    
    /// List of photo albums loaded from user selected media source
    var photoAlbums: [PhotoAlbum]?
    
    /// List of photos (which doesn't belong to any photo album) loaded from user selected media source
    var photos: Photo?
    
    /// This boolean flag indicates if the user is authenticated or not
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
