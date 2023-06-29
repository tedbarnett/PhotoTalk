//
//  PhotoAudio.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 29/05/23.
//

import Foundation

/**
 PhotoAudio data object contains details about the user recorded audio attached to a photo
 */
class PhotoAudio: Codable {
    let id: String
    let photoId: String
    let url: String
    let recordedDate: String
    
    init(id: String, photoId: String, url: String, recordedDate: String) {
        self.id = id
        self.photoId = photoId
        self.url = url
        self.recordedDate = recordedDate
    }
}
