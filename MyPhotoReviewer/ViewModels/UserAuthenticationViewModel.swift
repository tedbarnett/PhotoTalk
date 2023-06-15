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
import CryptoKit

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
    
    // MARK: Private properties
    
    private var currentNonce: String?
    
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
                
                self.localStorageService.userId = profile.id
                self.localStorageService.userName = profile.name
                self.localStorageService.isUserAuthenticated = true
                self.localStorageService.authenticationServiceProvider = .firebase
                
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
        
        let nonce = self.randomNonceString()
        self.currentNonce = nonce
        request.nonce = self.sha256(nonce)
        
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
                  let idToken = authResult.user.idToken,
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
            
            let acessToken = authResult.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString,
                                                             accessToken: acessToken)
            Auth.auth().signIn(with: credential) { firResult, error in
                guard error == nil,
                      let firbaseAuthResult = firResult else {
                    responseHandler(false)
                    return
                }
                
                profile.id = firbaseAuthResult.user.uid
                profile.email = uProfile.email
                profile.name = uProfile.name
                profile.authenticationServiceProvider = .google
                
                strongSelf.localStorageService.userEmail = profile.email ?? ""
                strongSelf.localStorageService.userName = profile.name
                strongSelf.localStorageService.userId = profile.id
                strongSelf.localStorageService.googleIdToken = idToken.tokenString
                strongSelf.localStorageService.googleAccessToken = acessToken
                strongSelf.localStorageService.isUserAuthenticated = true
                strongSelf.localStorageService.authenticationServiceProvider = .google
                
                DispatchQueue.main.async {
                    responseHandler(true)
                }
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
            additionalScopes: ["https://www.googleapis.com/auth/drive.readonly"]) { result, error in
                guard error == nil,
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
     Sends user email for resetting password, if the user was authenticated with Firebase authentication service
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
              let userProfile = self.userProfile else {
            return
        }
        
        userProfile.authenticationServiceProvider = self.localStorageService.authenticationServiceProvider
        userProfile.id = self.localStorageService.userId
        userProfile.name = self.localStorageService.userName
        
        if self.localStorageService.authenticationServiceProvider == .apple {
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            appleIDProvider.getCredentialState(forUserID: self.localStorageService.appleUserId) { credentialState, error in
                switch credentialState {
                case .authorized:
                    guard error == nil, let user = Auth.auth().currentUser else {
                        return
                    }
                    
                    userProfile.email = self.localStorageService.userEmail
                    self.localStorageService.isUserAuthenticated = true
                    userProfile.isAuthenticated = true
                    
                    // Uncomment below code, if the user needs to be re-authenticated with Firebase
//                    let idToken = self.localStorageService.appleIdToken
//                    let nonce = self.localStorageService.nonceUserdForAppleAuthentication
//                    let credential = OAuthProvider.credential(
//                        withProviderID: "apple.com",
//                        idToken: idToken,
//                        rawNonce: nonce)
//
//                    user.reauthenticate(with: credential) { authResult, error in
//                        guard error != nil else { return }
//                        userProfile.email = self.localStorageService.userEmail
//                        self.localStorageService.isUserAuthenticated = true
//                        userProfile.isAuthenticated = true
//                    }
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
                guard error == nil, let user = Auth.auth().currentUser else {
                    return
                }
                let idToken = self.localStorageService.googleIdToken
                let acessToken = self.localStorageService.googleAccessToken
                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                                 accessToken: acessToken)
                user.reauthenticate(with: credential) { authResult, error in
                    guard error == nil else { return }
                    userProfile.email = self.localStorageService.userEmail
                    userProfile.isAuthenticated = error == nil
                    self.localStorageService.isUserAuthenticated = error == nil
                }
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
            self.localStorageService.reset()
            responseHandler(true)
        } catch {
            responseHandler(false)
        }
    }
    
    /**
     Logs out user from Apple auth system
     */
    private func logoutUserFromAppleAuthSytem(responseHandler: @escaping ResponseHandler<Bool>) {
        let userName = self.localStorageService.userName
        let userEmail = self.localStorageService.userEmail
        
        self.localStorageService.reset()
        // Apple auth system doesn't return user name and email on second login attempts,
        // therefore saving the user name and email for later user
        self.localStorageService.userName = userName
        self.localStorageService.userEmail = userEmail
        
        responseHandler(true)
    }
    
    /**
     Logs out user from Google auth system
     */
    private func logoutUserFromGoogleAuthSytem(responseHandler: @escaping ResponseHandler<Bool>) {
        GIDSignIn.sharedInstance.signOut()
        self.localStorageService.reset()
        responseHandler(true)
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
      }.joined()

      return hashString
    }
}

// MARK: ASAuthorizationControllerDelegate methods

extension UserAuthenticationViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as?  ASAuthorizationAppleIDCredential,
              let user = appleIDCredential.fullName else {
            self.authenticationResponseHandler?(false)
            return
        }
        
        guard let profile = self.userProfile else {
            self.authenticationResponseHandler?(false)
            return
        }
        
        guard let nonce = self.currentNonce else {
            print("Invalid state: A login callback was received, but no login request was sent.")
            self.authenticationResponseHandler?(false)
            return
        }
        
        guard let appleIDToken = appleIDCredential.identityToken else {
            print("Unable to fetch identity token")
            self.authenticationResponseHandler?(false)
            return
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
            self.authenticationResponseHandler?(false)
            return
        }
        
        // Initialize a Firebase credential, including the user's full name.
        let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                       rawNonce: nonce,
                                                       fullName: user)
        
        // Sign in with Firebase.
        Auth.auth().signIn(with: credential) { authResult, error in
            guard error == nil,
                  let result = authResult else {
                self.authenticationResponseHandler?(false)
                return
            }
            
            /// Apple id may contain `.` charachter which isn't supported by Firebase database ad a node ID.
            /// Therefore, replacing `.` with `_`
            profile.id = result.user.uid
            
            if let firstName = user.givenName,
               let familyName = user.familyName {
                let userName = "\(firstName) \(familyName)"
                profile.name = userName
                self.localStorageService.userName = userName
            } else {
                let name = self.localStorageService.userName
                profile.name = name
            }
            
            if let email = appleIDCredential.email {
                profile.email = email
                self.localStorageService.userEmail = email
            }
            
            profile.authenticationServiceProvider = .apple
            self.localStorageService.userId = profile.id
            let appleUserId = appleIDCredential.user
            self.localStorageService.appleUserId = appleUserId
            self.localStorageService.appleIdToken = idTokenString
            self.localStorageService.isUserAuthenticated = true
            self.localStorageService.nonceUserdForAppleAuthentication = nonce
            self.localStorageService.authenticationServiceProvider = profile.authenticationServiceProvider
            
            profile.isAuthenticated = true
            self.authenticationResponseHandler?(true)
        }
    }
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        print(error.localizedDescription)
        self.authenticationResponseHandler?(false)
    }
}
