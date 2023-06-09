//
//  FolderView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 09/06/23.
//

import SwiftUI

/**
 FolderViewDelegate delegates back user action to the parent view
 */
protocol FolderViewDelegate {
    func didSelectFolder(_ folder: CloudAsset)
}

/**
 FolderView shows folder graphics and name
 */
struct FolderView: View {
    
    // MARK: Public properties
    
    var folder: CloudAsset
    var delegate: FolderViewDelegate?
    
    // MARK: User interface
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.clear)
            
            VStack(alignment: .center, spacing: 16) {
                Image("folderIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width:150, height: 150)
                if let folderName = self.folder.googleDriveFolderName {
                    Text(folderName)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color.white)
                }
            }
            .padding(.all, 10)
        }
        .onTapGesture {
            self.delegate?.didSelectFolder(self.folder)
        }
    }
}

