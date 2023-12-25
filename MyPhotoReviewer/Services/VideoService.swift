//
//  VideoService.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 08/12/23.
//

import UIKit
import AVFoundation

/**
 // Example usage
 let images = [UIImage(named: "image1")!, UIImage(named: "image2")!, UIImage(named: "image3")!]
 let audioURL = Bundle.main.url(forResource: "your_audio_file_name", withExtension: "mp3")!

 exportVideo(fromImages: images, withAudio: audioURL) { outputURL in
     if let outputURL = outputURL {
         print("Exported video URL: \(outputURL)")
     } else {
         print("Export failed")
     }
 }
 */

/**
 SlideShowVideoAsset contains details about the image, audio and other assets
 to include in the slide show video
 */
struct SlideShowVideoAsset {
    let image: UIImage
    let audioUrl: URL?
}

/**
 VideoService helps in stiching user photos and audio annotation together and export/share them as a
 slide show kind of video
 */
class VideoService {
    
    /**
     This method expects photo and audio pairs provided as an array of tuples, where each tuple contains
     a UIImage and a corresponding URL to an audio file. The exportVideo function takes care of creating an
     AVAssetWriter for video and audio, adding tracks, and writing the frames and audio samples.

     Make sure to replace the placeholder values in the video and audio settings with your desired configurations.
     */
    func exportVideo(photoAudioPairs: [(UIImage, URL)], outputURL: URL, completion: @escaping (Error?) -> Void) {
        // Create video writer
        guard let videoWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            completion(NSError(domain: "Error creating video writer", code: 0, userInfo: nil))
            return
        }
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 640,
            AVVideoHeightKey: 480
        ]
        
        let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: nil)
        
        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        } else {
            completion(NSError(domain: "Error adding video writer input", code: 0, userInfo: nil))
            return
        }
        
        // Create audio writer
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 44100.0,
            AVEncoderBitRateKey: 128000
        ]
        
        let audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        
        if videoWriter.canAdd(audioWriterInput) {
            videoWriter.add(audioWriterInput)
        } else {
            completion(NSError(domain: "Error adding audio writer input", code: 0, userInfo: nil))
            return
        }
        
        // Start writing
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: CMTime.zero)
        
        let videoQueue = DispatchQueue(label: "videoQueue")
        
        videoWriterInput.requestMediaDataWhenReady(on: videoQueue) {
            let frameDuration = CMTimeMake(value: 1, timescale: 30)
            var frameCount = 0
            
            while videoWriterInput.isReadyForMoreMediaData {
                if frameCount >= photoAudioPairs.count {
                    break
                }
                
                let frameTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameCount))
                let presentationTime = CMTimeAdd(frameTime, frameDuration)
                
                // Append video frame
                if let pixelBuffer = self.pixelBuffer(from: photoAudioPairs[frameCount].0) {
                    if !adaptor.append(pixelBuffer, withPresentationTime: presentationTime) {
                        completion(NSError(domain: "Error appending video frame", code: 0, userInfo: nil))
                        return
                    }
                }
                
                // Append audio sample
                let audioAsset = AVURLAsset(url: photoAudioPairs[frameCount].1)
                let audioDuration = audioAsset.duration
                let audioTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: audioDuration)
                
                do {
                    //try audioWriterInput.append(audioAsset.tracks(withMediaType: .audio)[0], timeRange: audioTimeRange)
                } catch {
                    completion(error)
                    return
                }
                
                frameCount += 1
            }
            
            // Finish writing
            videoWriterInput.markAsFinished()
            audioWriterInput.markAsFinished()
            
            videoWriter.finishWriting {
                completion(videoWriter.error)
            }
        }
    }
    
    private func pixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        let size = CGSize(width: 640, height: 480)
        var pixelBuffer: CVPixelBuffer? = nil
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, nil, &pixelBuffer)
        
        guard status == kCVReturnSuccess else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer!), width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        UIGraphicsPopContext()
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    /**
     Exports given set of photos and audio as a video file
     */
//    func exportVideo(fromAssets assets: [SlideShowVideoAsset], completion: @escaping (URL?) -> Void) {
//        
//        guard !assets.isEmpty else {
//            completion(nil)
//            return
//        }
//        
//        // Create a video composition
//        let videoComposition = AVMutableComposition()
//
//        // Add video track
//        guard let videoTrack = videoComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
//            completion(nil)
//            return
//        }
//
//        // Add audio track
//        guard let audioTrack = videoComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
//            completion(nil)
//            return
//        }
//        
//        var currentTime = CMTime.zero
//        for asset in assets {
//            try? videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoDuration), of: AVAssetTrack(asset: AVAsset(url: "image")), at: currentTime)
//            
//            if let audioURL = asset.audioUrl {
//                let audioAsset = AVAsset(url: audioURL)
//                let audioDuration = audioAsset.duration
//
//                // Set the video track to the duration of the audio
//                let videoDuration = CMTime(seconds: audioDuration.seconds, preferredTimescale: 600)
//                videoTrack.preferredTransform = CGAffineTransform(rotationAngle: .pi / 2)
//                
//                // Insert the audio track
//                try? audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: audioDuration), of: audioAsset.tracks(withMediaType: .audio)[0], at: .zero)
//            }
//        }
//        
//
//        // Get the duration of the audio
//        
//
//        // Insert each image into the video track
//        var currentTime = CMTime.zero
//        for image in images {
//            try? videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoDuration), of: AVAssetTrack(asset: AVAsset(url: "image")), at: currentTime)
//            currentTime += videoDuration
//        }
//
//        
//
//        // Create an export session
//        guard let exportSession = AVAssetExportSession(asset: videoComposition, presetName: AVAssetExportPresetHighestQuality) else {
//            completion(nil)
//            return
//        }
//
//        // Set output file path
//        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        let outputURL = documentsDirectory.appendingPathComponent("output_video.mp4")
//
//        exportSession.outputURL = outputURL
//        exportSession.outputFileType = .mp4
//
//        // Perform the export
//        exportSession.exportAsynchronously {
//            switch exportSession.status {
//            case .completed:
//                completion(outputURL)
//            default:
//                completion(nil)
//            }
//        }
//    }
}
