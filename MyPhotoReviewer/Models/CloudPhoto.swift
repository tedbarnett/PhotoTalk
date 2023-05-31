//
//  CloudPhoto.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 01/06/23.
//

import UIKit
import Photos

/**
 CloudPhoto represents a photo stored either on iCloud or Google drive
 */
class CloudPhoto: Hashable {
    static func == (lhs: CloudPhoto, rhs: CloudPhoto) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    let id: String = UUID().uuidString
    var source: MediaSource = .iCloud
    var iCloudAsset: PHAsset? = nil
    var googleDriveFileId: String? = nil
    
    // MARK: Public methods
    
    /**
     Downloads photo from the cloud and returns back the same via response handler
     */
    func downloadPhoto(responseHandler: @escaping ResponseHandler<UIImage?>) {
        let photoService = UserPhotoService()
        
        if self.source == .iCloud {
            guard let asset = self.iCloudAsset else { return }
            photoService.downloadPhtoFromICloud(asset: asset, responseHandler: responseHandler)
        } else if self.source == .googleDrive {
            guard let fileId = self.googleDriveFileId else { return }
            photoService.downloadPhtoFromGoogleDrive(fileId: fileId, responseHandler: responseHandler)
        }
    }
}
