//
//  UserAuthenticationViewModel.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 06/05/23.
//

import Foundation
import FirebaseAuth
import AuthenticationServices

/**
 UserAuthenticationViewModel communicates with Firebase authentication services for
 1. Registering new user with name, email and password
 2. Login user with email and password
 3. Logout user
 4. Delete user account
 */
class UserAuthenticationViewModel: NSObject, ObservableObject, BaseViewModel {
    
    // MARK: Public properties
    
    var userProfile: UserProfileModel?
    var authenticationResponseHandler: ResponseHandler<Bool>?
    
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
                profile.authenticationProvider = .firebase
                
                self.localStorageService.isUserAuthenticated = true
                self.localStorageService.userAuthenticationProvider = .firebase
                self.localStorageService.userId = profile.id
                self.localStorageService.userName = profile.name
                
                responseHandler(.userLoginSuccessfull)
            }
    }
    
    /**
     It initiates the sign in flow using Apple authentication framework
     */
    func signInWithApple(responseHandler: ResponseHandler<Bool>?) {
        self.authenticationResponseHandler = responseHandler
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
    
    func signInWithGoogle() {
        
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
     This method checks if the logged in user authentication state is still valid.
     If the authentication state is invalidated/expired by the authentication service provider,
     it logs user out of the system and prsents the login prompt
     */
    func validateUserAuthenticationStateIfNeeded() {
        let localStorageService = LocalStorageService()
        guard localStorageService.isUserAuthenticated,
              let userProfile = self.userProfile else { return }
        
        if localStorageService.userAuthenticationProvider == .apple {
            userProfile.authenticationProvider = .apple
            userProfile.id = localStorageService.userId
            userProfile.name = localStorageService.userName
            
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            appleIDProvider.getCredentialState(forUserID: localStorageService.userId) { credentialState, error in
                switch credentialState {
                case .authorized:
                    // The Apple ID credential is valid.
                    DispatchQueue.main.async {
                        userProfile.isAuthenticated = true
                    }
                    break
                case .revoked, .notFound:
                    // The Apple ID credential is either revoked or was not found, so show the sign-in UI.
                    DispatchQueue.main.async {
                        userProfile.isAuthenticated = false
                    }
                default:
                    break
                }
            }
        } else if localStorageService.userAuthenticationProvider == .firebase {
            userProfile.authenticationProvider = .firebase
            userProfile.id = localStorageService.userId
            userProfile.name = localStorageService.userName
            userProfile.isAuthenticated = localStorageService.isUserAuthenticated
        }
    }
    
    /**
     Calls Firebase authentication service to logout user
     */
    func logutUser(responseHandler: @escaping ResponseHandler<Bool>) {
        guard let authProvider = self.userProfile?.authenticationProvider else { return }
        switch authProvider {
        case .firebase: self.logoutFromFirebaseAuthSystem(responseHandler: responseHandler)
        case .apple: self.logoutUserFromAppleAuthSytem(responseHandler: responseHandler)
        case .google: self.logoutUserFromGoogleAuthSytem(responseHandler: responseHandler)
        }
    }
    
    /**
     Logs out user from Firebase auth system
     */
    private func logoutFromFirebaseAuthSystem(responseHandler: @escaping ResponseHandler<Bool>) {
        do {
            try Auth.auth().signOut()
            
            self.localStorageService.isUserAuthenticated = false
            self.localStorageService.userName = UserProfileModel.guestUserName
            responseHandler(true)
        } catch {
            responseHandler(false)
        }
    }
    
    /**
     Logs out user from Apple auth system
     */
    private func logoutUserFromAppleAuthSytem(responseHandler: @escaping ResponseHandler<Bool>) {
        self.localStorageService.isUserAuthenticated = false
        self.localStorageService.userId = ""
        self.localStorageService.userName = UserProfileModel.guestUserName
        responseHandler(true)
    }
    
    /**
     Logs out user from Google auth system
     */
    private func logoutUserFromGoogleAuthSytem(responseHandler: @escaping ResponseHandler<Bool>) {
        self.localStorageService.isUserAuthenticated = false
        self.localStorageService.userId = ""
        self.localStorageService.userName = UserProfileModel.guestUserName
        responseHandler(true)
    }
}

// MARK: ASAuthorizationControllerDelegate methods

extension UserAuthenticationViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as?  ASAuthorizationAppleIDCredential,
              let email = appleIDCredential.email,
              let user = appleIDCredential.fullName,
              let firstName = user.givenName,
              let familyName = user.familyName else {
            self.authenticationResponseHandler?(false)
            return
        }
        
        guard let profile = self.userProfile else {
            self.authenticationResponseHandler?(false)
            return
        }
        
        let userName = "\(firstName) \(familyName)"
        profile.id = appleIDCredential.user
        profile.name = userName
        profile.email = email
        
        self.localStorageService.isUserAuthenticated = true
        self.localStorageService.userAuthenticationProvider = .apple
        self.localStorageService.userId = profile.id
        self.localStorageService.userName = userName
        
        self.authenticationResponseHandler?(true)
    }
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        print(error.localizedDescription)
        self.authenticationResponseHandler?(false)
    }
}
