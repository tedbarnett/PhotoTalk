//
//  PhotoAlbum.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 29/05/23.
//

import Foundation

/**
 PhotoAlbum data object contains details about a collection of photos
 */
class PhotoAlbum: Hashable {
    let id: String = ""
    let name: String = ""
    let url: String? = nil
    let photos: [Photo] = []
    
    static func == (lhs: PhotoAlbum, rhs: PhotoAlbum) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
