//
//  UIDevice + ScreenSize.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 04/05/23.
//

import UIKit

extension UIDevice {
    
    /// Boolean flag indicating if the iPhone screen size is small
    static var hasSmallScreen: Bool {
        // iPhone 5/5S/5C have screen height of 1136
        // iPhone 6/6S/7/8 have screen height of 1334
        let screenHeight = UIScreen.main.nativeBounds.height
        return screenHeight >= 1136 && screenHeight <= 1334
    }
    
    /// Boolean flag indicating if the device is an iPad
    static var isIpad: Bool {
        let deviceIdiom = UIScreen.main.traitCollection.userInterfaceIdiom
        return deviceIdiom == .pad
    }
}
