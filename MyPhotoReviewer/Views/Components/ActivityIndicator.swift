//
//  ActivityIndicator.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 04/05/23.
//

import Foundation
import SwiftUI

/// Presents progress indicator view to indicate undergowing UI related processes
struct ActivityIndicator: UIViewRepresentable {

    // MARK: Public properties

    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    // MARK: Public methods
    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        let activityIndicatorView = UIActivityIndicatorView(style: style)
        activityIndicatorView.color = UIColor.white.withAlphaComponent(0.6)
        return activityIndicatorView
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        self.isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}
