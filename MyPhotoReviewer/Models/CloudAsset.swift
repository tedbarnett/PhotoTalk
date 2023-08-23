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
    var iCloudAssetId: String? = nil
    
    // MARK: Properties for Google Drive assets
    
    var googleDriveFolderName: String? = nil
    var googleDriveFolderId: String? = nil
    var googleDriveFileId: String? = nil
    
    var width: Int? = nil
    var height: Int? = nil
    
    var isDownloaded: Bool = false
    var isSelected: Bool = false
    
    // MARK: Common properties
    
    var photoId: String? {
        if self.source == .iCloud, let assetId = self.iCloudAssetId {
            if assetId.contains("/") {
                // iCloud photo ids (Ex: 6F2093EF-C398-48B4-901F-858C58E36A1C/L0/001) have `/` char
                // so they need to be replaced with - to prevent Firebase storage reference error
                return assetId.replacingOccurrences(of: "/", with: "-")
            }
            return assetId
        } else if self.source == .googleDrive, let fileId = self.googleDriveFileId {
            return fileId
        }
        return nil
    }
    
    // MARK: Public methods
    
    /**
     Downloads photo from the cloud and returns back the same via response handler
     */
    func downloadPhoto() async -> UIImage? {
        let photoService = UserPhotoService()
        
        if self.source == .iCloud {
            guard let asset = self.iCloudAsset,
                  let downloadedImage = try? await photoService.downloadPhtoFromICloud(asset: asset, targetSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)) else {
                self.isDownloaded = false
                return nil
            }
            self.isDownloaded = true
            return downloadedImage
        } else if self.source == .googleDrive {
            return nil
//            guard let fileId = self.googleDriveFileId else { return }
//            photoService.downloadPhtoFromGoogleDrive(fileId: fileId) { image in
//                guard let downloadedImage = image else {
//                    self.isDownloaded = false
//                    responseHandler(nil)
//                    return
//                }
//                self.isDownloaded = true
//                responseHandler(downloadedImage)
//            }
        }
        
        return nil
    }
}

/**
 CloudAssetType defines the type of the cloud asset
 */
enum CloudAssetType {
    case folder, photo
}
