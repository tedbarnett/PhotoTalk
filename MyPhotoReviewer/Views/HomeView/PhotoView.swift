//
//  PhotoView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 31/05/23.
//

import SwiftUI
import Photos

/**
 PhotoView displays user photos and provides controls for making favourite, adding
 data, location, audio, etc.
 */
struct PhotoView: View {
    
    // MARK: Public properties
    
    @Binding var currentSlideIndex: Int
    var index: Int = 0
    var photo: CloudAsset
    var width: CGFloat
    var height: CGFloat
    var forcePhotoDownload: Bool = false
    var shouldShowBackground: Bool = true
    var isPresentedAsThumbnail: Bool = false
    
    // MARK: Private properties
    
    @State private var image: Image?
    @State private var isImageLoading = true
    
    private let horizontalPadding: CGFloat = 4
    
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
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black300)
                    .frame(width: self.width, height: self.height)
            }
            
            if let img = self.image {
                img
                    .resizable()
                    .scaledToFit()
                    .frame(width: self.imageWidth, height: imageHeight)
            }
        }
        .onAppear {
            guard self.index == 0 || self.index == self.currentSlideIndex else { return }
            Task {
                await self.loadImageAsset()
            }
        }
        .onChange(of: self.currentSlideIndex) { currentSlideIndex in
            guard self.index == currentSlideIndex else { return }
            Task {
                await self.loadImageAsset()
            }
        }
        .onDisappear {
            self.image = nil
        }
    }
    
    // MARK: Private methods
    
    func loadImageAsset(targetSize: CGSize = PHImageManagerMaximumSize) async {
        guard let uiImage = await self.photo.downloadPhoto(ofSize: CGSize(width: self.width, height: self.height)) else {
            self.image = nil
            return
        }
        self.image = Image(uiImage: uiImage)
    }
}
