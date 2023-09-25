//
//  ICloudAlbumView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 09/06/23.
//

import SwiftUI

/**
 ICloudAlbumViewDelegate delegates back user selection/deselection action to the host view
 */
protocol ICloudAlbumViewDelegate {
    func didChangeSelection(isSelected: Bool, album: CloudAsset)
}

/**
 ICloudAlbumView shows iCloud album graphics and name
 */
struct ICloudAlbumView: View {
    
    // MARK: Public properties
    
    var album: CloudAsset
    var delegate: ICloudAlbumViewDelegate?
    
    // MARK: Private properties
    
    @State private var isSelected = false
    
    /*
     Returns title of the photo album
     */
    private var albumTitle: String {
        if let title = self.album.iCloudAlbumTitle {
            return title
        }
        return ""
    }
    
    // MARK: User interface
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .center, spacing: 0) {
                
                if let image = self.album.iCloudAlbumPreviewImage {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black300)
                            .frame(width:125, height: 125)
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width:110, height: 110)
                    }
                    .padding(.bottom, 4)
                } else {
                    Image("folderIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width:125, height: 125)
                }
                
                Text(self.albumTitle)
                    .font(.system(size: 14, weight: .regular))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(Color.offwhite100)
            }
            .padding(.all, 5)
            
            if self.isSelected {
                Image("selectedIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .padding(.all, 10)
            }
        }
        .onTapGesture {
            self.isSelected.toggle()
            self.delegate?.didChangeSelection(isSelected: self.isSelected, album: self.album)
        }
        .onAppear {
            self.isSelected = self.album.isSelected
        }
    }
}
