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
    
    var photo: CloudAsset?
    
    // MARK: Private properties
    
    @SwiftUI.Environment(\.presentationMode) private var presentationMode
    
    @EnvironmentObject private var appContext: AppContext
    @EnvironmentObject private var userProfile: UserProfileModel
    @EnvironmentObject private var overlayContainerContext: OverlayContainerContext
    
    @StateObject private var viewModel = PhotoDetailsViewModel()
    @State private var shouldShowAddPhotoDetailsView = false
    @State private var addPhotoDetailsViewMode: AddPhotoDetailsViewMode = .addLocation
    
    // MARK: User interface
    
    var body: some View {
        ZStack {
            // Background
            Color.black900
                .ignoresSafeArea()
            
            // Photo Preview
            if let photo = self.photo {
                PhotoView(
                    photo: photo,
                    width: UIScreen.main.bounds.width,
                    height: UIScreen.main.bounds.height,
                    forcePhotoDownload: true
                )
                .ignoresSafeArea()
            }
            
            // Back button, favourite button, photo details and audio recording/playback controls
            VStack(alignment: .leading) {
                
                HStack {
                    // Back button
                    Button(
                        action: {
                            self.presentationMode.wrappedValue.dismiss()
                        },
                        label: {
                            ZStack {
                                Rectangle()
                                    .fill(Color.clear)
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
                    
                    // Add location button
                    if self.viewModel.photoLocation == nil {
                        Button(
                            action: {
                                self.addPhotoDetailsViewMode = .addLocation
                                self.shouldShowAddPhotoDetailsView = true
                            },
                            label: {
                                ZStack {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(width: 40, height: 40)
                                    Image("addLocationIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                }
                            }
                        )
                    }
                    
                    // Add Date button
                    if self.viewModel.photoDate == nil {
                        Button(
                            action: {
                                self.addPhotoDetailsViewMode = .addDate
                                self.shouldShowAddPhotoDetailsView = true
                            },
                            label: {
                                ZStack {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(width: 40, height: 40)
                                    Image("addDateIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                }
                            }
                        )
                    }
                    
                    // Favourite button
                    Button(
                        action: {
                            // TODO: Update photo details as favourite - in local database and firebase
                        },
                        label: {
                            ZStack {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 40, height: 40)
                                Image("favouriteIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                            }
                        }
                    )
                    .padding(.trailing, 6)
                }
                .padding(.top, 50)
                
                // Photo location and date
                VStack(alignment: .center) {
                    if let location = self.viewModel.photoLocation {
                        Text(location)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color.offwhite100)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                Spacer()
                
                // Photo details and audio recording/playback controls
                if self.viewModel.arePhotoDetailsDownloaded {
                    ZStack {
                        // Rounded background
                        RoundedRectangle(cornerRadius: 40)
                            .fill(Color.black600)
                            .frame(height: 80)
                            .shadow(color: Color.offwhite100.opacity(0.2), radius: 5, x: 0, y: 0)
                        
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
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.offwhite100)
                                        .frame(height: 4)
                                        .frame(maxWidth: .infinity * 0.4)
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.blue500)
                                        .frame(height: 4)
                                        .frame(maxWidth: (.infinity * 0.4) * self.viewModel.audioPlaybackPercent)
                                }
                                
                                
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
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .frame(height: UIScreen.main.bounds.height)
        }
        .onAppear {
            self.initializeViewModel()
            self.viewModel.stopAudio()
            self.overlayContainerContext.shouldShowProgressIndicator = true
            self.viewModel.loadPhotoDetails()
            self.viewModel.loadPhotoAudio { _ in
                self.overlayContainerContext.shouldShowProgressIndicator = false
            }
        }
        .onDisappear {
            self.viewModel.stopAudio()
            self.viewModel.invalidateViewModel()
        }
        .sheet(isPresented: self.$shouldShowAddPhotoDetailsView) {
            AddPhotoDetailsView(
                mode: self.addPhotoDetailsViewMode,
                delegate: self
            )
        }
    }
    
    // MARK: Private methods
    
    private func initializeViewModel() {
        self.viewModel.currentEnvironment = self.appContext.currentEnvironment
        self.viewModel.photo = self.photo
        self.viewModel.userProfile = self.userProfile
    }
}

// MARK: AddPhotoDetailsViewDelegate delegate methods

extension PhotoDetailsView: AddPhotoDetailsViewDelegate {
    func didSelectDate(date: Date) {
        print("Save date to database")
    }
    
    func didSelectLocation(location: String) {
        self.overlayContainerContext.shouldShowProgressIndicator = true
        self.viewModel.savePhotoLocation(location) { didSave in
            self.overlayContainerContext.shouldShowProgressIndicator = false
        }
    }
}
