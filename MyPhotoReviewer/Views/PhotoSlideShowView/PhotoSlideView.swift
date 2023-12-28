//
//  PhotoSlideView.swift
//  MyPhotoReviewer-Development
//
//  Created by Prem Pratap Singh on 15/08/23.
//

import SwiftUI

/**
 PhotoSlideViewDelegate informs host view to slide to the next PhotoSlideView
 after either the time to show photo details is elapsed or available audio is played
 back in full length.
 */
protocol PhotoSlideViewDelegate {
    func slideToNextPhoto()
}

/**
 PhotoSlideView shows photo and its details like location, date, etc
 It also provides audio play back controls, if auido is available.
 */
struct PhotoSlideView: View {
    
    // MARK: Public properties
    
    @Binding var currentSlideIndex: Int
    @Binding var isPlaybackPaused: Bool
    var index: Int = 0
    var photoDetails: Photo?
    var width: CGFloat = 0
    var height: CGFloat = 0
    var numOfSecondsToShowPhotoDetails: Int = 5
    var delegate: PhotoSlideViewDelegate?
        
    // MARK: Private properties
    
    @State private var slideToNextPhotoTimer: Timer? = nil
    
    @State private var audioUrl: URL?
    @State private var isPlayingAudio: Bool = false
    @State private var audioDuration: Double = 0
    @State private var audioPlaybackTime: Double = 0
    @State private var audioPlaybackPercent: Double = 0.001
    
    // MARK: User interface
    
