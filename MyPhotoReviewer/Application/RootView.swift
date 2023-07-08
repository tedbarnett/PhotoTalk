//
//  RootView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 04/05/23.
//

import SwiftUI

/**
 RootView works as the primary view for the application.
 It sets application environment variables, checks user authentication state and navigates to the respective view.
 */
struct RootView: View {
    
    // MARK: Private properties
    
    @EnvironmentObject private var appContext: AppContext
    @EnvironmentObject private var userProfile: UserProfileModel
    @StateObject private var overlayContainerContext = OverlayContainerContext()
    
    @State private var isValidatingUserAuthentication = true
    
    // MARK: - User interface
    
    var body: some View {
        ZStack {
            ZStack {
                if self.userProfile.isAuthenticated {
                    // Main view that provides user option to select image source, preview image
                    // add image details like location, audio clip, etc
                    HomeView()
                } else {
                    // User login view presents user authentication view
                    UserLoginView()
                }
            }
            .opacity(self.isValidatingUserAuthentication ? 0 : 1)
            
            // Overlay (progress indicator, alert views, etc) container view
            OverlayContainerView()
        }
        .environmentObject(self.overlayContainerContext)
        .onAppear {
            self.initializeUserProfile()
            self.validateUserAuthenticationStateIfNeeded()
        }
    }
    
    // MARK: Private methods
    
    /**
     Intializes user profile based on user profile information saved in local storage
     */
    private func initializeUserProfile() {
        let localStorageService = LocalStorageService()
        self.userProfile.didAllowPhotoAccess = localStorageService.didUserAllowPhotoAccess
        let mediaSource = MediaSource(rawValue: localStorageService.userSelectedMediaSource)
        self.userProfile.mediaSource = mediaSource
    }
    
    /**
     If the user is already authenticated, it checks if the user authentication state is still valid for application access.
     If user authentication is invalidated, it logs out user from the app and presents the login screen.
     */
    private func validateUserAuthenticationStateIfNeeded() {
        self.isValidatingUserAuthentication = true
        self.overlayContainerContext.shouldShowProgressIndicator = true
        let userAuthenticationViewModel = UserAuthenticationViewModel()
        userAuthenticationViewModel.userProfile = self.userProfile
        userAuthenticationViewModel.validateUserAuthenticationStateIfNeeded {
            DispatchQueue.main.async {
                self.overlayContainerContext.shouldShowProgressIndicator = false
                self.isValidatingUserAuthentication = false
            }
        }
    }
}
