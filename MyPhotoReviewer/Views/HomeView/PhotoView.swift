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
    var isZoomAndPanEnabled: Bool = false
    
    // MARK: Private properties
    
    @State private var image: Image?
    @State private var isImageLoading = true
    
    // MARK: User interface
    
    var body: some View {
        ZStack(alignment: .top) {
            if let img = self.image {
                if self.isZoomAndPanEnabled {
                    GeometryReader { proxy in
                        img
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: self.width, height: height)
                            .modifier(ImageModifier(contentSize: CGSize(width: proxy.size.width, height: proxy.size.height)))
                    }
                } else {
                    img
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: self.width, height: height)
                        .clipped()
                }
            }
            
            if self.shouldShowBackground {
                Rectangle()
                    .stroke(Color.gray800.opacity(0.7) , lineWidth: 1)
                    .frame(width: self.width, height: self.height)
            }
        }
        .background(Color.offwhite100)
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
        guard let uiImage = await self.photo.downloadPhoto(ofSize: CGSize(width: self.width * 2, height: self.height * 2)) else {
            self.image = nil
            return
        }
        self.image = Image(uiImage: uiImage)
    }
}
