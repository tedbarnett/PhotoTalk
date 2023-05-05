//
//  RootView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 04/05/23.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appContext: AppContext
    @EnvironmentObject private var userProfile: UserProfileModel

    @StateObject private var overlayContainerContext = OverlayContainerContext()
    
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
    }
}
