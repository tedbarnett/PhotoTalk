//
//  AlertView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 04/05/23.
//

import SwiftUI

/// Common alert view to show response messeges for a user action like claiming trustpoints,
/// bookmarking products, deleting bookmarks, etc
struct AlertView: View {

    // MARK: Public properties
    var alertType: AlertType
    var actionButtonHandler: VoidResponseHandler?
    var dismissButtonHandler: VoidResponseHandler?

    // MARK: Private properties

    @State private var hasSmallScreen = false

    // MARK: User interface
    var body: some View {
        ZStack {

            // Background
            Color.black.opacity(0.25)
                .ignoresSafeArea()

            ZStack {
                // Content background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.offwhite100)

                // Content views
                VStack(alignment: .center, spacing: 12) {
                    if self.alertType.shouldShowCloseButton {
                        HStack {
                            Spacer()
                                Button(
                                    action: {
                                        self.dismissButtonHandler?()
                                    },
                                    label: {
                                        Image("closeButtonIcon")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 28, height: 28)
                                    }
                            )
                        }
                        .padding(.trailing, 15)
                        .padding(.top, 15)
                    }

                    if let icon = self.alertType.icon {
                        Image(icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .padding(.top, 40)
                    }

                    if let titleText = self.alertType.title {
                        Text(titleText)
                            .font(.system(size: 20, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.black600)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                    }

                    if let descriptionText = self.alertType.description {
                        Text(descriptionText)
                            .font(.system(size: 16, weight: .regular))
                            .multilineTextAlignment(self.alertType.descriptionTextAlignment)
                            .foregroundColor(Color.black300)
                            .padding(.horizontal, 16)
                            .padding(.top, self.alertType.title == nil ? 16 : 0)
                    }

                    HStack(alignment: .center, spacing: 15) {
                        if let dismissButtonTitle = self.alertType.dismissButtonTitle {
                            Button(
                                action: {
                                    self.dismissButtonHandler?()
                                },
                                label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.blue500, lineWidth: 1)
                                            .frame(height: 40)
                                        Text(dismissButtonTitle)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(Color.blue500)
                                    }
                                }
                            )
                        }

                        if let actionButtonTitle = self.alertType.actionButtonTitle {
                            Button(
                                action: {
                                    self.actionButtonHandler?()
                                },
                                label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.blue500)
                                            .frame(height: 40)
                                        Text(actionButtonTitle)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.all, 16)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxHeight: 200)
            .padding(.horizontal, 16)
        }
        .onAppear {
            self.hasSmallScreen = UIDevice.hasSmallScreen
        }
    }
}

/// Enumeration for different alert view types
enum AlertType: Equatable {
    case userLoginFailed
    case userRegistrationSuccessfull
    case userRegistrationFailed
    case emailSentForPasswordReset

    // MARK: Public properties

    /// Boolean flag for showing close button
    var shouldShowCloseButton: Bool {
        switch self {
        case .userLoginFailed,
            .userRegistrationSuccessfull,
            .userRegistrationFailed,
            .emailSentForPasswordReset: return false
        }
    }

    /// Icon name for the alert view.
    /// Its optional as every alert views won't have icon to show
    var icon: String? {
        switch self {
        case .userLoginFailed,
            .userRegistrationSuccessfull,
            .userRegistrationFailed,
            .emailSentForPasswordReset: return nil
        }
    }

    /// Tittle text for the alert view
    var title: String? {
        switch self {
        case .userLoginFailed:
            return NSLocalizedString("Login failed", comment: "User login - failure title")
        case .userRegistrationSuccessfull:
            return NSLocalizedString("Registration successful", comment: "User registration - successful title")
        case .userRegistrationFailed:
            return NSLocalizedString("Registration failed", comment: "User registration - failure title")
        case .emailSentForPasswordReset:
            return NSLocalizedString("Email sent for password reset", comment: "User registration - password reset title")
        }
    }

    /// Description text for the alert view
    var description: String? {
        switch self {
        case .userLoginFailed:
            return NSLocalizedString(
                "Oops! login failed. Please check your email, password and try again.",
                comment: "User login - failure description"
            )
        case .userRegistrationSuccessfull:
            return NSLocalizedString(
                "Wooho! your new account is created. Please login with your email and password.",
                comment: "User registration - successful description"
            )
        case .userRegistrationFailed:
            return NSLocalizedString(
                "Oops! there was an error creating your account. Please try again.",
                comment: "User registration - failure description"
            )
        case .emailSentForPasswordReset:
            return NSLocalizedString(
                "We sent you an email with details about resetting your password. Please follow the email instructions.",
                comment: "User registration - password reset description"
            )
        }
    }

    var descriptionTextAlignment: TextAlignment {
        switch self {
        case .userLoginFailed,
            .userRegistrationSuccessfull,
            .userRegistrationFailed,
            .emailSentForPasswordReset: return .leading
        }
    }

    /// Title text for the primary action button
    var actionButtonTitle: String? {
        switch self {
        case .userLoginFailed,
            .userRegistrationSuccessfull,
            .userRegistrationFailed,
            .emailSentForPasswordReset:
            return NSLocalizedString("Ok", comment: "Common view - Ok button label")
        }
    }

    /// Title text for the dismiss  button
    /// Its optional as each alert view won't have dismiss button
    var dismissButtonTitle: String? {
        switch self {
        case .userLoginFailed,
            .userRegistrationSuccessfull,
            .userRegistrationFailed,
            .emailSentForPasswordReset: return nil
        }
        
        // Other options - return NSLocalizedString("Cancel", comment: "Common view - Cancel button label")
    }
}
