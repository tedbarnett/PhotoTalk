//
//  PhotoSlideShowView.swift
//  MyPhotoReviewer-Development
//
//  Created by Prem Pratap Singh on 15/08/23.
//

import SwiftUI

/**
 PhotoSlideShowView presents horizontally scrolling slide show for user selected photos.
 While sliding through photos,  their details like location, date is shown and audio recording is
 also played back if audio is available.
 */
struct PhotoSlideShowView: View {
    
    // MARK: Public properties
    
    var photoAssets: [CloudAsset]?
    var selectedPhotoAsset: CloudAsset?
    
    // MARK: Private properties
    
    @EnvironmentObject private var appContext: AppContext
    @EnvironmentObject private var userProfile: UserProfileModel
    @EnvironmentObject private var overlayContainerContext: OverlayContainerContext
    
    @SwiftUI.Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = PhotoSlideShowViewModel()
    @State private var currentSlideIndex = 0
    
    private let numOfSecondsToShowPhotoDetails = 3
    
    // MARK: User interface
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background
            Color.black900
                .ignoresSafeArea()
            
            ZStack(alignment: .center) {
                // Horizontally scrollable photo slide view
                if self.viewModel.arePhotoDetailsDownloaded {
                    SlidesScrollView(
                        pageCount: self.viewModel.photoDetails.count,
                        isLeftSlideEnabled: self.viewModel.canSlideToLeft,
                        isRightSlideEnabled: self.viewModel.canSlideToRight,
                        currentIndex: self.$currentSlideIndex,
                        delegate: self
                    ) {
                        ForEach(self.viewModel.photoDetails, id: \.self.id) { details in
                            PhotoSlideView(
                                currentSlideIndex: self.$currentSlideIndex,
                                index: self.viewModel.photoDetails.firstIndex(where: {$0.id == details.id}) ?? 0,
                                photoDetails: details,
                                width: UIScreen.main.bounds.width,
                                height: UIScreen.main.bounds.height,
                                numOfSecondsToShowPhotoDetails: self.numOfSecondsToShowPhotoDetails,
                                delegate: self
                            )
                        }
                    }
                    
                    // Large play button to resume slide show playback
//                    Button(
//                        action: {
//                            // TODO: resume slide show playback
//                        },
//                        label: {
//                            Image("playButtonIcon")
//                                .resizable()
//                                .renderingMode(.template)
//                                .tint(Color.offwhite100)
//                                .scaledToFit()
//                                .frame(width: 50, height: 50)
//                        }
//                    )
//                    .opacity(self.viewModel.isPlaybackPaused ? 1 : 0)
//                    .disabled(!self.viewModel.isPlaybackPaused)
                }
            }
            .ignoresSafeArea()
            
            // Share slideshow video button
            HStack(alignment: .center) {
                Button(
                    action: {
                        self.loadVideoAssetsAndExportVideo()
                    },
                    label: {
                        ZStack {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 40, height: 40)
                            Image("shareButtonIcon")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .tint(Color.offwhite100)
                                .frame(width: 30, height: 30)
                        }
                    }
                )
                
                Spacer()
                
                Button(
                    action: {
                        self.presentationMode.wrappedValue.dismiss()
                    },
                    label: {
                        ZStack {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 40, height: 40)
                            Image("closeButtonIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 25)
                        }
                    }
                )
            }
            .padding(.horizontal, 10)
        }
        .onAppear {
            self.initializeViewModel()
            
            // Preparing the assets list for video export before start downloading the photo details
            // becuase during the photo details download, image and audio could be set for the video export assets
            self.viewModel.getPhotoIdsWithUserUploadedAudio { _ in
                // Starting to download photo details
                self.downloadPhotoDetails()
            }
        }
        .onDisappear {
            self.viewModel.resetToDefault()
        }
    }
    
    // MARK: Private methods
    
    private func initializeViewModel() {
        self.viewModel.currentEnvironment = self.appContext.currentEnvironment
        self.viewModel.userProfile = self.userProfile
        self.viewModel.photoAssets = self.photoAssets
        self.viewModel.selectedPhotoAsset = self.selectedPhotoAsset
        self.currentSlideIndex = self.viewModel.currentPhotoIndex
    }
    
    private func downloadPhotoDetails() {
        self.viewModel.arePhotoDetailsDownloaded = false
        self.overlayContainerContext.shouldShowProgressIndicator = true
        self.viewModel.loadPhotoDetails { didLoadDetails in
            self.overlayContainerContext.shouldShowProgressIndicator = false
            
            guard didLoadDetails else {
                self.overlayContainerContext.presentAlert(ofType: .errorStartingPhotoSlideShow)
                return
            }
            print(">>>>> All photo details loaded, starting slide show...")
            self.viewModel.arePhotoDetailsDownloaded = true
        }
    }
    
    private func endSlideShowPresentation() {
        self.viewModel.resetToDefault()
        self.presentationMode.wrappedValue.dismiss()
    }
    
    private func loadVideoAssetsAndExportVideo() {
        self.overlayContainerContext.shouldShowProgressIndicator = true
        // Loading asset details for the video to export
        self.viewModel.loadAssetDetailsForVideoExport { didLoadDetails in
            // Generating video from the loaded assets
            self.viewModel.generateVideoFromAssets { videoURL in
                DispatchQueue.main.async {
                    self.overlayContainerContext.shouldShowProgressIndicator = false
                    guard let url = videoURL,
                          let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else { return }
                    
                    // Presenting native iOS share prompt to allow user share generated video to the targetted platform
                    let activityViewController = UIActivityViewController(activityItems: [url] , applicationActivities: nil)
                    presentingViewController.present(activityViewController, animated: true)
                }
            }
        }
    }
}

// MARK: SlidesScrollViewDelegate delegate methods

extension PhotoSlideShowView: SlidesScrollViewDelegate {
    func didSlidePage(index: Int, position: CGFloat) {
        self.viewModel.onSlidePhotoTo(index: index)
    }

    func didChangeSlidePosition(index: Int, position: CGFloat) {}
}

// MARK: PhotoSlideViewDelegate delegate methods

extension PhotoSlideShowView: PhotoSlideViewDelegate {
    func slideToNextPhoto() {
        let nextSlideIndex = self.viewModel.currentPhotoIndex + 1
        guard let assets = self.viewModel.photoAssets, nextSlideIndex < assets.count else {
            // Ending slide show as all of the photo details have been presented
            //self.endSlideShowPresentation()
            return
        }
        
        self.viewModel.currentPhotoIndex = nextSlideIndex
        self.currentSlideIndex = nextSlideIndex
        print("PhotoSlideShowView > Presenting next slide > loading/caching data for next set of slides")
        print("PhotoSlideShowView > Next slide index: \(self.currentSlideIndex)")
        self.viewModel.loadPhotoDetails { _ in }
    }
}
