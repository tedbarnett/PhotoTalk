//
//  UserRegistrationView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 28/04/23.
//

import SwiftUI

struct UserRegistrationView: View {
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    
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
                .padding(.top, 60)
                .padding(.leading, 24)
                
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            
            // User registration form
            VStack(alignment: .center, spacing: 24) {
                Text("Fill in these details to register")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.orange200)
                    .padding(.bottom, 20)
                
                FormTextField(
                    text: self.$name,
                    title: "Name",
                    backgroundColor: Color.offwhite100,
                    height: 45
                )
                
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

                        Text("Register")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.black)
                    }
                }
            }
            .padding(.all, 24)
        }
    }
}
