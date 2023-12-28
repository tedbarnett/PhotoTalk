//
//  VideoService.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 08/12/23.
//

import UIKit
import AVFoundation

/**
 VideoService provides API for generating MP4 video with the given collection of `AssetForVideoExport`
 where each AssetForVideoExport instance contains details like image, audio url, location and date.
 */
class VideoService {
    
    /**
     This method expects photo and audio pairs provided as an array of tuples, where each tuple contains
     a UIImage and a corresponding URL to an audio file. The exportVideo function takes care of creating an
     AVAssetWriter for video and audio, adding tracks, and writing the frames and audio samples.

     Make sure to replace the placeholder values in the video and audio settings with your desired configurations.
     */
    
    func exportVideo(with images: [UIImage], audioURL: [URL], responseHandler: @escaping ResponseHandler<URL?>) {
        let now = Date()
        let videoFileName = "video_\(now.dateTimeStampForFileName).mp4"
        VideoGenerator.fileName = videoFileName
        VideoGenerator.videoBackgroundColor = .black
        VideoGenerator.videoImageWidthForMultipleVideoGeneration = 2000
        VideoGenerator.current.generate(
            withImages: images,
            andAudios: audioURL,
            andType: .multiple,
            { progress in
                print("[VideoGenerator] progress: \(progress)")
            },
            outcome: { result in
                switch result {
                case .success(let url):
                    print("[VideoGenerator] successfully exported video at URL: \(url.absoluteString)")
                    responseHandler(url)
                case .failure(let error): 
                    print("[VideoGenerator] error exporting video: \(error)")
                    responseHandler(nil)
                }
            }
        )
    }
    
    /**
     This method expects photo and audio pairs provided as an array of tuples, where each tuple contains
     a UIImage and a corresponding URL to an audio file. The exportVideo function takes care of creating an
     AVAssetWriter for video and audio, adding tracks, and writing the frames and audio samples.

     Make sure to replace the placeholder values in the video and audio settings with your desired configurations.
     */
    func exportVideo(fromAssets assets: [AssetForVideoExport], responseHandler: @escaping ResponseHandler<URL?>) {
        
        // Create video writer
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let now = Date()
        let videoFileName = "video_\(now.dateTimeStampForFileName).mp4"
        let outputURL = documentsDirectory.appendingPathComponent(videoFileName)
        
        guard let videoWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            print("Error creating video writer")
            responseHandler(nil)
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
            print("Error adding video writer input")
            responseHandler(nil)
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
            print("Error adding audio writer input")
            responseHandler(nil)
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
                if frameCount >= assets.count {
                    break
                }
                
                let videoAsset = assets[frameCount]
                let frameTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameCount))
                let presentationTime = CMTimeAdd(frameTime, frameDuration)
                
                // Append video frame
                if let image = videoAsset.image, let pixelBuffer = self.pixelBuffer(from: image) {
                    if !adaptor.append(pixelBuffer, withPresentationTime: presentationTime) {
                        print("Error appending video frame")
                        responseHandler(nil)
                        return
                    }
                }
                
                // Append audio sample
                if let audioURL = videoAsset.audioUrl {
                    let audioAsset = AVURLAsset(url: audioURL)
                    let audioDuration = audioAsset.duration
                    let audioTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: audioDuration)
                    
                    do {
                        if audioWriterInput.isReadyForMoreMediaData, let audioSampleBuffer = self.createSampleBuffer(from: audioURL) {
                            audioWriterInput.append(audioSampleBuffer)
                        }
                        
                        //try audioWriterInput.append(audioAsset.tracks(withMediaType: .audio)[0], timeRange: audioTimeRange)
                    } catch {
                        print("Error appending audio \(error.localizedDescription)")
                        responseHandler(nil)
                        return
                    }
                }
                
                frameCount += 1
            }
            
            // Finish writing
            videoWriterInput.markAsFinished()
            audioWriterInput.markAsFinished()
            
            videoWriter.finishWriting {
                responseHandler(outputURL)
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
    
    private func createSampleBuffer(from audioURL: URL) -> CMSampleBuffer? {
        // Create AVAsset from the audio URL
        let asset = AVAsset(url: audioURL)

        // Create an AVAssetReader
        guard let assetReader = try? AVAssetReader(asset: asset) else {
            return nil
        }

        // Get the audio track from the asset
        guard let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first else {
            return nil
        }

        // Set up the track output
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM
        ]

        let trackOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
        assetReader.add(trackOutput)

        // Start reading from the asset
        assetReader.startReading()

        // Create a CMSampleBuffer
        var sampleBuffer: CMSampleBuffer?
        while let nextBuffer = trackOutput.copyNextSampleBuffer() {
            sampleBuffer = nextBuffer
        }

        // Finish reading
        assetReader.cancelReading()

        return sampleBuffer
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
