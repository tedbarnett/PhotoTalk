//
//  UserAuthenticationViewModel.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 06/05/23.
//

import Foundation
import FirebaseAuth

/**
 UserAuthenticationViewModel communicates with Firebase authentication services for
 1. Registering new user with name, email and password
 2. Login user with email and password
 3. Logout user
 4. Delete user account
 */
class UserAuthenticationViewModel: ObservableObject, BaseViewModel {
    
    // MARK: Public properties
    
    var userProfile: UserProfileModel?
    
    // MARK: Public methods
    
    /**
     Calls Firebase authentication service to login user with email and password combination
     */
    func authenticateUser(
        with email: String,
        password: String,
        responseHandler: @escaping ResponseHandler<Bool>) {
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                guard let result = authResult,
                      let userEmail = result.user.email,
                      let userName = result.user.displayName,
                      error == nil else {
                    responseHandler(false)
                    return
                }

                guard let profile = self.userProfile else {
                    responseHandler(false)
                    return
                }
                
                profile.id = result.user.uid
                profile.email = userEmail
                profile.name = userName
                
                self.localStorageService.isUserAuthenticated = true
                self.localStorageService.userName = profile.name
                
                responseHandler(true)
            }
    }
    
    /**
     Calls Firebase authentication service to register new user with name, email and password combination
     */
    func registerUser(
        with name: String,
        email: String,
        password: String,
        responseHandler: @escaping ResponseHandler<Bool>) {
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                guard error == nil else {
                    responseHandler(false)
                    return
                }

                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = name
                changeRequest?.commitChanges { _ in
                    responseHandler(true)
                }
            }
    }
    
    /**
     Sends user email for resetting password 
     */
    func sendEmailForPasswordReset(userEmail: String, responseHandler: @escaping ResponseHandler<Bool>) {
        guard let userProfile = self.userProfile else {
            responseHandler(false)
            return
        }
        Auth.auth().sendPasswordReset(withEmail: userEmail) { error in
            guard error == nil else {
                responseHandler(false)
                return
            }
            responseHandler(true)
        }
    }
    
    /**
     Calls Firebase authentication service to logout user
     */
    func logutUser(responseHandler: @escaping ResponseHandler<Bool>) {
        do {
            try Auth.auth().signOut()
            
            self.localStorageService.isUserAuthenticated = false
            self.localStorageService.userName = UserProfileModel.guestUserName
            
            responseHandler(true)
        } catch {
            responseHandler(false)
        }
    }
}
