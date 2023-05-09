//
//  PhotoReviewerView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 22/04/23.
//

import SwiftUI

/**
 PhotoReviewerView is the main view shown to the user after successful user authentication.
 It presents UI/UX for user to select source of images (Google drive, Apple iCloud, etc), presents
 list of images and their preview.
 
 It also provides the tools for adding details to the image like location,date, time, audio annotation, etc.
 */
struct PhotoReviewerView: View {
    
    // MARK: Private properties
    
    @EnvironmentObject private var appContext: AppContext
    @EnvironmentObject private var userProfile: UserProfileModel
    @EnvironmentObject private var overlayContainerContext: OverlayContainerContext
    
    @StateObject private var authenticationViewModel = UserAuthenticationViewModel()
    
    // MARK: User interface
    
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
                        self.overlayContainerContext.shouldShowProgressIndicator = true
                        self.authenticationViewModel.logutUser { didLogoutSuccessfully in
                            self.overlayContainerContext.shouldShowProgressIndicator = false
                            guard didLogoutSuccessfully else {
                                return 
                            }
                            self.userProfile.isAuthenticated = false
                        }
                    }) {
                        Image(systemName: "power.circle.fill")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .tint(Color.blue500)
                            .frame(width: 30, height: 30)
                    }
                }
                .padding(.horizontal, UIDevice.isIpad ? 40 : 16)
                
                Spacer()
            }
            .padding(.top, UIDevice.isIpad ? 40 : 20)
        }
        .onAppear {
            self.authenticationViewModel.userProfile = self.userProfile
        }
    }
}
