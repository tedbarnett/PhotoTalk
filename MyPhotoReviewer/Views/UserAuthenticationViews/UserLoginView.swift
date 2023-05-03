//
//  UserLoginView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 28/04/23.
//

import SwiftUI

struct UserLoginView: View {
    
    @State private var email: String = ""
    @State private var isEmailInputValid: Bool = false
    
    @State private var password: String = ""
    @State private var isPasswordInputValid: Bool = false
    @State private var isPasswordIncorrect: Bool = false
    
    @State private var isLoginEnabled: Bool = false
    @State private var shouldShowUserRegistrationView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black900
                    .ignoresSafeArea()
                
                UserAuthenticationBackgroundArt()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 40)
                
                VStack(alignment: .center, spacing: 16) {
                    Text("Log in to Photo Reviewer")
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
                            Text("Forgot password?")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color.offwhite100)
                            
                            Text("Reset here")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.blue500)
                                .onTapGesture {
                                    self.shouldShowUserRegistrationView = true
                                }
                            Spacer()
                        }
                        .opacity(self.isPasswordIncorrect ? 1 : 0)
                    }
                    .padding(.bottom, 20)
                    
                    Button(action: {
                        // Integrate Firebase user login API
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue500)
                                .frame(height: 45)
                        
                            Text("Login")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.white)
                        }
                    }
                    .disabled(!self.isLoginEnabled)
                    .opacity(self.isLoginEnabled ? 1 : 0.5)
                    
                    HStack(alignment: .center) {
                        Text("New to Photo Reviewer?")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.offwhite100)
                        
                        Text("Register here")
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
            .onAppear {
                self.isLoginEnabled = false
            }
            .onChange(of: self.isEmailInputValid) { isValid in
                self.isLoginEnabled = isValid && self.isPasswordInputValid && !self.password.isEmpty
            }
            .onChange(of: self.isPasswordInputValid) { isValid in
                self.isLoginEnabled = isValid && self.isEmailInputValid && !self.email.isEmpty
            }
        }
        .navigationBarHidden(true)
    }
}
