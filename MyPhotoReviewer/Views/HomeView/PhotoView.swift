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
    @State private var uiImage: UIImage?
    @State private var isImageLoading = true
    @State private var currentScale: CGFloat = 1
    @State private var actualImageWidth: CGFloat = 0
    @State private var actualImageHeight: CGFloat = 0
    
    // MARK: User interface
    
    var body: some View {
        ZStack(alignment: .top) {
            if let img = self.image {
                if self.isZoomAndPanEnabled, let uiImage = self.uiImage {
                    let scaleToFitImageOnScreen = UIScreen.main.bounds.width / self.actualImageWidth
                    ZoomableImage(
                        image: uiImage,
                        backgroundColor: .yellow,
                        minScaleFactor: scaleToFitImageOnScreen,
                        idealScaleFactor: scaleToFitImageOnScreen,
                        maxScaleFactor: 5
                    )
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
        .background(Color.black900)
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
    
    private func loadImageAsset(targetSize: CGSize = PHImageManagerMaximumSize) async {
        guard let uiImage = await self.photo.downloadPhoto(ofSize: CGSize(width: self.width, height: self.height)) else {
            self.image = nil
            return
        }
        
        self.actualImageWidth = uiImage.size.width
        self.actualImageHeight = uiImage.size.height
        self.uiImage = uiImage
        self.image = Image(uiImage: uiImage)
    }
    
    private func onImageDoubleTapped() {
        self.resetImageState()
    }
    
    private func resetImageState() {
        withAnimation(.interactiveSpring()) {
            self.currentScale = 1
        }
    }
}
