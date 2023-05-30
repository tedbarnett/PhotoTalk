//
//  MediaSourceSelectionButton.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 30/05/23.
//

import SwiftUI

/**
 MediaSourceSelectionButton presents UI for the media source selection button and
 also handles user interaction
 */
struct MediaSourceSelectionButton: View {
    
    // MARK: Public properties
    
    var mediaSource: MediaSource
    var width: CGFloat
    var tapActionHandler: ResponseHandler<MediaSource>?
    
    // MARK: User interface
    
    var body: some View {
        Button(
            action: {
                self.tapActionHandler?(self.mediaSource)
            },
            label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black600)
                        .frame(width: self.width, height: self.width)
                        .shadow(color: Color.offwhite100.opacity(0.2), radius: 5, x: 0, y: 0)
                    
                    VStack(alignment: .center, spacing: 16) {
                        Image(self.mediaSource.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: self.width * 0.6, height: self.width * 0.6)
                        Text(self.mediaSource.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.offwhite100)
                    }
                }
            }
        )
    }
}
