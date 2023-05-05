//
//  OverlayContainerView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 04/05/23.
//

import SwiftUI

/**
 This view works as container for presenting overlay views like progress indicator,
 alert views, global views, etc above the B2CTabView.
 */
struct OverlayContainerView: View {

    // MARK: Private properties
    @EnvironmentObject private var overlayContainerContext: OverlayContainerContext

    // MARK: User interface
    var body: some View {
        ZStack {
            // Progress indicator view
            if self.overlayContainerContext.shouldShowProgressIndicator {
                HStack {
                    ActivityIndicator(isAnimating: .constant(true), style: .large)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .background(Color.black.opacity(0.6))
                .edgesIgnoringSafeArea(.all)
            }

            // Alert view
            if self.overlayContainerContext.shouldShowAlert {
                AlertView(
                    alertType: self.overlayContainerContext.alertType,
                    actionButtonHandler: {
                        withAnimation(.easeIn(duration: 0.2)) {
                            self.overlayContainerContext.shouldShowAlert = false
                            self.overlayContainerContext.primaryActionButtonHandler?()
                        }
                    },
                    dismissButtonHandler: {
                        withAnimation(.easeIn(duration: 0.2)) {
                            self.overlayContainerContext.shouldShowAlert = false
                            self.overlayContainerContext.dismissActionButtonHandler?()
                        }
                    }
                )
            }
        }
        .ignoresSafeArea()
    }
}
