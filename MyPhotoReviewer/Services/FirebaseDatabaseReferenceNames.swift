//
//  FirebaseDatabaseReferenceNames.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 29/05/23.
//

import Foundation

/**
 DatabaseNodeCommonProperties defines common property names used
 for different nodes in Firebase Database.
 */
struct DatabaseNodeCommonProperties {
    static let id = "id"
    static let photoId = "userId"
    static let name = "name"
    static let url = "url"
}

/**
 UserNodeProperties defines useer node name and its properties used in the database.
 These names are used to get references of actual database nodes.
 */
struct UserNodeProperties {
    static let nodeName = "User"
    static let email = "email"
    static let authenticationServiceProvider = "authenticationServiceProvider"
    static let mediaSource = "mediaSource"
}

/**
 PhotoAlbumNodeProperties defines photo album node name and its properties used in the database.
 These names are used to get references of actual database nodes.
 */
struct PhotoAlbumNodeProperties {
    static let nodeName = "PhotoAlbum"
    static let photoIds = "photoIds"
}

/**
 PhotoNodeProperties defines photo node name and its properties used in the database.
 These names are used to get references of actual database nodes.
 */
struct PhotoNodeProperties {
    static let nodeName = "Photo"
    static let photoAlbumId = "photoAlbumId"
    static let extnsion = "extnsion"
    static let dateAndTime = "dateAndTime"
    static let location = "location"
    static let audio = "audio"
}

/**
 PhotoAudioNodeProperties defines photo audio node name and its properties used in the database.
 These names are used to get references of actual database nodes.
 */
struct PhotoAudioNodeProperties {
    static let nodeName = "PhotoAudio"
    static let recordedDate = "recordedDate"
}

/**
 PhotoLocationNodeProperties defines photo location node name and its properties used in the database.
 These names are used to get references of actual database nodes.
 */
struct PhotoLocationNodeProperties {
    static let nodeName = "PhotoLocation"
    static let longitude = "longitude"
    static let latitude = "latitude"
}
