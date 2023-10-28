//
//  MyPhotoReviewerApp.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 22/04/23.
//

import SwiftUI

@main
struct MyPhotoReviewerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var appContext = AppContext()
    @StateObject private var userProfile = UserProfileModel.defaultUserProfile
    @StateObject private var overlayContainerContext = OverlayContainerContext()
    
    init() {
        AppleMapsService.sharedInstance.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(self.appContext)
                .environmentObject(self.userProfile)
                .environmentObject(self.overlayContainerContext)
        }
    }
}
