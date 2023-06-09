//
//  PhotoAlbum.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 29/05/23.
//

import Foundation

/**
 PhotoAlbum data object contains details about a folder from Google drive
 */
class PhotoAlbum: Codable {
    let id: String
    let name: String
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
