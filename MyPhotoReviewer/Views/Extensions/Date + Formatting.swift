//
//  Date + Formatting.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 13/07/23.
//

import Foundation

extension Date {
    
    /**
     Returns formatted date string for user photo date/time value
     */
    var photoNodeFormattedDateAndTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = PhotoNodeProperties.dateAndTimeFormat
        let photoDateString = formatter.string(from: self)
        return photoDateString
    }
    
    /**
     Returns formatted date string for user photo date/time value
     */
    var photoNodeFormattedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = PhotoNodeProperties.dateFormat
        let photoDateString = formatter.string(from: self)
        return photoDateString
    }
    
    /**
     Returns date and time stamp to be used for file name
     */
    var dateTimeStampForFileName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dMy_hhmm"
        let photoDateString = formatter.string(from: self)
        return photoDateString
    }
}
