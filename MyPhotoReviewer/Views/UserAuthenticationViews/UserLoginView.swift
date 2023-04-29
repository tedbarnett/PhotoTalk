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
                Color.black600
                    .ignoresSafeArea()
                
                UserAuthenticationBackgroundArt()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 40)
                
                VStack(alignment: .center, spacing: 24) {
                    Text("Login with your email and password")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.orange200)
                        .padding(.bottom, 20)
                    
                    FormTextField(
                        text: self.$email,
                        title: "Email",
                        backgroundColor: Color.offwhite100,
                        height: 45
                    )
                    
                    FormTextField(
                        text: self.$password,
                        title: "Password",
                        isSecuredField: true,
                        backgroundColor: Color.offwhite100,
                        height: 45
                    )
                    .padding(.bottom, 20)
                    
                    Button(action: {
                        // Integrate Firebase user login API
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange200)
                                .frame(height: 45)
                            
                            Text("Login")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.black)
                        }
                    }
                    
                    HStack(alignment: .center) {
                        Text("New to Photo Reviewer?")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.white)
                        
                        Text("Register here")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.orange200)
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
