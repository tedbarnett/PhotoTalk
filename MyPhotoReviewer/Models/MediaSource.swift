//
//  MediaSource.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 29/05/23.
//

import Foundation

/**
 MediaSource enumeration defines the different media sources available - iCloud, Google Drive, photos (local photos)
 */
enum MediaSource: String, CaseIterable {
    case iCloud, googleDrive, photos
    
    // MARK: Public properties
    
    var icon: String {
        switch self {
        case .iCloud: return "iCloudIcon"
        case .googleDrive: return "googleDriveIcon"
        case .photos: return "photosIcon"
        }
    }
    
    var name: String {
        switch self {
        case .iCloud: return NSLocalizedString("Apple iCloud", comment: "Media source - icloud name")
        case .googleDrive: return NSLocalizedString("Google Drive", comment: "Media source - google drive name")
        case .photos: return NSLocalizedString("Photos", comment: "Media source - photos name")
        }
    }
}
