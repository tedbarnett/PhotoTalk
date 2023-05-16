//
//  UserLoginView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 28/04/23.
//

import SwiftUI
import FirebaseAuth

/**
 User login view preents input form for user login with email and password.
 It uses UserAuthenticationViewModel for managing its data, state and api calls.
 */
struct UserLoginView: View {
    
    // MARK: Private properties
    
    @EnvironmentObject private var appContext: AppContext
    @EnvironmentObject private var overlayContainerContext: OverlayContainerContext
    @EnvironmentObject private var userProfile: UserProfileModel
    
    @State private var email: String = ""
    @State private var isEmailInputValid: Bool = true
    
    @State private var password: String = ""
    @State private var isPasswordInputValid: Bool = true
    @State private var isPasswordIncorrect: Bool = false
    
    @State private var shouldShowUserRegistrationView = false
    
    @StateObject private var authenticationViewModel = UserAuthenticationViewModel()
    
    // MARK: user inteface
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black900
                    .ignoresSafeArea()
                
                UserAuthenticationBackgroundArt()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 40)
                
                VStack(alignment: .center, spacing: 16) {
                    Text(NSLocalizedString("Sign in to Photo Reviewer", comment: "User login view - title"))
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(Color.offwhite100)
                        .padding(.bottom, 20)
                    
                    FormTextField(
                        type: .email,
                        text: self.$email,
                        isInputValid: self.$isEmailInputValid,
                        height: 45
                    )
                    
                    VStack(alignment: .leading, spacing: 0) {
                        FormTextField(
                            type: .password,
                            text: self.$password,
                            isInputValid: self.$isPasswordInputValid,
                            isSecuredField: true,
                            height: 45
                        )
                        
                        HStack(alignment: .center) {
                            Text(NSLocalizedString("Forgot password?", comment: "User login view - forgot password title"))
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color.offwhite100)
                            
                            Text(NSLocalizedString("Reset here", comment: "User login view - forgot password button title"))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.blue500)
                                .onTapGesture {
                                    self.overlayContainerContext.shouldShowProgressIndicator = true
                                    self.authenticationViewModel.sendEmailForPasswordReset(userEmail: self.email) { didSendEmail in
                                        self.overlayContainerContext.shouldShowProgressIndicator = false
                                        guard didSendEmail else {
                                            self.overlayContainerContext.presentAlert(ofType: .emailFailedForPasswordReset)
                                            return
                                        }
                                        self.overlayContainerContext.presentAlert(ofType: .emailSentForPasswordReset)
                                    }
                                }
                            Spacer()
                        }
                        .opacity(self.isPasswordIncorrect ? 1 : 0)
                    }
                    .padding(.bottom, 10)
                    
                    Button(action: {
                        guard self.areInputsValid() else {
                            return
                        }
                        
                        self.overlayContainerContext.shouldShowProgressIndicator = true
                        self.authenticationViewModel.authenticateUser(
                            with: self.email,
                            password: self.password) { alertType in
                                self.overlayContainerContext.shouldShowProgressIndicator = false
                                
                                guard alertType == .userLoginSuccessfull else {
                                    self.overlayContainerContext.presentAlert(ofType: alertType)
                                    self.isPasswordIncorrect = alertType == .userLoginFailed
                                    return
                                }
                                
                                self.isPasswordIncorrect = false
                                self.userProfile.isAuthenticated = true
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue500)
                                .frame(height: 45)
                        
                            Text(NSLocalizedString("Sign in", comment: "User login view - Sign in button title"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.white)
                        }
                    }
                    .disabled(self.email.isEmpty || self.password.isEmpty)
                    .opacity(self.email.isEmpty || self.password.isEmpty ? 0.5 : 1)
                    
                    HStack(alignment: .center) {
                        Text(NSLocalizedString("New to Photo Reviewer?", comment: "User login view - registration title"))
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.offwhite100)
                        
                        Text(NSLocalizedString("Register here", comment: "User login view - registration button title"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.blue500)
                            .onTapGesture {
                                self.shouldShowUserRegistrationView = true
                            }
                    }
                    
                    VStack(alignment: .center, spacing: 16) {
                        Button(
                            action: {
                                self.authenticationViewModel.signInWithApple { didSignin in
                                    guard didSignin else {
                                        return
                                    }
                                    self.userProfile.isAuthenticated = true
                                }
                            },
                            label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.black)
                                        .frame(height: 45)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.offwhite100, lineWidth: 1)
                                                .frame(height: 45)
                                        }
                                
                                    HStack(alignment: .center, spacing: 12) {
                                        Image(systemName: "apple.logo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                            .tint(Color.white)
                                        
                                        Text(NSLocalizedString("Sign in with Apple", comment: "User login view - Apple signin button title"))
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color.white)
                                    }
                                }
                            }
                        )
                        
                        Button(
                            action: {
                                self.authenticationViewModel.signInWithGoogle()
                            },
                            label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.black)
                                        .frame(height: 45)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.offwhite100, lineWidth: 1)
                                                .frame(height: 45)
                                        }
                                
                                    
                                    HStack(alignment: .center, spacing: 12) {
                                        Image("googleIcon")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                        
                                        Text(NSLocalizedString("Sign in with Google", comment: "User login view - Google signin button title"))
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color.white)
                                    }
                                }
                            }
                        )
                    }
                    .padding(.top, 40)
                }
                .frame(width: UIDevice.isIpad ? UIScreen.main.bounds.width * 0.4 : UIScreen.main.bounds.width - 48)
                
                // Link to user registration view
                NavigationLink(
                    destination:
                        UserRegistrationView()
                        .navigationBarHidden(true)
                    ,
                    isActive: self.$shouldShowUserRegistrationView
                ) { EmptyView() }
            }
        }
        .navigationBarHidden(true)
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            self.authenticationViewModel.userProfile = self.userProfile
        }
    }
    
    // MARK: Private methods
    
    private func areInputsValid() -> Bool {
        self.isEmailInputValid = !self.email.isEmpty && self.email.contains("@") && self.email.contains(".")
        self.isPasswordInputValid = !self.password.isEmpty && self.password.count >= 8
        return self.isEmailInputValid && self.isPasswordInputValid
    }
}
