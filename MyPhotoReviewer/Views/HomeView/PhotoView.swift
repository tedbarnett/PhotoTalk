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
    
    // MARK: Private properties
    
    @State private var image: Image?
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
                img
                    .resizable()
                    .scaledToFit()
                    .frame(width: self.imageWidth, height: imageHeight)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.offwhite100.opacity(0.6))
                        .frame(width: self.width, height: self.height)
                    ActivityIndicator(isAnimating: .constant(true), style: .large)
                }
                .opacity(0)
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
            //self.image = nil
        }
    }
    
    // MARK: Private methods
    
    func loadImageAsset(targetSize: CGSize = PHImageManagerMaximumSize) async {
        guard let uiImage = await self.photo.downloadPhoto() else {
            self.image = nil
            return
        }
        self.image = Image(uiImage: uiImage)
    }
}
