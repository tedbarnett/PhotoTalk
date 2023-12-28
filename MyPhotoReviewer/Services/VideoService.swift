//
//  VideoService.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 08/12/23.
//

import UIKit
import AVFoundation

/**
 VideoService provides API for generating MP4 video with the given collection of photos and audio URLs.
 */
class VideoService {
    
    /**
     This method expects photos and audio URLs provided as array. It uses VideoGenerator component to
     merge the photos and audio URLs together to generate a MP4 video.
     
     It uses this video generator library source code - https://github.com/dev-labs-bg/swift-video-generator directly
     added to the project under `/VideoGenerator` folder
     */
    
    func exportVideo(with images: [UIImage], audioURL: [URL], responseHandler: @escaping ResponseHandler<URL?>) {
        let now = Date()
        let videoFileName = "video_\(now.dateTimeStampForFileName).mp4"
        VideoGenerator.fileName = videoFileName
        VideoGenerator.videoBackgroundColor = .black
        VideoGenerator.videoImageWidthForMultipleVideoGeneration = Int(UIScreen.main.bounds.width)
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
}
