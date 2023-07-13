//
//  String + Date.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 13/07/23.
//

import Foundation

extension String {
    
    /**
     Returns date object from formatted date/time string valuefor user photo
     */
    var photoNodeDateFromString: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = PhotoNodeProperties.dateAndTimeFormat
        let date = dateFormatter.date(from: self)
        return date
    }
}
