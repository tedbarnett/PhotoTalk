//
//  UserLoginView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 28/04/23.
//

import SwiftUI

struct UserLoginView: View {
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    @State private var shouldShowUserRegistrationView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black900
                    .ignoresSafeArea()
                
                UserAuthenticationBackgroundArt()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 40)
                
                VStack(alignment: .center, spacing: 24) {
                    Text("Log in to Photo Reviewer")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(Color.offwhite100)
                        .padding(.bottom, 20)
                    
                    FormTextField(
                        type: .email,
                        text: self.$email,
                        backgroundColor: Color.offwhite100,
                        height: 45
                    )
                    
                    VStack(alignment: .leading) {
                        FormTextField(
                            type: .password,
                            text: self.$password,
                            isSecuredField: true,
                            backgroundColor: Color.offwhite100,
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
        }
        .navigationBarHidden(true)
    }
}
