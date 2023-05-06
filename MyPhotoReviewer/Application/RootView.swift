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
    
    // MARK: - User interface
    
    var body: some View {
        ZStack {
            if self.userProfile.isAuthenticated {
                // Main view that provides user option to select image source, preview image
                // add image details like location, audio clip, etc
                PhotoReviewerView()
            } else {
                // User login view presents user authentication view
                UserLoginView()
            }
            
            // Overlay (progress indicator, alert views, etc) container view
            OverlayContainerView()
        }
        .environmentObject(self.overlayContainerContext)
        .onAppear {
            self.initializeApp()
        }
    }
    
    // MARK: Private methods
    
    /**
     This method sets initial settings and configuration for the app
     */
    private func initializeApp() {
        print("App is running with \(self.appContext.currentEnvironment.name.uppercased()) environment")
        
        let localStorageService = LocalStorageService()
        self.userProfile.isAuthenticated = localStorageService.isUserAuthenticated
        self.userProfile.name = localStorageService.userName
    }
}
