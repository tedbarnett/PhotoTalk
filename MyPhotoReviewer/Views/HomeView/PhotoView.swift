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
    @State private var zoomScale: CGFloat = 1
    @State private var previousZoomScale: CGFloat = 1
    
    private let minZoomScale: CGFloat = 1
    private let maxZoomScale: CGFloat = 5
    
    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged(self.onZoomGestureStarted)
            .onEnded(self.onZoomGestureEnded)
    }
    
    // MARK: User interface
    
    var body: some View {
        ZStack(alignment: .top) {
            if let img = self.image {
                if self.isZoomAndPanEnabled {
                    GeometryReader { proxy in
                        ScrollView([.vertical, .horizontal], showsIndicators: false) {
                            img
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .onTapGesture(count: 2, perform: self.onImageDoubleTapped)
                                .gesture(self.zoomGesture)
                                .frame(width: proxy.size.width * max(self.minZoomScale, self.zoomScale))
                                .frame(maxHeight: .infinity)
                        }
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
        guard let uiImage = await self.photo.downloadPhoto(ofSize: CGSize(width: self.width * 2, height: self.height * 2)) else {
            self.image = nil
            return
        }
        self.image = Image(uiImage: uiImage)
    }
    
    private func onImageDoubleTapped() {
        self.resetImageState()
    }
    
    private func onZoomGestureStarted(value: MagnificationGesture.Value) {
        withAnimation(.easeIn(duration: 0.1)) {
            let delta = value / self.previousZoomScale
            self.previousZoomScale = value
            let zoomDelta = self.zoomScale * delta
            var minMaxScale = max(self.minZoomScale, zoomDelta)
            minMaxScale = min(self.maxZoomScale, minMaxScale)
            self.zoomScale = minMaxScale
        }
    }
    
    private func onZoomGestureEnded(value: CGFloat) {
        self.previousZoomScale = 1
        if self.zoomScale <= 1 {
            self.resetImageState()
        } else if zoomScale > 5 {
            self.zoomScale = 5
        }
    }
    
    private func resetImageState() {
        withAnimation(.interactiveSpring()) {
            self.zoomScale = 1
        }
    }
}
