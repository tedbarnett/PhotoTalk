//
//  FirebaseStorageService.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 23/05/23.
//

import UIKit
import FirebaseStorage

/// FirebaseStorageService is a wrapper service class for simplying file upload and download
/// processes for Firebase Storage service
class FirebaseStorageService {
    // MARK: Private Properties

    private var environment: Environment = .dev

    // MARK: Initializers

    init(environment: Environment) {
        self.environment = environment
        print("Connecting to Firebase storage - \(self.environment.storageUrl)")
    }
}

extension FirebaseStorageService {
    
    // MARK: Public methods
    
    /**
     It attempts to upload user recorded audio to Firebase storage service.
     And responds back via completionHandler to update about success/failure status.
     */
    func uploadPhotoAudioFor(
        userId: String,
        photoId: String,
        audioUrl: URL,
        completionHandler: @escaping ResponseHandler<String?>) {
        
            let storage = Storage.storage().reference(forURL: self.environment.storageUrl)
            let photoAudioFolderRef = storage.child(PhotoAudioNodeProperties.nodeName)
            
            let audioFileNmae = photoId
            let audioFileExtension = audioUrl.pathExtension
            let newAudioFileName = "\(audioFileNmae).\(audioFileExtension)"
            let newAudioStorageReference = photoAudioFolderRef.child("\(userId)/\(newAudioFileName)")
            let _ = newAudioStorageReference.putFile(from: audioUrl, metadata: nil) { metadata, error in
                if let error = error {
                    print("[Firebase Storage]: Error uploading photo audio: \(newAudioFileName), Error: \(error.localizedDescription)")
                    completionHandler(nil)
                    return
                }
                print("[Firebase Storage]: Successfuly uploaded photo audio: \(newAudioFileName)")
                completionHandler(newAudioFileName)
            }
    }
    
    /**
     It attempts to download user recorded audio from Firebase storage service.
     And responds back via completionHandler to update about success/failure status.
     */
    func downloadPhotoAudioFor(
        userId: String,
        photoId: String,
        completionHandler: @escaping ResponseHandler<URL?>) {
            
            guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Unable to access document directory.")
                completionHandler(nil)
                return
            }
            
            let storage = Storage.storage().reference(forURL: self.environment.storageUrl)
            let photoAudioFolderRef = storage.child(PhotoAudioNodeProperties.nodeName)
            let photoAudioStorageReference = photoAudioFolderRef.child("\(userId)/\(photoId).\(AudioService.audioFileExtension)")
            
            let localAudioFileName = UUID().uuidString.appending(".\(AudioService.audioFileExtension)")
            let localAudioFileUrl = documentDirectory.appendingPathComponent(localAudioFileName)
            photoAudioStorageReference.write(toFile: localAudioFileUrl) { url, error in
                if let error = error {
                    print("[Firebase Storage]: Error downloading photo audio: \(photoId), error: \(error.localizedDescription)")
                    completionHandler(nil)
                } else {
                    print("[Firebase Storage]: Succussfully downloaded photo audio: \(photoId)")
                    completionHandler(url)
                }
            }
    }
    
    /**
     It attempts to get the list of user recorded audio  from Firebase storage service.
     And responds back via completionHandler with the list of user uploaded photo audio file names.
     */
    func getPhotoAudioFor(userId: String, completionHandler: @escaping ResponseHandler<[String]?>) {
        let storage = Storage.storage().reference(forURL: self.environment.storageUrl)
        let photoAudioFolderRef = storage.child(PhotoAudioNodeProperties.nodeName)
        let userPhotoAudioStorageReference = photoAudioFolderRef.child(userId)
        
        userPhotoAudioStorageReference.listAll { result, error in
            guard let storageListResult = result, error == nil else {
                print("[Firebase Storage]: Error downloading photo audio list for user: \(userId), error: \(error?.localizedDescription ?? "")")
                completionHandler(nil)
                return
            }
            
            print("[Firebase Storage]: Succussfully downloaded photo audio names for user: \(userId)")
            var imageNames = [String]()
            for item in storageListResult.items {
                imageNames.append(item.name)
            }
            completionHandler(imageNames)
        }
    }
    
    /*
     Connects to the Firebase storage service to delete photo audio file with given user id and name.
     And responds back via completionHandler to update about success/failure status.
     */
    func deletePhotoAudioFor(
        userId: String,
        photoId: String,
        completionHandler: @escaping ResponseHandler<Bool>) {
        
            let storage = Storage.storage().reference(forURL: self.environment.storageUrl)
            let photoAudioFolderRef = storage.child(PhotoAudioNodeProperties.nodeName)
            let photoAudioStorageReference = photoAudioFolderRef.child("\(userId)/\(photoId)")
            photoAudioStorageReference.delete { error in
                if let error = error {
                    print("[Firebase Storage]: Error deleting audio file: \(photoId), error: \(error.localizedDescription)")
                    completionHandler(false)
                } else {
                    print("[Firebase Storage]: Successfully deleted audio file: \(photoId)")
                    completionHandler(true)
                }
            }
    }
}

