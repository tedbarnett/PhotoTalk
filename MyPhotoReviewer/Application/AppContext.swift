//
//  AppContext.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 04/05/23.
//

import Foundation

/**
 AppContext encapsulates cruical application state data that may be required at different application module.
 Such as user authentication state, current active view, etc.
 */
class AppContext: ObservableObject {
    @Published var isUserAuthenticated = false
    
    var currentEnvironment: Environment {
        return EnvironmentManager.shared.currentEnvironment
    }
}

/**
 OverlayContainerContext contains information about the overlay views and their properties like
 progress indicator view, alert view, etc
 */
class OverlayContainerContext: ObservableObject {
    @Published var shouldShowProgressIndicator = false
    
    @Published var shouldShowAlert = false
    @Published var alertType: AlertType = .userRegistrationSuccessfull
    @Published var primaryActionButtonHandler: VoidResponseHandler?
    @Published var dismissActionButtonHandler: VoidResponseHandler?
    
    /// Sends notification for presenting Alert view
    func presentAlert(
        ofType: AlertType,
        primaryActionButtonHandler: VoidResponseHandler? = nil,
        dismissActionButtonHandler: VoidResponseHandler? = nil
    ) {
        DispatchQueue.main.async {
            self.shouldShowAlert = true
            self.alertType = ofType
            self.primaryActionButtonHandler = primaryActionButtonHandler
            self.dismissActionButtonHandler = dismissActionButtonHandler
        }
    }
}
