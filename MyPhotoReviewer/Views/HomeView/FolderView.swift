//
//  FolderView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 09/06/23.
//

import SwiftUI

/**
 FolderViewDelegate delegates back user selection/deselection action to the host view
 */
protocol FolderViewDelegate {
    func didChangeSelection(isSelected: Bool, folder: CloudAsset)
}

/**
 FolderView shows folder graphics and name
 */
struct FolderView: View {
    
    // MARK: Public properties
    
    var folder: CloudAsset
    var delegate: FolderViewDelegate?
    
    // MARK: Private properties
    
    @State private var isSelected = false
    
    /*
     Returns title of the Google drive folder or iCloud photo album
     */
    private var folderTitle: String {
        if let gDriveFolderTitle = folder.googleDriveFolderName {
            return gDriveFolderTitle
        } else if let iCloudAlbumTitle = folder.iCloudAlbumTitle {
            return iCloudAlbumTitle
        }
        return ""
    }
    
    // MARK: User interface
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .center, spacing: 0) {
                
                if let image = self.folder.iCloudAlbumPreviewImage {
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
                
                Text(self.folderTitle)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color.offwhite100)
            }
            .padding(.all, 10)
            
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
            self.delegate?.didChangeSelection(isSelected: self.isSelected, folder: self.folder)
        }
        .onAppear {
            self.isSelected = self.folder.isSelected
        }
    }
}

struct FolderView_Previews: PreviewProvider {
    static var asset: CloudAsset {
        let asset = CloudAsset()
        asset.googleDriveFolderName = "Folder"
        return asset
    }
    
    static var previews: some View {
        FolderView(folder: self.asset)
    }
}
