//
//  FolderSelectionView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 09/06/23.
//

import SwiftUI

/**
 FolderSelectionViewDelegate delegates back change event in user selected folder selection
 */
protocol FolderSelectionViewDelegate {
    func didChangeFolderSelection(selectedFolders: [CloudAsset])
    func didCancelFolderSelection()
}

/**
 FolderSelectionView lets users select folders from a grid of user Google drive folders
 and delegates back user folder selection event to the host view
 */
struct FolderSelectionView: View {
    
    // MARK: Public properties
    
    var folders: [CloudAsset] = []
    var delegate: FolderSelectionViewDelegate? = nil
    
    // MARK: Private properties
    
    @State private var selectedFolders = [CloudAsset]()
    
    private var columns: [GridItem] {
        let itemCount = UIDevice.isIpad ? 4 : 2
        var gridItems = [GridItem]()
        for _ in 0..<itemCount {
            gridItems.append(GridItem(.flexible()))
        }
        return gridItems
    }
    
    // MARK: User interface
    
    init(folders: [CloudAsset], delegate: FolderSelectionViewDelegate? = nil) {
        self.folders = folders
        self.delegate = delegate
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            
            // Folders list
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: self.columns, spacing: 16) {
                    ForEach(self.folders, id: \.self) { folder in
                        FolderView(folder: folder, delegate: self)
                    }
                }
                .padding()
            }
            
            // Action buttons
            HStack(alignment: .center, spacing: 16) {
                Button(
                    action: {
                        self.delegate?.didCancelFolderSelection()
                    },
                    label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray200)
                                .frame(height: 40)
                            Text(NSLocalizedString("Cancel", comment: "Common - Cancel button title"))
                                .font(.system(size: 16))
                                .foregroundColor(Color.black)
                        }
                    }
                )
                
                Button(
                    action: {
                        self.delegate?.didChangeFolderSelection(selectedFolders: self.selectedFolders)
                    },
                    label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue)
                                .frame(height: 40)
                            Text(NSLocalizedString("Done", comment: "Common - Done button title"))
                                .font(.system(size: 16))
                                .foregroundColor(Color.white)
                        }
                    }
                )
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: FolderViewDelegate delegate methods
extension FolderSelectionView: FolderViewDelegate {
    func didChangeSelection(isSelected: Bool, folder: CloudAsset) {
        if isSelected {
            if self.selectedFolders.first(where: { $0.id == folder.id }) == nil {
                self.selectedFolders.append(folder)
            }
        } else {
            if let index = self.selectedFolders.firstIndex(where: { $0.id == folder.id }) {
                self.selectedFolders.remove(at: index)
            }
        }
    }
}


struct FolderSelectionView_Previews: PreviewProvider {
    static var folders: [CloudAsset] {
        var assets = [CloudAsset]()
        for i in 0..<100 {
            let asset = CloudAsset()
            asset.googleDriveFolderName = "Folder \(i)"
            assets.append(asset)
        }
        return assets
    }
    
    static var previews: some View {
        FolderSelectionView(folders: self.folders)
    }
}
