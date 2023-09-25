//
//  GoogleDriveFolderView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 23/09/23.
//

import SwiftUI

/**
 GoogleDriveFolderViewDelegate delegates back user selection/deselection action to the host view
 */
protocol GoogleDriveFolderViewDelegate {
    func didTapOn(folder: CloudAsset, responseHandler: @escaping ResponseHandler<[CloudAsset]?>)
}

/**
 GoogleDriveFolderView presents details about a Google drive folder and provides user
 interaction to see sub folders (if any) and select/deselect folder
 */
struct GoogleDriveFolderView: View {
    
    // MARK: Public properties
    
    var folder: CloudAsset
    var delegate: GoogleDriveFolderViewDelegate?
    
    // MARK: Private properties
    
    @State private var subFolders: [CloudAsset]?
    @State private var isSubfolder: Bool = false
    @State private var isSelected = false
    @State private var isExpanded = false
    
    /*
     Returns title of the folder
     */
    private var albumTitle: String {
        if let title = self.folder.googleDriveFolderName {
            return title
        }
        return ""
    }
    
    // MARK: User interface
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            
            // Folder details - icon, name, date, etc
            HStack(alignment: .center, spacing: 12) {
                Image("folderIcon")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .tint(Color.gray600)
                    .frame(width: 20, height: 20)
                
                Text(self.albumTitle)
                    .font(.system(size: 14, weight: .regular))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(Color.offwhite100)
                
                Spacer()
                
                // Selection icon
                if self.isSelected {
                    Image("selectedIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
                
                // Expand/Collapse button
                if self.subFolders != nil {
                    Button(
                        action: {
                            self.isExpanded.toggle()
                        },
                        label: {
                            ZStack {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 40, height: 40)
                                Image(self.isExpanded ? "downArrow" : "rightArrow")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .tint(Color.offwhite100)
                                    .animation(nil, value: self.isExpanded)
                            }
                        }
                    )
                }
            }
            
            // Sub folders list
            if let subFolders = self.subFolders, self.isExpanded {
                Rectangle()
                    .stroke(Color.gray600, lineWidth: 1)
                    .frame(height: 1)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(subFolders, id: \.self.id) { folder in
                            GoogleDriveFolderView(folder: folder, delegate: self.delegate)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, self.isSubfolder ? 0 : 10)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray900)
        }
        .onTapGesture {
            guard let folders = self.folder.googleDriveSubfolders else {
                self.delegate?.didTapOn(folder: self.folder) { folders in
                    guard let subFolders = folders, !subFolders.isEmpty else {
                        self.isSelected = true
                        self.folder.isSelected = true
                        return
                    }
                    self.addToSubfolders(folders: subFolders)
                }
                return
            }
            self.addToSubfolders(folders: folders)
        }
        .onAppear {
            self.isSelected = self.folder.isSelected
            self.isSubfolder = self.folder.isSubfolder
        }
    }
    
    // MARK: - Private methods
    
    private func addToSubfolders(folders: [CloudAsset]) {
        self.isSelected = false
        self.folder.isSelected = false
        
        for folder in folders {
            folder.isSubfolder = true
        }
        
        self.subFolders = [CloudAsset]()
        self.subFolders?.append(contentsOf: folders)
        self.isExpanded = true
    }
}
