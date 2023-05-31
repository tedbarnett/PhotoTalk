//
//  UserPhotoService.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 30/05/23.
//

import UIKit
import Photos
import GTMSessionFetcherCore
import GoogleAPIClientForRESTCore
import GoogleAPIClientForREST_Drive
import GoogleSignIn

/**
 UserPhotoService manages the process of connecting to the user's photo source like iCloud,
 Google Drive, Photo Gallery and download photos and their detaiils
 */
class UserPhotoService {
    
    // MARK: Public methods
    
    /**
     Presents native iOS consent popup for requesting access to user's iCloud
     */
    func requestAccessToUserICloud(responseHandler: @escaping ResponseHandler<Bool>) {
        let readStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard readStatus != .authorized else {
            responseHandler(true)
            return
        }
        
        PHPhotoLibrary.requestAuthorization { status in
            responseHandler(status == .authorized)
        }
    }
    
    func downloadUserPhotoAlbumsFromICloud() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumCloudShared,
            options: nil
        )
        
        fetchResult.enumerateObjects { collection, _, _ in
            // Process each iCloud album
            // For example, you can retrieve the album's title:
            let albumTitle = collection.localizedTitle
            // Perform further operations as needed
        }
    }
    
    func downloadUserPhotosFromICloud(responseHandler: @escaping ResponseHandler<[CloudPhoto]>) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        var cloudPhotos = [CloudPhoto]()
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        fetchResult.enumerateObjects { asset, _, _ in
            var photo = CloudPhoto()
            photo.source = .iCloud
            photo.iCloudAsset = asset
            cloudPhotos.append(photo)
        }
        responseHandler(cloudPhotos)
    }
    
    func downloadPhtoFromICloud(asset: PHAsset, responseHandler: @escaping ResponseHandler<UIImage?>) {
        let requiredPhotoSize = CGSize(
            width: 200,
            height: 200
        )
        
        let reqOptions = PHImageRequestOptions()
        reqOptions.isNetworkAccessAllowed = true
        reqOptions.progressHandler = { (progress, error, stop, info) in
            //print("Asset download progress is at \(progress)")
        }
        PHCachingImageManager().requestImage(
            for: asset,
            targetSize: requiredPhotoSize,
            contentMode: .aspectFill,
            options: reqOptions,
            resultHandler: { image, info in
                
                guard let img = image else {
                    if let isIniCloud = info?[PHImageResultIsInCloudKey] as? NSNumber, isIniCloud.boolValue == true {
                        print("Downloading image from iCloud...")
                    }
                    responseHandler(nil)
                    return
                }
                responseHandler(img)
            })
    }
    
    func downloadUserPhotosFromGoogleDrive(responseHandler: @escaping ResponseHandler<[CloudPhoto]>) {
        let service = GTLRDriveService()
        service.authorizer = GIDSignIn.sharedInstance.currentUser?.fetcherAuthorizer
        let query = GTLRDriveQuery_FilesList.query()
        query.q = "mimeType contains 'image/'"
        
        service.executeQuery(query) { ticket, files, error in
            guard error == nil,
                  let photos = files as? GTLRDrive_FileList,
                  let fileList = photos.files else {
                print("Error retrieving photos from Google Drive")
                responseHandler([])
                return
            }
            
            var cloudPhotos = [CloudPhoto]()
            for file in fileList {
                let fileName = file.name
                let fileId = file.identifier
                
                var photo = CloudPhoto()
                photo.source = .googleDrive
                photo.googleDriveFileId = fileId
                cloudPhotos.append(photo)
            }
            responseHandler(cloudPhotos)
        }
    }
    
    func downloadPhtoFromGoogleDrive(fileId: String, responseHandler: @escaping ResponseHandler<UIImage?>) {
        let service = GTLRDriveService()
        service.authorizer = GIDSignIn.sharedInstance.currentUser?.fetcherAuthorizer
        service.executeQuery(GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileId)) { (ticket, file, error) in
            guard error == nil,
                  let data = (file as? GTLRDataObject)?.data,
                  let image = UIImage(data: data) else {
                responseHandler(nil)
                return
            }
            responseHandler(image)
        }
    }
}
