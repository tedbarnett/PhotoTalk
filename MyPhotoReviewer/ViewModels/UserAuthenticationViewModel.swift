//
//  UserAuthenticationViewModel.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 06/05/23.
//

import Foundation
import Firebase
import FirebaseAuth
import GoogleSignIn
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
                profile.authenticationServiceProvider = .firebase
                
                self.localStorageService.isUserAuthenticated = true
                self.localStorageService.authenticationServiceProvider = .firebase
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
    
    func signInWithGoogle(responseHandler: @escaping ResponseHandler<Bool>) {
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController,
              let firebaseApp = FirebaseApp.app(),
              let clientID = firebaseApp.options.clientID else {
            DispatchQueue.main.async {
                responseHandler(false)
            }
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            guard error == nil,
                  let strongSelf = self,
                  let authResult = result,
                  let userId = authResult.user.userID,
                  let uProfile = authResult.user.profile else {
                DispatchQueue.main.async {
                    responseHandler(false)
                }
                return
            }
            
            guard let profile = strongSelf.userProfile else {
                DispatchQueue.main.async {
                    responseHandler(false)
                }
                return
            }
            
            profile.id = userId
            profile.email = uProfile.email
            profile.name = uProfile.name
            profile.authenticationServiceProvider = .google
            
            strongSelf.localStorageService.isUserAuthenticated = true
            strongSelf.localStorageService.authenticationServiceProvider = .google
            strongSelf.localStorageService.userName = profile.name
            strongSelf.localStorageService.userId = profile.id
            
            DispatchQueue.main.async {
                responseHandler(true)
            }
        }
    }
    
    /**
     This method is called before trying to download photos from users google drive.
     It presents Google authentication prompt to the user and returns the authentication token on
     successful authentication.
     */
    func authenticateUserWithGoogle(responseHandler: @escaping ResponseHandler<String?>) {
        guard let googleClientId = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
              let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {
            responseHandler(nil)
            return
        }
        
        let config = GIDConfiguration(clientID: googleClientId)
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingViewController,
            hint: nil,
            additionalScopes: ["https://www.googleapis.com/auth/drive.readonly"]) { [weak self] result, error in
                guard error == nil,
                      let strongSelf = self,
                      let authResult = result else {
                    responseHandler(nil)
                    return
                }
                let accessToken = authResult.user.accessToken
                let refreshToken = authResult.user.refreshToken
                responseHandler(accessToken.tokenString)
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
     This method checks if the logged in user authentication state is still valid.
     If the authentication state is invalidated/expired by the authentication service provider,
     it logs user out of the system and prsents the login prompt
     */
    func validateUserAuthenticationStateIfNeeded() {
        guard self.localStorageService.isUserAuthenticated,
              let userProfile = self.userProfile else { return }
        
        userProfile.authenticationServiceProvider = self.localStorageService.authenticationServiceProvider
        userProfile.id = self.localStorageService.userId
        userProfile.name = self.localStorageService.userName
        
        if self.localStorageService.authenticationServiceProvider == .apple {
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            appleIDProvider.getCredentialState(forUserID: self.localStorageService.userId) { credentialState, error in
                switch credentialState {
                case .authorized:
                    // The Apple ID credential is valid.
                    DispatchQueue.main.async {
                        userProfile.email = self.localStorageService.userEmail
                        self.localStorageService.isUserAuthenticated = true
                        userProfile.isAuthenticated = true
                    }
                    break
                case .revoked, .notFound:
                    // The Apple ID credential is either revoked or was not found, so show the sign-in UI.
                    DispatchQueue.main.async {
                        userProfile.isAuthenticated = false
                        self.localStorageService.isUserAuthenticated = false
                    }
                default:
                    break
                }
            }
        } else if self.localStorageService.authenticationServiceProvider == .firebase {
            let user = Auth.auth().currentUser
            if let user = user, let email = user.email {
                userProfile.email = email
                userProfile.isAuthenticated = self.localStorageService.isUserAuthenticated
            }
        } else {
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                userProfile.email = self.localStorageService.userEmail
                userProfile.isAuthenticated = error == nil
                self.localStorageService.isUserAuthenticated = error == nil
            }
        }
    }
    
    /**
     Calls Firebase authentication service to logout user
     */
    func logutUser(responseHandler: @escaping ResponseHandler<Bool>) {
        guard let authProvider = self.userProfile?.authenticationServiceProvider else { return }
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
            self.localStorageService.userId = ""
            self.localStorageService.userName = UserProfileModel.guestUserName
            self.localStorageService.userEmail = UserProfileModel.defaultEmail
            self.localStorageService.isUserAuthenticated = false
            responseHandler(true)
        } catch {
            responseHandler(false)
        }
    }
    
    /**
     Logs out user from Apple auth system
     */
    private func logoutUserFromAppleAuthSytem(responseHandler: @escaping ResponseHandler<Bool>) {
        self.localStorageService.userId = ""
        self.localStorageService.userName = UserProfileModel.guestUserName
        self.localStorageService.userEmail = UserProfileModel.defaultEmail
        self.localStorageService.isUserAuthenticated = false
        responseHandler(true)
    }
    
    /**
     Logs out user from Google auth system
     */
    private func logoutUserFromGoogleAuthSytem(responseHandler: @escaping ResponseHandler<Bool>) {
        GIDSignIn.sharedInstance.signOut()
        self.localStorageService.userId = ""
        self.localStorageService.userName = UserProfileModel.guestUserName
        self.localStorageService.userEmail = UserProfileModel.defaultEmail
        self.localStorageService.isUserAuthenticated = false
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
        
        if let email = appleIDCredential.email {
            profile.email = email
            self.localStorageService.userEmail = email
        }
        
        profile.authenticationServiceProvider = .google
        
        self.localStorageService.isUserAuthenticated = true
        self.localStorageService.authenticationServiceProvider = .apple
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
