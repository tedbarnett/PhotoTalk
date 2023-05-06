//
//  PhotoReviewerView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 22/04/23.
//

import SwiftUI

struct PhotoReviewerView: View {
    @EnvironmentObject private var appContext: AppContext
    @EnvironmentObject private var userProfile: UserProfileModel
    
    var body: some View {
        ZStack {
            
            // Background
            Color.black900
                .ignoresSafeArea()
            
            // Content View
            VStack {
                HStack {
                    
                    // Welcome text
                    HStack(alignment: .center, spacing: 3) {
                        Text(NSLocalizedString("Welcome back", comment: "Photo reviewer view - welcome title"))
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color.offwhite100)
                        Text("\(self.userProfile.name)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.blue500)
                    }
                    Spacer()
                    
                    // Logout button
                    Button(action: {
                        
                    }) {
                        Image(systemName: "power.circle.fill")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .tint(Color.blue500)
                            .frame(width: 30, height: 30)
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
            }
            .padding(.top, 20)
        }
    }
}
