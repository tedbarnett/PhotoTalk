//
//  Photo.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 29/05/23.
//

import UIKit

/**
 Photo data object contains details about each user photos
 */
class Photo {
    var id: String = ""
    let url: String = ""
    var dateAndTime: Date? = nil
    var isFavourite: Bool = false
    var location: String? = nil
    var audioUrl: URL? = nil
    var image: UIImage? = nil
    
    var hasSomeDetailToShow: Bool {
        return self.location != nil || self.audioUrl != nil || self.dateAndTime != nil
    }
}
