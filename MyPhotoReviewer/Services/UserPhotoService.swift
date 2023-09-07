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
    
    // MARK: Private properties
    
    /// The manager that will fetch and cache photos for us
    var imageCachingManager = PHCachingImageManager()
    
    // MARK: Public methods
    
    /**
     Presents native iOS consent popup for requesting access to user's iCloud
     */
    func requestAccessToUserICloud(responseHandler: @escaping ResponseHandler<Bool>) {
        let readStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard readStatus != .authorized || readStatus != .limited else {
            responseHandler(true)
            return
        }
        
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized, .limited:
                responseHandler(true)
            case .denied, .restricted, .notDetermined:
                responseHandler(false)
            @unknown default:
                responseHandler(false)
            }
        }
    }
    
    func fetchPhotoAlbumsFromUserDevice(responseHandler: @escaping ResponseHandler<[CloudAsset]>) {
        let result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        var photoAlbums = [CloudAsset]()
        result.enumerateObjects { photoAlbum, _, _ in
            let albumPhotos = PHAsset.fetchAssets(in: photoAlbum, options: nil)
            if albumPhotos.count > 0 {
                let album = CloudAsset()
                album.source = .iCloud
                album.iCloudAlbumId = photoAlbum.localIdentifier
                album.iCloudAlbumTitle = photoAlbum.localizedTitle
                album.iCloudAlbumPreviewImage = albumPhotos.firstObject?.getAssetThumbnail()
                photoAlbums.append(album)
            }
        }
        responseHandler(photoAlbums)
    }
    
    func fetchPhotosFromUserDevice(responseHandler: @escaping ResponseHandler<[CloudAsset]>) {
        let photosOptions = PHFetchOptions()
        photosOptions.sortDescriptors = [
          NSSortDescriptor(
            key: "creationDate",
            ascending: false)
        ]
        
        var cloudPhotos = [CloudAsset]()
        let result = PHAsset.fetchAssets(with: photosOptions)
        result.enumerateObjects { asset, _, _ in
            let photo = CloudAsset()
            photo.source = .iCloud
            photo.iCloudAssetId = asset.localIdentifier
            photo.width = asset.pixelWidth
            photo.height = asset.pixelHeight
            photo.iCloudAsset = asset
            cloudPhotos.append(photo)
        }
        responseHandler(cloudPhotos)
    }
    
    func downloadUserPhotosFromICloud(responseHandler: @escaping ResponseHandler<[CloudAsset]>) {
        self.imageCachingManager.allowsCachingHighQualityImages = false
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.includeHiddenAssets = false
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        var cloudPhotos = [CloudAsset]()
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        fetchResult.enumerateObjects { asset, _, _ in
            let photo = CloudAsset()
            photo.source = .iCloud
            photo.iCloudAssetId = asset.localIdentifier
            photo.width = asset.pixelWidth
            photo.height = asset.pixelHeight
            photo.iCloudAsset = asset
            cloudPhotos.append(photo)
        }
        
        responseHandler(cloudPhotos)
    }
    
    func downloadPhtoFromICloud(asset: PHAsset, targetSize: CGSize) async throws -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .none
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            /// Use the imageCachingManager to fetch the image
            self?.imageCachingManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options,
                resultHandler: { image, info in
                    /// image is of type UIImage
                    if let error = info?[PHImageErrorKey] as? Error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: image)
                }
            )
        }
    }
    
    func downloadUserFoldersFromGoogleDrive(responseHandler: @escaping ResponseHandler<[CloudAsset]>) {
        let service = GTLRDriveService()
        service.authorizer = GIDSignIn.sharedInstance.currentUser?.fetcherAuthorizer
        let query = GTLRDriveQuery_FilesList .query()
        query.q = "mimeType contains 'application/vnd.google-apps.folder'"
        
        service.executeQuery(query) { ticket, files, error in
            guard error == nil,
                  let response = files as? GTLRDrive_FileList,
                  let folders = response.files else {
                print("Error retrieving user folders from Google Drive")
                responseHandler([])
                return
            }
            
            var cloudFolders = [CloudAsset]()
            for folder in folders {
                let asset = CloudAsset()
                asset.source = .googleDrive
                asset.googleDriveFolderId = folder.identifier
                asset.googleDriveFolderName = folder.name
                cloudFolders.append(asset)
            }
            responseHandler(cloudFolders)
        }
    }
    
    func downloadPhotosFromGoogleDriveFolder(folderId: String, responseHandler: @escaping ResponseHandler<[CloudAsset]>) {
        let service = GTLRDriveService()
        service.authorizer = GIDSignIn.sharedInstance.currentUser?.fetcherAuthorizer
        
        let query = GTLRDriveQuery_FilesList.query()
        query.q = "'\(folderId)' in parents and mimeType contains 'image/'"
        
//        let query = GTLRDriveQuery_FilesList.query()
//        query.q = "'\(folderId)' in parents and mimeType contains 'image/'"
//        query.spaces = "drive"
//        query.fields = "files(id, name)"
        
        service.executeQuery(query) { ticket, files, error in
            guard error == nil,
                  let photos = files as? GTLRDrive_FileList,
                  let fileList = photos.files else {
                print("Error retrieving photos from Google Drive")
                responseHandler([])
                return
            }
            
            var cloudPhotos = [CloudAsset]()
            for file in fileList {
                let asset = CloudAsset()
                asset.source = .googleDrive
                asset.googleDriveFileId = file.identifier
                cloudPhotos.append(asset)
            }
            responseHandler(cloudPhotos)
        }
    }

    func downloadUserPhotosFromGoogleDrive(responseHandler: @escaping ResponseHandler<[CloudAsset]>) {
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
            
            var cloudPhotos = [CloudAsset]()
            for file in fileList {
                let asset = CloudAsset()
                asset.source = .googleDrive
                asset.googleDriveFileId = file.identifier
                cloudPhotos.append(asset)
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
