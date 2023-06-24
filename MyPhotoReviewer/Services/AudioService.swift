//
//  AudioService.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 24/06/23.
//

import Foundation
import AVFoundation

/**
 AudioServiceDelegate helps notifying about audio service related events
 */
protocol AudioServiceDelegate {
    func didFinishPlayingAudio()
    func didPausePlayingAudio()
    func didResumePlayingAudio()
    func didFailPlayingAudio()
}

/**
 AudioService provides API for recording user audio and saving/loading it from the device
 file system. It also helps in controlling the playback (play, pause, etc) of given audio.
 */
class AudioService: NSObject, AVAudioRecorderDelegate {
    
    // MARK: Public properties
    
    static let instance = AudioService()
    static let audioFileExtension = "m4a"
    var audioFileUrl: URL?
    var delegate: AudioServiceDelegate?
    
    // MARK: Private properties
    
    private var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    var playerItem: AVPlayerItem?
    
    // MARK: Public methods
    
    func startUserAudioRecording(responseHandler: @escaping ResponseHandler<Bool>) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return
            }

            let recordingFileName = UUID().uuidString.appending(".\(AudioService.audioFileExtension)")
            self.audioFileUrl = documentsPath.appendingPathComponent(recordingFileName)
            self.audioRecorder = try AVAudioRecorder(url: self.audioFileUrl!, settings: settings)
            self.audioRecorder?.delegate = self
            self.audioRecorder?.record()
            responseHandler(true)
        } catch {
            print("[AudioService] Error starting audio recording")
            responseHandler(false)
        }
    }
    
    func stopUserAudioRecording() {
        self.audioRecorder?.stop()
    }
    
    func playAudio(_ url: URL) {
        guard self.audioPlayer == nil else {
            self.audioPlayer?.play()
            self.delegate?.didResumePlayingAudio()
            return
        }
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(AVAudioSession.Category.playback)
            let soundData = try Data(contentsOf: url)
            self.audioPlayer = try AVAudioPlayer(data: soundData)
            self.audioPlayer?.prepareToPlay()
            self.audioPlayer?.volume = 0.7
            self.audioPlayer?.delegate = self
            self.audioPlayer?.play()
        } catch {
            print("[AudioService] Error playing audio from url: \(url)")
        }
    }
    
    func pauseAudio() {
        self.audioPlayer?.pause()
        self.delegate?.didPausePlayingAudio()
    }
}

extension AudioService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.audioPlayer = nil
        self.delegate?.didFinishPlayingAudio()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        self.audioPlayer = nil
        self.delegate?.didFailPlayingAudio()
    }
    
    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        self.audioPlayer?.pause()
        self.delegate?.didPausePlayingAudio()
    }
    
    func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        self.audioPlayer?.play()
        self.delegate?.didResumePlayingAudio()
    }
}
