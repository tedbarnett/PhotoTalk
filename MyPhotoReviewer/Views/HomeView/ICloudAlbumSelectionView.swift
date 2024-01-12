//
//  ICloudAlbumSelectionView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 09/06/23.
//

import SwiftUI

/**
 ICloudAlbumSelectionViewDelegate delegates back change event in user selected albums
 */
protocol ICloudAlbumSelectionViewDelegate {
    func didChangeAlbumSelection(selectedAlbums: [CloudAsset])
    func didCancelAlbumSelection()
}

/**
 ICloudAlbumSelectionView lets users select photo albums from the photo gallery and icloud
 and delegates back user album selection event to the host view
 */
struct ICloudAlbumSelectionView: View {
    
    // MARK: Public properties
    
    var albums: [CloudAsset] = []
    var delegate: ICloudAlbumSelectionViewDelegate? = nil
    
    // MARK: Private properties
    @State private var selectedAlbums = [CloudAsset]()
    
    private var columns: [GridItem] {
        let itemCount = UIDevice.isIpad ? 6 : 3
        var gridItems = [GridItem]()
        for _ in 0..<itemCount {
            gridItems.append(GridItem(.flexible()))
        }
        return gridItems
    }
    
    // MARK: User interface
    
    init(albums: [CloudAsset], delegate: ICloudAlbumSelectionViewDelegate? = nil) {
        self.albums = albums
        self.delegate = delegate
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            
            // Action buttons
            HStack(alignment: .center, spacing: 16) {
                Button(
                    action: {
                        self.delegate?.didCancelAlbumSelection()
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
                
                if !self.albums.isEmpty {
                    Button(
                        action: {
                            let albums = self.albums.filter { $0.isSelected == true }
                            self.delegate?.didChangeAlbumSelection(selectedAlbums: albums)
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
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Albums list
            if !self.albums.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: self.columns, spacing: 4) {
                        ForEach(self.albums, id: \.self) { album in
                            ICloudAlbumView(album: album, delegate: self)
                        }
                    }
                    .padding()
                }
            } else {
                Text(NSLocalizedString("You don't have photo album/s to select.", comment: "Album selection view - No photo albums"))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color.gray600)
                    .frame(maxHeight: .infinity, alignment: .center)
                    .padding(.horizontal, 16)
                Spacer()
            }
        }
    }
}

// MARK: FolderViewDelegate delegate methods
extension ICloudAlbumSelectionView: ICloudAlbumViewDelegate {
    func didChangeSelection(isSelected: Bool, album: CloudAsset) {
        album.isSelected = isSelected
    }
}
