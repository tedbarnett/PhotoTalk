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
                    Text(NSLocalizedString("Log in to Photo Reviewer", comment: "User login view - title"))
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(Color.offwhite100)
                        .padding(.bottom, 20)
                    
                    FormTextField(
                        type: .email,
                        text: self.$email,
                        isInputValid: self.$isEmailInputValid,
                        height: 45
                    )
                    
                    VStack(alignment: .leading) {
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
                                    self.authenticationViewModel.sendEmailForPasswordReset { didSendEmail in
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
                    .padding(.bottom, 20)
                    
                    Button(action: {
                        guard self.areInputsValid() else {
                            return
                        }
                        
                        self.overlayContainerContext.shouldShowProgressIndicator = true
                        self.authenticationViewModel.authenticateUser(
                            with: self.email,
                            password: self.password) { isAuthenticationSuccessful in
                                self.overlayContainerContext.shouldShowProgressIndicator = false
                                guard isAuthenticationSuccessful else {
                                    self.overlayContainerContext.presentAlert(ofType: .userLoginFailed)
                                    self.isPasswordIncorrect = true
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
                        
                            Text(NSLocalizedString("Login", comment: "User login view - login button title"))
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
                }
                .padding(.all, 24)
                
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
