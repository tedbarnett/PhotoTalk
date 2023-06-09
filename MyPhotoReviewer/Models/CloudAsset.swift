//
//  CloudAsset.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 01/06/23.
//

import UIKit
import Photos

/**
 CloudAsset represents an assets (folder or photo) stored either on iCloud or Google drive
 */
class CloudAsset: Hashable {
    static func == (lhs: CloudAsset, rhs: CloudAsset) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    let id: String = UUID().uuidString
    let type: CloudAssetType = .photo
    var source: MediaSource = .iCloud
    
    // MARK: Properties for iCloud assets
    var iCloudAsset: PHAsset? = nil
    
    // MARK: Properties for Google Drive assets
    var googleDriveFolderName: String? = nil
    var googleDriveFolderId: String? = nil
    var googleDriveFileId: String? = nil
    
    var isDownloaded: Bool = false
    var isSelected: Bool = false
    
    // MARK: Public methods
    
    /**
     Calls Google drive API to download list of photos from the folder
     */
    func downloadPhotos() {
        
    }
    
    /**
     Downloads photo from the cloud and returns back the same via response handler
     */
    func downloadPhoto(responseHandler: @escaping ResponseHandler<UIImage?>) {
        let photoService = UserPhotoService()
        
        if self.source == .iCloud {
            guard let asset = self.iCloudAsset else { return }
            photoService.downloadPhtoFromICloud(asset: asset) { image in
                guard let downloadedImage = image else {
                    self.isDownloaded = false
                    responseHandler(nil)
                    return
                }
                self.isDownloaded = true
                responseHandler(downloadedImage)
            }
        } else if self.source == .googleDrive {
            guard let fileId = self.googleDriveFileId else { return }
            photoService.downloadPhtoFromGoogleDrive(fileId: fileId) { image in
                guard let downloadedImage = image else {
                    self.isDownloaded = false
                    responseHandler(nil)
                    return
                }
                self.isDownloaded = true
                responseHandler(downloadedImage)
            }
        }
    }
}

/**
 CloudAssetType defines the type of the cloud asset
 */
enum CloudAssetType {
    case folder, photo
}
