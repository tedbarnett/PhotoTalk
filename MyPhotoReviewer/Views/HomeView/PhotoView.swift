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
    var width: CGFloat
    var height: CGFloat
    var forcePhotoDownload: Bool = false
    var shouldShowBackground: Bool = true
    
    // MARK: Private properties
    
    @State private var image: UIImage?
    @State private var isImageLoading = true
    
    private let horizontalPadding: CGFloat = 12
    
    private var imageWidth: CGFloat {
        return self.width - (self.horizontalPadding * 2)
    }
    
    private var imageHeight: CGFloat {
        return self.height - (self.horizontalPadding * 2)
    }
    
    // MARK: User interface
    
    var body: some View {
        ZStack {
            if self.shouldShowBackground {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black600)
                    .frame(width: self.width, height: self.height)
                    .shadow(color: Color.offwhite100.opacity(0.2), radius: 5, x: 0, y: 0)
            }
            
            if let img = self.image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: self.imageWidth, height: imageHeight)
            }
            
            if self.isImageLoading {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.offwhite100.opacity(0.6))
                        .frame(width: self.width, height: self.height)
                    ActivityIndicator(isAnimating: .constant(true), style: .large)
                }
            }
        }
        .onAppear {
            guard !self.photo.isDownloaded || self.forcePhotoDownload else { return }
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
