//
//  PHAsset + Preview Image + Raw Image.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 25/08/23.
//

import UIKit
import Photos

extension PHAsset {
    
    // MARK: - Public methods
    
    func getAssetThumbnail(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        option.isSynchronous = true
        var thumbnail = UIImage()
        manager.requestImage(
            for: self,
            targetSize: size,
            contentMode: .aspectFit,
            options: option) { result, _ in
                guard let image = result else { return }
                thumbnail = image
        }
        return thumbnail
    }
}
