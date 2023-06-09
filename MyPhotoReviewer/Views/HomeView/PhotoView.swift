//
//  PhotoView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 31/05/23.
//

import SwiftUI

/**
 PhotoView displays user photos and provides controls for making favourite, adding
 data, location, audio, etc.
 */
struct PhotoView: View {
    
    // MARK: Public properties
    
    var photo: CloudAsset
    
    // MARK: Private properties
    
    @State private var image: UIImage?
    @State private var isImageLoading = true
    
    // MARK: User interface
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black600)
                .frame(
                    width: UIScreen.main.bounds.width - 48,
                    height: UIScreen.main.bounds.height * 0.7
                )
            
            if let img = self.image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIScreen.main.bounds.width - 96)
            }
            
            if self.isImageLoading {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.offwhite100.opacity(0.6))
                        .frame(
                            width: UIScreen.main.bounds.width - 48,
                            height: UIScreen.main.bounds.height * 0.7
                        )
                    
                    ActivityIndicator(isAnimating: .constant(true), style: .large)
                }
            }
        }
        .onAppear {
            guard !self.photo.isDownloaded else { return }
            self.isImageLoading = true
            self.photo.downloadPhoto { photo in
                DispatchQueue.main.async {
                    self.isImageLoading = false
                    guard let image = photo else { return }
                    self.image = image
                }
            }
        }
    }
}
