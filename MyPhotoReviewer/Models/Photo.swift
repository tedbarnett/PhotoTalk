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
    let name: String = ""
    let extnsion: String = ""
    let url: String = ""
    let dateAndTime: Date? = nil
    let location: PhotoLocation? = nil
    let audio: PhotoAudio? = nil
}
