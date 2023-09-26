//
//  GoogleDriveFolderSelectionView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 23/09/23.
//

import SwiftUI

/**
 GoogleDriveFolderSelectionViewDelegate delegates back change event in user selected folders
 */
protocol GoogleDriveFolderSelectionViewDelegate {
    func didChangeFolderSelection(selectedFolders: [CloudAsset])
    func didCancelFolderSelection()
}

/**
 GoogleDriveFolderSelectionView lets users select photo folders from Google drive
 and delegates back user folder selection events to the host view
 */
struct GoogleDriveFolderSelectionView: View {
    
    // MARK: Public properties
    
    var folders: [CloudAsset] = []
    var delegate: GoogleDriveFolderSelectionViewDelegate? = nil
    
    // MARK: Private properties
    
    @EnvironmentObject private var overlayContainerContext: OverlayContainerContext
    @State private var selectedFolders = [CloudAsset]()
    @State private var shouldShowProgressIndicator = false
    
    // MARK: User interface
    
    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 8) {
                
                // Action buttons
                HStack(alignment: .center, spacing: 16) {
                    Button(
                        action: {
                            self.delegate?.didCancelFolderSelection()
                        },
                        label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.clear)
                                    .frame(width: 20, height: 20)
                                Image("closeButtonIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                            }
                        }
                    )
                    
                    Spacer()
                    
                    Text(NSLocalizedString("Select Photo Album", comment: "Album selection view - Title"))
                        .font(.system(size: 16))
                        .foregroundColor(Color.white)
                    
                    Spacer()
                    
                    Button(
                        action: {
                            self.delegate?.didChangeFolderSelection(selectedFolders: self.selectedFolders)
                        },
                        label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.clear)
                                    .frame(width: 20, height: 20)
                                Text(NSLocalizedString("Done", comment: "Common - Done button title"))
                                    .font(.system(size: 18))
                                    .foregroundColor(Color.blue)
                            }
                        }
                    )
                }
                
                // Folder list view
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(self.folders, id: \.self.id) { folder in
                            GoogleDriveFolderView(folder: folder, delegate: self)
                        }
                    }
                }
                .padding(.top, 16)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            if self.shouldShowProgressIndicator {
                HStack {
                    ActivityIndicator(isAnimating: .constant(true), style: .large)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .background(Color.black.opacity(0.6))
                .edgesIgnoringSafeArea(.all)
            }
        }
        .onAppear {
            self.getSelectedFolders()
        }
    }
    
    // MARK: - Private methods
    
    private func getSelectedFolders() {
        for folder in self.folders where folder.isSelected {
            self.selectedFolders.append(folder)
        }
    }
}

// MARK: - GoogleDriveFolderViewDelegate delegate methods

extension GoogleDriveFolderSelectionView: GoogleDriveFolderViewDelegate {
    func didTapOn(folder: CloudAsset, responseHandler: @escaping ResponseHandler<[CloudAsset]?>) {
        self.shouldShowProgressIndicator = true
        let service = UserPhotoService()
        service.downloadSubfoldersIfAnyForGoogleDriveFolder(folder) { folders in
            self.shouldShowProgressIndicator = false
            guard let subFolders = folders, !subFolders.isEmpty else {
                responseHandler(nil)
                return
            }
            
            folder.googleDriveSubfolders = subFolders
            responseHandler(subFolders)
        }
    }
    
    func didChangeFolderSelection(folder: CloudAsset) {
        if folder.isSelected {
            if self.selectedFolders.first(where: {$0.id == folder.id}) == nil {
                self.selectedFolders.append(folder)
            }
        } else {
            if let index = self.selectedFolders.firstIndex(where: {$0.id == folder.id}) {
                self.selectedFolders.remove(at: index)
            }
        }
    }
}
