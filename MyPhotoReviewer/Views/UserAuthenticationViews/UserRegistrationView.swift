//
//  UserRegistrationView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 28/04/23.
//

import SwiftUI
import FirebaseAuth

/**
 User registration view preents input form for user registration with name, email and password.
 It uses UserAuthenticationViewModel for managing its data, state and api calls.
 */
struct UserRegistrationView: View {
    
    // MARK: Private properties
    
    @SwiftUI.Environment(\.presentationMode) private var presentationMode
    
    @EnvironmentObject private var appContext: AppContext
    @EnvironmentObject private var overlayContainerContext: OverlayContainerContext
    @EnvironmentObject private var userProfile: UserProfileModel
    
    @State private var name = ""
    @State private var isNameInputValid: Bool = true
    @State private var email = ""
    @State private var isEmailInputValid: Bool = true
    @State private var password = ""
    @State private var isPasswordInputValid: Bool = true
    
    @StateObject private var authenticationViewModel = UserAuthenticationViewModel()
    
    // MARK: - User interface
    
    var body: some View {
        ZStack {
            
            // Background color and art
            Color.black600
                .ignoresSafeArea()
            UserAuthenticationBackgroundArt()
                .padding(.horizontal, 16)
                .padding(.vertical, 40)
            
            // Back button and its container
            VStack {
                HStack {
                    Button(
                        action: {
                            self.presentationMode.wrappedValue.dismiss()
                        },
                        label: {
                            ZStack {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 40, height: 40)
                                Image("leftArrowIcon")
                                    .renderingMode(.template)
                                    
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 9, height: 16)
                                    .tint(.white)
                            }
                        }
                    )
                    Spacer()
                }
                .padding(.top, 50)
                
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            
            // User registration form
            VStack(alignment: .center, spacing: 16) {
                Text(NSLocalizedString("Get your free account", comment: "User registration view - title"))
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(Color.offwhite100)
                    .padding(.bottom, 20)
                
                FormTextField(
                    type: .name,
                    text: self.$name,
                    isInputValid: self.$isNameInputValid,
                    height: 45
                )
                
                FormTextField(
                    type: .email,
                    text: self.$email,
                    isInputValid: self.$isEmailInputValid,
                    height: 45
                )
                
                FormTextField(
                    type: .password,
                    text: self.$password,
                    isInputValid: self.$isPasswordInputValid,
                    isSecuredField: true,
                    height: 45
                )
                .padding(.bottom, 20)
                
                Button(action: {
                    guard self.areInputsValid() else { return }
                    self.overlayContainerContext.shouldShowProgressIndicator = true
                    self.authenticationViewModel.registerUserWithFirebase(
                        with: self.name,
                        email: self.email,
                        password: self.password) { didRegisterUserSuccessfully in
                            self.overlayContainerContext.shouldShowProgressIndicator = false
                            guard didRegisterUserSuccessfully else {
                                self.overlayContainerContext.presentAlert(ofType: .userRegistrationFailed)
                                return
                            }
                            self.overlayContainerContext.presentAlert(
                                ofType: .userRegistrationSuccessfull,
                                primaryActionButtonHandler: {
                                    self.presentationMode.wrappedValue.dismiss()
                                }
                            )
                        }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue500)
                            .frame(height: 45)

                        Text(NSLocalizedString("Register", comment: "User registration view - register button title"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.white)
                    }
                }
                .disabled(self.name.isEmpty || self.email.isEmpty || self.password.isEmpty)
                .opacity(self.name.isEmpty || self.email.isEmpty || self.password.isEmpty ? 0.5 : 1)
            }
            .frame(width: UIDevice.isIpad ? UIScreen.main.bounds.width * 0.4 : UIScreen.main.bounds.width - 48)
        }
    }
    
    // MARK: Private methods
    
    private func areInputsValid() -> Bool {
        self.isNameInputValid = !self.name.isEmpty
        self.isEmailInputValid = !self.email.isEmpty && self.email.contains("@") && self.email.contains(".")
        self.isPasswordInputValid = !self.password.isEmpty && self.password.count >= 8
        return self.isNameInputValid && self.isEmailInputValid && self.isPasswordInputValid
    }
}
