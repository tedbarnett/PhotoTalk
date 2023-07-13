//
//  Photo.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 29/05/23.
//

import Foundation

/**
 Photo data object contains details about each user photos
 */
class Photo {
    var id: String = ""
    let photoAlbumId: String? = nil
    let url: String = ""
    var dateAndTime: Date? = nil
    var location: String? = nil
    let audio: PhotoAudio? = nil
}
