//
//  PhotoDetailsView.swift
//  MyPhotoReviewer-Development
//
//  Created by Prem Pratap Singh on 15/06/23.
//

import SwiftUI

/**
 PhotoDetailsView presents larger view of the user photo and details added to it.
 This view also provides UI/UX for adding/editing photo details like location, date, audio, etc
 */
struct PhotoDetailsView: View {
    
    // MARK: Public properties
    
    var photos: [CloudAsset]?
    var selectedPhoto: CloudAsset?
    
    // MARK: Private properties
    
    @SwiftUI.Environment(\.presentationMode) private var presentationMode
    
    @EnvironmentObject private var appContext: AppContext
    @EnvironmentObject private var userProfile: UserProfileModel
    @EnvironmentObject private var overlayContainerContext: OverlayContainerContext
    
    @StateObject private var viewModel = PhotoDetailsViewModel()
    @State private var shouldShowAddPhotoDetailsView = false
    @State private var addPhotoDetailsViewMode: AddPhotoDetailsViewMode = .addLocation
    @State private var currentSlideIndex: Int = 0
    @State private var canSlideToLeft: Bool = false
    @State private var canSlideToRight: Bool = true
    
    // MARK: User interface
    
    var body: some View {
        ZStack {
            // Background
            Color.black900
                .ignoresSafeArea()
            
            VStack(alignment: .leading) {
                // Photo Preview horizontal scroll view
                if let photos = self.viewModel.photos {
                    SlidesScrollView(
                        pageCount: photos.count,
                        isLeftSlideEnabled: self.canSlideToLeft,
                        isRightSlideEnabled: self.canSlideToRight,
                        currentIndex: self.$currentSlideIndex,
                        delegate: self
                    ) {
                        ForEach (0..<photos.count, id: \.self) { index in
                            let photo = photos[index]
                            PhotoView(
                                currentSlideIndex: self.$currentSlideIndex,
                                index: index,
                                photo: photo,
                                width: UIScreen.main.bounds.width,
                                height: UIScreen.main.bounds.height,
                                forcePhotoDownload: true,
                                shouldShowBackground: false,
                                isPresentedAsThumbnail: false,
                                isZoomAndPanEnabled: true
                            )
                        }
                    }
                }
                Spacer(minLength: 100)
            }
            .ignoresSafeArea()
            
            // Main Content
            VStack(alignment: .center) {
                
                // Toolbar - Back button, Add location button, Add data button, favourite button
                HStack {
                    // Back button
                    Button(
                        action: {
                            self.presentationMode.wrappedValue.dismiss()
                        },
                        label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 40, height: 40)
                                Image("leftArrowIcon")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 9, height: 16)
                                    .tint(Color.offwhite100)
                            }
                        }
                    )
                    
                    Spacer()
                    
                    if self.viewModel.arePhotoDetailsDownloaded {
                        // Favourite button
                        Button(
                            action: {
                                self.overlayContainerContext.shouldShowProgressIndicator = true
                                self.viewModel.updateFavouriteState { _ in
                                    self.overlayContainerContext.shouldShowProgressIndicator = false
                                }
                            },
                            label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.black.opacity(0.6))
                                        .frame(width: 40, height: 40)
                                    Image(self.viewModel.isFavourite ? "favouriteIcon" : "unfavouriteIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                }
                            }
                        )
                        //.padding(.trailing, 6)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 50)
                
                Spacer()
                
                if self.viewModel.arePhotoDetailsDownloaded {
                    // Photo details - Location, Date, Audio Recording/Playback controls
                    VStack(alignment: .center, spacing: 16) {
                        // Photo location
                        if let location = self.viewModel.photoLocation {
                            Text(location)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.offwhite100)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .onTapGesture {
                                    self.addPhotoDetailsViewMode = .addLocation
                                    self.shouldShowAddPhotoDetailsView = true
                                }
                        }
                        
                        // Photo date and time
                        if let photoDateString = self.viewModel.photoDateString {
                            Text(photoDateString)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.offwhite100)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .onTapGesture {
                                    self.addPhotoDetailsViewMode = .addDate
                                    self.shouldShowAddPhotoDetailsView = true
                                }
                        }
                        
