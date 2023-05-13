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
        responseHandler: @escaping ResponseHandler<AlertType>) {
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                
                guard error == nil,
                    let result = authResult,
                    let userEmail = result.user.email,
                    let userName = result.user.displayName else {
                    responseHandler(.userLoginFailed)
                    return
                }
                
                guard result.user.isEmailVerified else {
                    responseHandler(.userLoginFailedDueToUnverifiedAccount)
                    return
                }

                guard let profile = self.userProfile else {
                    responseHandler(.userLoginFailed)
                    return
                }
                
                profile.id = result.user.uid
                profile.email = userEmail
                profile.name = userName
                
                self.localStorageService.isUserAuthenticated = true
                self.localStorageService.userName = profile.name
                
                responseHandler(.userLoginSuccessfull)
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
                guard error == nil,
                      let result = authResult else {
                    responseHandler(false)
                    return
                }
                
                // Sending account verification email
                result.user.sendEmailVerification { _ in
                    print("An account verfication email is sent to \(email)")
                    
                    // Updating name for the user
                    let changeRequest = result.user.createProfileChangeRequest()
                    changeRequest.displayName = name
                    changeRequest.commitChanges { _ in
                        print("User name is updated as \(name)")
                    }
                }
                
                responseHandler(true)
            }
    }
    
    /**
     Sends user email for resetting password
     */
    func sendEmailForPasswordReset(userEmail: String, responseHandler: @escaping ResponseHandler<Bool>) {
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
