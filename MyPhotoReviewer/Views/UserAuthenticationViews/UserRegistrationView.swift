//
//  UserRegistrationView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 28/04/23.
//

import SwiftUI
import FirebaseAuth

struct UserRegistrationView: View {
    
    @EnvironmentObject private var appContext: AppContext
    @EnvironmentObject private var overlayContainerContext: OverlayContainerContext
    @EnvironmentObject private var userProfile: UserProfileModel
    
    @State private var name = ""
    @State private var isNameInputValid: Bool = true
    @State private var email = ""
    @State private var isEmailInputValid: Bool = true
    @State private var password = ""
    @State private var isPasswordInputValid: Bool = true
    
    @SwiftUI.Environment(\.presentationMode) private var presentationMode
    
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
                Text("Get your free account")
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
                    Auth.auth().createUser(withEmail: self.email, password: self.password) { authResult, error in
                        self.overlayContainerContext.shouldShowProgressIndicator = false
                        guard let result = authResult,
                              let userEmail = result.user.email,
                              error == nil else {
                            print("Error, couldn't register user")
                            self.overlayContainerContext.presentAlert(ofType: .userRegistrationFailed)
                            return
                        }
                        print("Successfully created a new user account with email: \(userEmail)")

                        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                        changeRequest?.displayName = self.name
                        changeRequest?.commitChanges { error in
                            self.overlayContainerContext.presentAlert(ofType: .userRegistrationSuccessfull)
                            guard error == nil else { return }
                            print("Successfully updated useer name to \(self.name)")
                        }
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue500)
                            .frame(height: 45)

                        Text("Register")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.white)
                    }
                }
                .disabled(self.name.isEmpty || self.email.isEmpty || self.password.isEmpty)
                .opacity(self.name.isEmpty || self.email.isEmpty || self.password.isEmpty ? 0.5 : 1)
            }
            .padding(.all, 24)
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