                        // Audio recording/playback controls
                        ZStack {
                            // Rounded background
                            RoundedRectangle(cornerRadius: 40)
                                .fill(Color.black600)
                                .frame(height: 80)
                                .shadow(color: Color.offwhite100.opacity(0.2), radius: 2, x: 0, y: 0)
                            
                            // Controls for recording, saving and deleting audio
                            if self.viewModel.photoAudioLocalFileUrl != nil {
                                HStack(alignment: .center, spacing: 16) {
                                    // Play/Pause audio button
                                    Button(
                                        action: {
                                            if self.viewModel.isPlayingAudio {
                                                self.viewModel.pauseAudio()
                                            } else {
                                                self.viewModel.playAudio()
                                            }
                                        },
                                        label: {
                                            Image(self.viewModel.isPlayingAudio ? "pauseButtonIcon" : "playButtonIcon")
                                                .resizable()
                                                .renderingMode(.template)
                                                .tint(Color.offwhite100)
                                                .scaledToFit()
                                                .frame(width: 30, height: 30)
                                                .animation(.easeIn(duration: 0.2), value: self.viewModel.isPlayingAudio)
                                        }
                                    )
                                    
                                    // Audio playback duration detail
                                    Text("\(self.viewModel.audioPlaybackTime, specifier: "%.1f") / \(self.viewModel.audioDuration, specifier: "%.1f")")
                                        .font(.system(size: 14))
                                        .scaledToFit()
                                        .foregroundColor(Color.offwhite100)
                                        .frame(width: 70)
                                    
                                    // Audio playback progress indicator
                                    GeometryReader { reader in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.offwhite100)
                                                .frame(height: 4)
                                                .frame(width: reader.size.width)
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.blue500)
                                                .frame(height: 4)
                                                .frame(width: reader.size.width * self.viewModel.audioPlaybackPercent)
                                        }
                                    }
                                    .frame(height: 4)
                                    
