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
            .frame(width: UIDevice.isIpad ? UIScreen.main.bounds.width * 0.3 : UIScreen.main.bounds.width - 32)
        }
        .onAppear {
            self.hasSmallScreen = UIDevice.hasSmallScreen
        }
    }
}

/// Enumeration for different alert view types
enum AlertType: Equatable {
    case userRegistrationSuccessfull
    case userRegistrationFailed
    case userLoginSuccessfull
    case userLoginFailed
    case userLoginFailedDueToUnverifiedAccount
    case emailSentForPasswordReset
    case emailFailedForPasswordReset
    case deleteAudioRecording
    case errorStartingPhotoSlideShow
    
    // MARK: Public properties

    /// Boolean flag for showing close button
    var shouldShowCloseButton: Bool {
        switch self {
        case .userRegistrationSuccessfull,
            .userRegistrationFailed,
            .userLoginSuccessfull,
            .userLoginFailed,
            .userLoginFailedDueToUnverifiedAccount,
            .emailSentForPasswordReset,
            .emailFailedForPasswordReset,
            .deleteAudioRecording,
            .errorStartingPhotoSlideShow: return false
        }
    }

    /// Icon name for the alert view.
    /// Its optional as every alert views won't have icon to show
    var icon: String? {
        switch self {
        case .userRegistrationSuccessfull,
            .userRegistrationFailed,
            .userLoginSuccessfull,
            .userLoginFailed,
            .userLoginFailedDueToUnverifiedAccount,
            .emailSentForPasswordReset,
            .emailFailedForPasswordReset,
            .deleteAudioRecording,
            .errorStartingPhotoSlideShow: return nil
        }
    }

    /// Tittle text for the alert view
    var title: String? {
        switch self {
        case .userRegistrationSuccessfull:
            return NSLocalizedString("Registration successful", comment: "User registration - successful title")
        case .userRegistrationFailed:
            return NSLocalizedString("Registration failed", comment: "User registration - failure title")
        case .userLoginSuccessfull: return nil
        case .userLoginFailed, .userLoginFailedDueToUnverifiedAccount:
            return NSLocalizedString("Login failed", comment: "User login - failure title")
        case .emailSentForPasswordReset:
            return NSLocalizedString("Email sent for password reset", comment: "User registration - password reset title")
        case .emailFailedForPasswordReset:
            return NSLocalizedString("Failed to send email", comment: "User registration - password reset title")
        case .deleteAudioRecording:
            return NSLocalizedString("Delete audio?", comment: "Photo details view - delete audio consent title")
        case .errorStartingPhotoSlideShow:
            return NSLocalizedString("Photo slide show", comment: "Photo slide show - error title")
        }
    }

    /// Description text for the alert view
    var description: String? {
        switch self {
        case .userRegistrationSuccessfull:
            return NSLocalizedString(
                "Wooho! your new account is created. A verification email is sent to you for your account activation, please verify and then login with your email and password.",
                comment: "User registration - successful description"
            )
        case .userRegistrationFailed:
            return NSLocalizedString(
                "Oops! there was an error creating your account. Please try again.",
                comment: "User registration - failure description"
            )
        case .userLoginSuccessfull: return nil
        case .userLoginFailed:
            return NSLocalizedString(
                "Oops! login failed. Please check your email, password and try again.",
                comment: "User login - failure description"
            )
        case .userLoginFailedDueToUnverifiedAccount:
            return NSLocalizedString(
                "Oops! login failed. Please verify your account by clicking on the account verification link sent via an email.",
                comment: "User login failed due to unverified account - failure description"
            )
        case .emailSentForPasswordReset:
            return NSLocalizedString(
                "We sent you an email with details about resetting your password. Please follow the email instructions.",
                comment: "User registration - password reset description"
            )
        case .emailFailedForPasswordReset:
            return NSLocalizedString(
                "Oops! there was an error sending email for password reset. Please try again.",
                comment: "User registration - password reset title"
            )
        case .deleteAudioRecording:
            return NSLocalizedString(
                "Do you really want to delete the audio? Once the audio is deleted, it can't be restored.",
                comment: "Photo details view - delete audio consent description"
            )
        case .errorStartingPhotoSlideShow:
            return NSLocalizedString(
                "Oops! error loading photo details for the slide show. Please try again.",
                comment: "Photo slide show - error description")
        }
    }

    var descriptionTextAlignment: TextAlignment {
        switch self {
        case .userRegistrationSuccessfull,
            .userRegistrationFailed,
            .userLoginSuccessfull,
            .userLoginFailed,
            .userLoginFailedDueToUnverifiedAccount,
            .emailSentForPasswordReset,
            .emailFailedForPasswordReset,
            .deleteAudioRecording,
            .errorStartingPhotoSlideShow: return .leading
        }
    }

    /// Title text for the primary action button
    var actionButtonTitle: String? {
        switch self {
        case .userRegistrationSuccessfull,
            .userRegistrationFailed,
            .userLoginSuccessfull,
            .userLoginFailed,
            .userLoginFailedDueToUnverifiedAccount,
            .emailSentForPasswordReset,
            .emailFailedForPasswordReset,
            .errorStartingPhotoSlideShow:
            return NSLocalizedString("Ok", comment: "Common view - Ok button label")
        case .deleteAudioRecording:
            return NSLocalizedString("Yes", comment: "Common view - Yes button label")
        }
    }

    /// Title text for the dismiss  button
    /// Its optional as each alert view won't have dismiss button
    var dismissButtonTitle: String? {
        switch self {
        case .userRegistrationSuccessfull,
            .userRegistrationFailed,
            .userLoginSuccessfull,
            .userLoginFailed,
            .userLoginFailedDueToUnverifiedAccount,
            .emailSentForPasswordReset,
            .emailFailedForPasswordReset,
            .errorStartingPhotoSlideShow: return nil
        case .deleteAudioRecording:
            return NSLocalizedString("No", comment: "Common view - No button label")
        }
    }
}
