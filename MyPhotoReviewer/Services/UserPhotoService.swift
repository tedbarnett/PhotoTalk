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
    
    func downloadUserPhotosFromICloud(responseHandler: @escaping ResponseHandler<[CloudAsset]>) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        var cloudPhotos = [CloudAsset]()
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        fetchResult.enumerateObjects { asset, _, _ in
            let id = asset.localIdentifier
            var photo = CloudAsset()
            photo.source = .iCloud
            photo.iCloudAssetId = asset.localIdentifier
            photo.width = asset.pixelWidth
            photo.height = asset.pixelHeight
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