                                    // Delete audio button
                                    Button(
                                        action: {
                                            self.overlayContainerContext.presentAlert(
                                                ofType: .deleteAudioRecording,
                                                primaryActionButtonHandler: {
                                                    self.overlayContainerContext.shouldShowProgressIndicator = true
                                                    self.viewModel.deleteAudioRecordingFromServer { didDeleteRecording in
                                                        self.overlayContainerContext.shouldShowProgressIndicator = false
                                                    }
                                                }
                                            )
                                        },
                                        label: {
                                            Image("deleteButtonIcon")
                                                .resizable()
                                                .renderingMode(.template)
                                                .tint(Color.offwhite100)
                                                .scaledToFit()
                                                .frame(width: 30, height: 30)
                                        }
                                    )
                                }
                                .padding(.horizontal, 24)
                            }
                            
                            // Controls for playing, progress and deleting audio
                            else {
                                HStack(alignment: .center, spacing: 16) {
                                    
                                    // Save audio recording button
                                    Button(
                                        action: {
                                            self.overlayContainerContext.shouldShowProgressIndicator = true
                                            self.viewModel.saveUserRecordingToServer { didSaveRecording in
                                                self.overlayContainerContext.shouldShowProgressIndicator = false
                                            }
                                        },
                                        label: {
                                            Image("saveButtonIcon")
                                                .resizable()
                                                .renderingMode(.template)
                                                .tint(self.viewModel.didRecordAudio ? Color.offwhite100 : Color.gray600)
                                                .scaledToFit()
                                                .frame(width: 24, height: 24)
                                        }
                                    )
                                    .disabled(!self.viewModel.didRecordAudio)
                                    
                                    Spacer()
                                    
                                    // Record audio button
                                    Button(
                                        action: {
                                            if self.viewModel.isRecoringInProgress {
                                                self.viewModel.stopAudioRecording()
                                            } else {
                                                self.viewModel.startAudioRecording()
                                            }
                                        },
                                        label: {
                                            Image(self.viewModel.isRecoringInProgress ? "recordingAudioIcon" : "recordAudioIcon")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 40, height: 40)
                                        }
                                    )
                                    
                                    Spacer()
                                    
                                    // Delete audio recording button
                                    Button(
                                        action: {
                                            self.overlayContainerContext.presentAlert(
                                                ofType: .deleteAudioRecording,
                                                primaryActionButtonHandler: {
                                                    self.viewModel.deleteAudioRecordingFromLocal()
                                                }
                                            )
                                        },
                                        label: {
                                            Image("deleteButtonIcon")
                                                .resizable()
                                                .renderingMode(.template)
                                                .tint(self.viewModel.didRecordAudio ? Color.offwhite100 : Color.gray600)
                                                .scaledToFit()
                                                .frame(width: 30, height: 30)
                                        }
                                    )
                                    .disabled(!self.viewModel.didRecordAudio)
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    }
                    .padding(.all, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.black300)
                            .frame(maxWidth: .infinity)
                            .shadow(color: Color.offwhite100.opacity(0.4), radius: 8, x: 0, y: 0)
                    )
                }
            }
            .frame(height: UIScreen.main.bounds.height)
        }
        .onAppear {
            self.initializeViewModel()
            self.downloadPhotoDetails()
        }
        .onDisappear {
            self.viewModel.stopAudio()
            self.viewModel.invalidateViewModel()
        }
        .sheet(isPresented: self.$shouldShowAddPhotoDetailsView) {
            AddPhotoDetailsView(
                photo: self.selectedPhoto,
                mode: self.addPhotoDetailsViewMode,
                selectedLocation: self.viewModel.photoLocation,
                selectedDateString: self.viewModel.photoDateString,
                delegate: self
            )
        }
    }
    
    // MARK: Private methods
    
    private func initializeViewModel() {
        self.viewModel.currentEnvironment = self.appContext.currentEnvironment
        self.viewModel.photos = self.photos
        self.viewModel.selectedPhoto = self.selectedPhoto
        if let selectedPhoto = self.selectedPhoto,
           let photos = self.photos,
           let index = photos.firstIndex(where: {$0.photoId == selectedPhoto.photoId}) {
            self.currentSlideIndex = index
            self.canSlideToLeft = index > 0
            self.canSlideToRight = index < photos.count - 1
        }
        self.viewModel.userProfile = self.userProfile
    }
    
    private func downloadPhotoDetails() {
        self.viewModel.stopAudio()
        self.viewModel.arePhotoDetailsDownloaded = false
        
        self.viewModel.loadPhotoDetails()
        self.viewModel.loadPhotoAudio { _ in
            self.viewModel.initializeAudioPlayer()
        }
    }
}

// MARK: AddPhotoDetailsViewDelegate delegate methods

extension PhotoDetailsView: AddPhotoDetailsViewDelegate {
    func didSelectDate(date: Date) {
        self.viewModel.updatePhotoEXIFDate(to: date)
        
        self.overlayContainerContext.shouldShowProgressIndicator = true
        self.viewModel.savePhotoDateAndTime(date) { didSave in
            self.overlayContainerContext.shouldShowProgressIndicator = false
        }
    }
    
    func didSelectLocation(location: GooglePlace) {
        guard !location.name.isEmpty else { return }
        self.viewModel.updatePhotoEXIFLocation(to: location)
        
        self.overlayContainerContext.shouldShowProgressIndicator = true
        self.viewModel.savePhotoLocation(location.name) { didSave in
            self.overlayContainerContext.shouldShowProgressIndicator = false
        }
    }
}

// MARK: SlidesScrollViewDelegate delegate methods

extension PhotoDetailsView: SlidesScrollViewDelegate {
    func didSlidePage(index: Int, position: CGFloat) {
        guard let photos = self.viewModel.photos else { return }
        self.canSlideToLeft = index > 0
        self.canSlideToRight = index < photos.count - 1
        
        let photo = photos[index]
        self.viewModel.selectedPhoto = photo
        self.downloadPhotoDetails()
    }

    func didChangeSlidePosition(index: Int, position: CGFloat) {}
}
