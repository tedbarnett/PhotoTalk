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
    
    // MARK: User interface
    
    var body: some View {
        ZStack {
            // Background
            Color.black900
                .ignoresSafeArea()
            
            // Main content
            VStack(alignment: .leading, spacing: 16) {
                // Photo Preview
                if let photo = self.photo {
                    PhotoView(
                        photo: photo,
                        width: UIScreen.main.bounds.width - 48,
                        height: UIScreen.main.bounds.height * 0.65,
                        forcePhotoDownload: true
                    )
                    .padding(.bottom, 14)
                }
                
                
                // Buttons for recording/playing audio
                if self.viewModel.arePhotoDetailsDownloaded {
                    if self.viewModel.photoAudioLocalFileUrl != nil {
                        // Audio playback information
                        if self.viewModel.audioDuration > 0 {
                            Text("\(self.viewModel.audioPlaybackTime, specifier: "%.1f") / \(self.viewModel.audioDuration, specifier: "%.1f")")
                                .font(.system(size: 18))
                                .foregroundColor(Color.white)
                        }
                        
                        // Play audio button
                        Button(
                            action: {
                                if self.viewModel.isPlayingAudio {
                                    self.viewModel.pauseAudio()
                                } else {
                                    self.viewModel.playAudio()
                                }
                            },
                            label: {
                                Image(self.viewModel.isPlayingAudio ? "pauseButton" : "playButton")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 70, height: 70)
                                    .animation(.easeIn(duration: 0.2), value: self.viewModel.isPlayingAudio)
                            }
                        )
                    } else {
                        Button(
                            action: {
                                if self.viewModel.isRecoringInProgress {
                                    self.viewModel.stopAudioRecording()
                                    self.overlayContainerContext.shouldShowProgressIndicator = true
                                    self.viewModel.saveUserRecordingToFirebase { didSaveRecording in
                                        self.overlayContainerContext.shouldShowProgressIndicator = false
                                    }
                                } else {
                                    self.viewModel.startAudioRecording()
                                }
                            },
                            label: {
                                Image(self.viewModel.isRecoringInProgress  ? "recordButton" : "microphoneIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 70, height: 70)
                                    .animation(.easeIn(duration: 0.2), value: self.viewModel.isRecoringInProgress)
                            }
                        )
                    }
                }
                
                Spacer()
                
                // Done button
                Button(
                    action: {
                        self.presentationMode.wrappedValue.dismiss()
                    },
                    label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue)
                                .frame(height: 40)
                            Text(NSLocalizedString("Done", comment: "Common - Done button title"))
                                .font(.system(size: 16))
                                .foregroundColor(Color.white)
                        }
                    }
                )
                
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            self.initializeViewModel()
            self.overlayContainerContext.shouldShowProgressIndicator = true
            self.viewModel.loadPhotoAudio { _ in
                self.overlayContainerContext.shouldShowProgressIndicator = false
            }
        }
        .onDisappear {
            self.viewModel.stopAudio()
            self.viewModel.invalidateViewModel()
        }
    }
    
    // MARK: Private methods
    
    private func initializeViewModel() {
        self.viewModel.currentEnvironment = self.appContext.currentEnvironment
        self.viewModel.photo = self.photo
        self.viewModel.userProfile = self.userProfile
    }
}
