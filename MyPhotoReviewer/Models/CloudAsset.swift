//
//  CloudAsset.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 01/06/23.
//

import UIKit
import Photos
import CoreLocation

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
    var type: CloudAssetType = .photo
    var source: MediaSource = .iCloud
    var date: Date? = nil
    
    // MARK: Properties for iCloud assets
    
    var iCloudAsset: PHAsset? = nil
    var iCloudAssetId: String? = nil
    var iCloudAlbumId: String? = nil
    var iCloudAlbumTitle: String? = nil
    var iCloudAlbumPreviewImage: UIImage?
    var iCloudPhotoCreationDate: Date?
    var iCloudPhotoLocation: CLLocation?
    
    // MARK: Properties for Google Drive assets
    
    var googleDriveFolderName: String? = nil
    var googleDriveFolderId: String? = nil
    var googleDriveSubfolders: [CloudAsset]? = nil
    var isSubfolder: Bool = false
    var didLoadFolderDetails: Bool = false
    var googleDriveFileId: String? = nil
    
    var width: Int? = nil
    var height: Int? = nil
    
    var isDownloaded: Bool = false
    var isSelected: Bool = false
    
    // MARK: Common properties
    
    var photoId: String? {
        if self.source == .iCloud, let assetId = self.iCloudId {
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
    
    var albumId: String? {
        if self.source == .iCloud, let albumId = self.iCloudAlbumId {
            return albumId
        } else if self.source == .googleDrive, let folderId = self.googleDriveFolderId {
            return folderId
        }
        return nil
    }
    
    var iCloudId: String? {
        if let assetId = self.iCloudAssetId {
            return assetId
        }
        return self.iCloudAlbumId
    }
    
    // MARK: Public methods
    
    func updateEXIFLocation(to location: CLLocation?) {
        guard let photoAsset = self.iCloudAsset else {
            return
        }
        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest = PHAssetChangeRequest(for: photoAsset)
            assetChangeRequest.location =  location
        }, completionHandler: { success, error in
            guard success, error == nil else {
                print("Error updating EXIF location: \(error)")
                return
            }
            print("Successfully updated EXIF location")
        })
    }
    
    func updateEXIFCreationDate(to date: Date) {
        guard let photoAsset = self.iCloudAsset else {
            return
        }
        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest = PHAssetChangeRequest(for: photoAsset)
            assetChangeRequest.creationDate = date
        }, completionHandler: { success, error in
            guard success, error == nil else {
                print("Error updating EXIF date: \(error)")
                return
            }
            print("Successfully updated EXIF date")
        })
    }
    
    /**
     Downloads photo from the cloud and returns back the same via response handler
     */
    func downloadPhoto(ofSize: CGSize) async -> UIImage? {
        let photoService = UserPhotoService()
        
        if self.source == .iCloud {
            guard let asset = self.iCloudAsset,
                  let downloadedImage = try? await photoService.downloadPhtoFromICloud(asset: asset, targetSize: ofSize) else {
                self.isDownloaded = false
                return nil
            }
            self.isDownloaded = true
            return downloadedImage
        } else if self.source == .googleDrive {
            guard let fileId = self.googleDriveFileId,
                  let downloadedImage = try? await photoService.downloadPhtoFromGoogleDrive(fileId: fileId) else {
                self.isDownloaded = false
                return nil
            }
            self.isDownloaded = true
            return downloadedImage
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
