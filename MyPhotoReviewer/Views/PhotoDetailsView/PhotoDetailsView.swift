//
//  PhotoDetailsView.swift
//  MyPhotoReviewer-Development
//
//  Created by Prem Pratap Singh on 15/06/23.
//

import SwiftUI

/**
 PhotoDetailsView presents larger view of the user photo and details added to it.
 This view also provides UI/UX for adding/editing photo details like location, date, audio, etc
 */
struct PhotoDetailsView: View {
    
    // MARK: Public properties
    
    var photo: CloudAsset?
    
    // MARK: Private properties
    
    @SwiftUI.Environment(\.presentationMode) private var presentationMode
    
    // MARK: User interface
    
    var body: some View {
        ZStack {
            // Background
            Color.black900
                .ignoresSafeArea()
            
            // Header
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button(
                        action: {
                            self.presentationMode.wrappedValue.dismiss()
                        },
                        label: {
                            ZStack {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 40, height: 40)
                                Image("leftArrowIcon")
                                    .renderingMode(.template)
                                    
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 9, height: 16)
                                    .tint(.white)
                            }
                        }
                    )
                    Spacer()
                }
                
                // Main content view
                
                if let photo = self.photo {
                    PhotoView(
                        photo: photo,
                        width: UIScreen.main.bounds.width - 48,
                        height: UIScreen.main.bounds.height * 0.8,
                        forcePhotoDownload: true
                    )
                }
                
                Spacer()
                
            }
            .padding(.horizontal, 24)
        }
    }
}