    var body: some View {
        ZStack {
            // Background
            Color.black900
                .ignoresSafeArea()
            
            // Image preview
            VStack(alignment: .leading) {
                if let details = self.photoDetails,
                   let image = details.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: self.width, height: height)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.offwhite100.opacity(0.6))
                            .frame(width: self.width, height: self.height)
                        ActivityIndicator(isAnimating: .constant(true), style: .large)
                    }
                }
            }
            .ignoresSafeArea()
            
            // Photo details - Location, Date, Audio Playback controls
            if let details = self.photoDetails {
                Spacer(minLength: 100)
                VStack(alignment: .center) {
                    Spacer()
                    VStack(alignment: .center, spacing: 16) {
                        // Photo location
                        if let location = details.location {
                            Text(location)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.offwhite100)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        
                        // Photo date and time
                        if let dateAndTime = details.dateAndTime {
                            Text(dateAndTime.photoNodeFormattedDateAndTimeString)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.offwhite100)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        
                        // Audio playback controls
                        if details.audioUrl != nil {
                            ZStack {
                                // Rounded background
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black600)
                                    .frame(height: 40)
                                    .shadow(color: Color.offwhite100.opacity(0.2), radius: 2, x: 0, y: 0)
                                    .opacity(details.audioUrl != nil ? 1 : 0)
                                
                                // Controls for recording, saving and deleting audio
                                HStack(alignment: .center, spacing: 16) {
                                    // Audio playback duration detail
                                    Text("\(self.audioPlaybackTime, specifier: "%.1f") / \(self.audioDuration, specifier: "%.1f")")
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
                                                .frame(width: reader.size.width * self.audioPlaybackPercent)
                                        }
                                    }
                                    .frame(height: 4)
                                }
                                .padding(.horizontal, 24)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.all, 24)
                    .padding(.bottom, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.black300)
                            .frame(maxWidth: .infinity)
                            .shadow(color: Color.offwhite100.opacity(0.4), radius: 8, x: 0, y: 0)
                            .opacity(details.hasSomeDetailToShow ? 1 : 0)
                    )
                }
                .frame(height: UIScreen.main.bounds.height)
            }
        }
        .clipped()
        .onChange(of: self.isPlaybackPaused) { isPaused in
            if isPaused {
                if self.isPlayingAudio {
                    self.pauseAudio()
                }
                if self.slideToNextPhotoTimer != nil {
                    self.invalidateTimerIfAny()
                }
            } else {
                self.resumeAudio()
                if self.audioUrl == nil {
                    self.setSlideToNextPhotoTimer()
                }
            }
        }
        .onAppear {
            guard self.index == 0 else { return }
            self.initializeSlidePresentation()
        }
        .onDisappear {
            self.stopAudio()
            AudioService.instance.invalidate()
            
            guard let details = self.photoDetails else { return }
            details.image = nil
        }
        .onChange(of: self.currentSlideIndex) { index in
            guard self.index == index else { return }
            self.initializeSlidePresentation()
        }
    }
    
    // MARk: Private methods
    
    private func initializeSlidePresentation() {
        // Stop existing timer, if any
        self.invalidateTimerIfAny()
        
        // Setting audio service delegate to nil
        AudioService.instance.delegate = nil
        
        // Start playing the audio (if available) or start the timer to show photo and photo details
        self.playAudioOrScheduleSlideToNextPhotoTimerAsNeeded()
    }
    
    /**
     Starts a timer of 3 seconds to slide to the next photo, if there are no audio to
     play. If audio exists, the slide to next photo call is made after the audio playback
     is completed
     */
    private func playAudioOrScheduleSlideToNextPhotoTimerAsNeeded() {
        self.invalidateTimerIfAny()
        if let url = self.photoDetails?.audioUrl {
            self.audioUrl = url
            AudioService.instance.delegate = self
            AudioService.instance.initializeAudioPlayer(forAudioUrl: url)
            self.playAudio()
        } else {
            self.setSlideToNextPhotoTimer()
        }
    }
    
    private func setSlideToNextPhotoTimer() {
        if self.slideToNextPhotoTimer == nil {
            self.slideToNextPhotoTimer = Timer.scheduledTimer(
                withTimeInterval: 5.0,
                repeats: false) { _ in
                self.delegate?.slideToNextPhoto()
            }
        }
    }
    
    private func invalidateTimerIfAny() {
        self.slideToNextPhotoTimer?.invalidate()
        self.slideToNextPhotoTimer = nil
    }
    
    /**
     Attempts to play available photo audio
     */
    private func playAudio() {
        guard self.audioUrl != nil else { return }
        self.isPlayingAudio = true
        AudioService.instance.playAudio()
    }
    
    /**
     Attempts to pause available photo audio playback
     */
    private func pauseAudio() {
        self.isPlayingAudio = false
        AudioService.instance.pauseAudio()
    }
    
    private func resumeAudio() {
        self.isPlayingAudio = true
        AudioService.instance.resumeAudio()
    }
    
    /**
     Attempts to stop available photo audio playback
     */
    private func stopAudio() {
        AudioService.instance.stopAudio()
        self.isPlayingAudio = false
    }
}


// MARK: AudioServiceDelegate delegate methods

extension PhotoSlideView: AudioServiceDelegate {
    func isPlayingAudio(currentTime: Double) {
        self.audioDuration = AudioService.instance.audioDuration
        self.audioPlaybackTime = currentTime
        if self.audioPlaybackTime > 0 && self.audioDuration > 0 {
            let percent = self.audioPlaybackTime/self.audioDuration
            self.audioPlaybackPercent = percent > 1.0 ? 1.0 : percent
            self.audioPlaybackTime = percent > 1 ? 0 : currentTime
        }
    }
    
    func didFinishPlayingAudio() {
        self.isPlayingAudio = false
        if self.slideToNextPhotoTimer == nil {
            self.slideToNextPhotoTimer = Timer.scheduledTimer(
                withTimeInterval: 1.0,
                repeats: false) { _ in
                self.delegate?.slideToNextPhoto()
            }
        }
    }
    
    func didPausePlayingAudio() {
        self.isPlayingAudio = false
    }
    
    func didStopPlayingAudio() {
        self.isPlayingAudio = false
    }
    
    func didResumePlayingAudio() {
        self.isPlayingAudio = true
    }
    
    func didFailPlayingAudio() {
        self.isPlayingAudio = false
    }
}
