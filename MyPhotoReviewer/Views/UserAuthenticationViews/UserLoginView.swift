//
//  UserLoginView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 28/04/23.
//

import SwiftUI

struct UserLoginView: View {
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Please enter your email and password")) {
                    TextField("Email", text: $email)
                    TextField("Password", text: $password)
                }
                Section {
                    Button(action: {
                        // Integrate Firebase user login API
                    }) {
                        Text("Login")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("User Login")
        }
    }
}
