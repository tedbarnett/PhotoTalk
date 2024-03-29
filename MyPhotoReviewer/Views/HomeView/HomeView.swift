//
//  HomeView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 22/04/23.
//

import SwiftUI

/**
 HomeView is the main view shown to the user after successful user authentication.
 It presents UI/UX for user to select source of images (Google drive, Apple iCloud, etc), presents
 list of images and their preview.
 
 It also provides the tools for adding details to the image like location,date, time, audio annotation, etc.
 */
struct HomeView: View {
    
    // MARK: Private properties
    
    @EnvironmentObject private var appContext: AppContext
    @EnvironmentObject private var userProfile: UserProfileModel
    @EnvironmentObject private var overlayContainerContext: OverlayContainerContext
    
    @StateObject private var authenticationViewModel = UserAuthenticationViewModel()
    @StateObject private var viewModel = HomeViewModel()
    
    @State private var shouldShowHelpView = false
    @State private var shouldShowFolderSelectionView = false
    @State private var shouldShowPhotoDetails = false
    @State private var shouldShowPhotoSlideShowView = false
    @State private var selectedPhoto: CloudAsset?
    @State private var didAttemptToDownloadAssets: Bool = false
    @State private var draggedPhoto: CloudAsset?
    
    // MARK: User interface
    
    var body: some View {
        NavigationView {
            ZStack {
                
                // Background
                Color.black900
                    .ignoresSafeArea()
                
                // Content View
                VStack {
                    ZStack {
                        // Title text
                        Text(NSLocalizedString("My Photo Memories", comment: "Photo reviewer view - title"))
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(Color.offwhite100)
                        
                        HStack {
                            Spacer()
                            Menu {
                                // Add photo album button
                                Button(
                                    action: {
                                        self.viewModel.setFoldersAsSelectedIfAny()
                                        self.shouldShowFolderSelectionView = true
                                    },
                                    label: {
                                        Text(
                                            NSLocalizedString("Add Photo Album",
                                                              comment: "Home view - Add photo selection")
                                        )
                                        .font(.system(size: 16))
                                        .foregroundColor(self.didAttemptToDownloadAssets && !self.viewModel.photos.isEmpty ? Color.white : .gray900)
                                    }
                                )
                                .disabled(!self.didAttemptToDownloadAssets && self.viewModel.folders.isEmpty)
                                
                                // Start slide show button
                                Button(
                                    action: {
                                        guard !self.viewModel.photosIncludedInSlideShowByUser.isEmpty else { return }
                                        self.shouldShowPhotoSlideShowView = true
                                    },
                                    label: {
                                        Text(
                                            NSLocalizedString("Start Slide Show",
                                                              comment: "Home view - Start photo slide show button title")
                                        )
                                        .font(.system(size: 16))
                                        .foregroundColor(self.didAttemptToDownloadAssets && !self.viewModel.photos.isEmpty && self.userProfile.didAddPhotosToSlideShow ? Color.white : .gray900)
                                    }
                                )
                                .disabled(!self.didAttemptToDownloadAssets && self.viewModel.photos.isEmpty && !self.userProfile.didUpdatePhotoDetails)
                                
                                Button(NSLocalizedString("Help and FAQ", comment: "Menu option - Help and FAQ"), action: {
                                    self.shouldShowHelpView = true
                                })
                                
                                Button(NSLocalizedString("Logout", comment: "Menu option - Logout"), action: {
                                    self.overlayContainerContext.shouldShowProgressIndicator = true
                                    self.authenticationViewModel.logutUser { didLogoutSuccessfully in
                                        self.overlayContainerContext.shouldShowProgressIndicator = false
                                        guard didLogoutSuccessfully else {
                                            return
                                        }
                                        self.userProfile.isAuthenticated = false
                                    }
                                })
                                
                            } label: {
                                Image("hamburgerIcon")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .tint(Color.offwhite100)
                                    .frame(width: 25, height: 25)
                            }
                        }
                        .padding(.horizontal, UIDevice.isIpad ? 40 : 16)
                    }
                    
                    Spacer()
                    
                    // Displaying media source selection options, if there are no user photos/albums
                    if !self.userProfile.didAllowPhotoAccess { // || self.viewModel.photos.isEmpty
                        VStack(alignment: .center, spacing: 24) {
                            Text(NSLocalizedString(
                                "Where are your photos stored? Please select from the following options:",
                                comment: "Home view - Media source selection description")
                            )
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color.offwhite100)
                            .padding(.bottom, 24)
                            
                            if UIDevice.isIpad {
                                HStack(alignment: .center, spacing: 40) {
                                    ForEach(MediaSource.allCases, id: \.self) { mediaSource in
                                        MediaSourceSelectionButton(
                                            mediaSource: mediaSource,
                                            width: UIScreen.main.bounds.width * 0.2,
                                            tapActionHandler: { mediaSource in
                                                self.userProfile.mediaSource = mediaSource
                                                self.viewModel.userProfile = self.userProfile
                                                self.viewModel.saveUserDetailsToDatabase { _ in
                                                    self.presentMediaSelectionConsent(for: mediaSource)
                                                }
                                            }
                                        )
                                    }
                                }
                            } else {
                                VStack(alignment: .center, spacing: 24) {
                                    ForEach(MediaSource.allCases, id: \.self) { mediaSource in
                                        MediaSourceSelectionButton(
                                            mediaSource: mediaSource,
                                            width: UIScreen.main.bounds.width * 0.4,
                                            tapActionHandler: { mediaSource in
                                                self.userProfile.mediaSource = mediaSource
                                                self.viewModel.userProfile = self.userProfile
                                                self.viewModel.saveUserDetailsToDatabase { _ in
                                                    self.presentMediaSelectionConsent(for: mediaSource)
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        Spacer()
                    }
                    
                    // Displaying user photos with details, if user photos/album details are saved in database
                    else if !self.viewModel.photos.isEmpty {
                        VStack(alignment: .leading, spacing: 24) {
                            ScrollView(.vertical, showsIndicators: false) {
                                LazyVGrid(columns: self.viewModel.photoGridColumns, spacing: 3) {
                                    ForEach(self.viewModel.filteredPhotos, id: \.self.id) { photo in
                                        PhotoView(
                                            currentSlideIndex: .constant(0),
                                            index: 0,
                                            photo: photo,
                                            width: self.viewModel.photoGridColumnWidth,
                                            height: self.viewModel.photoGridColumnWidth,
                                            isPresentedAsThumbnail: true
                                        )
                                        .onTapGesture {
                                            photo.isDownloaded = false
                                            self.selectedPhoto = photo
                                            self.shouldShowPhotoDetails = true
                                        }
                                        .onDrag({
                                            self.draggedPhoto = photo
                                            return NSItemProvider()
                                        })
                                        .onDrop(
                                            of: [.item],
                                            delegate: DropViewDelegate(
                                                destinationPhoto: photo,
                                                photos: self.$viewModel.photos,
                                                draggedPhoto: self.$draggedPhoto
                                            )
                                        )
                                        .onChange(of: viewModel.photos) { photos in
                                            if self.viewModel.isCheckboxSelectedToShowOnlySlideShowPhotos {
                                                let idsOfUpdatedPhotos = self.viewModel.localStorageService.idsOfUpdatedPhotosByUser
                                                let slideShowPhotos = photos.filter({
                                                    guard let photoId = $0.photoId else { return false }
                                                    return idsOfUpdatedPhotos.contains(photoId)
                                                })
                                                self.viewModel.filteredPhotos = slideShowPhotos
                                            } else {
                                                self.viewModel.filteredPhotos = photos
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            CheckboxView(
                                title: NSLocalizedString("Show only slide show photos", comment: "Home view - show only slide show photo"),
                                delegate: self
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    } else if self.didAttemptToDownloadAssets, let selectedFolders = self.viewModel.selectedFolders, !selectedFolders.isEmpty, self.viewModel.photos.isEmpty {
                        Text(NSLocalizedString("No photos found in the selected photo albums, please select different albums", comment: "Home view - no photos found"))
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color.gray600)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.top, UIDevice.isIpad ? 40 : 20)
                
                // Link to photo details view
                NavigationLink(
                    destination:
                        PhotoDetailsView(
                            photos: self.viewModel.filteredPhotos,
                            selectedPhoto: self.selectedPhoto
                        )
                        .navigationBarHidden(true)
                    ,
                    isActive: self.$shouldShowPhotoDetails
                ) { EmptyView() }
                
                
                // Link to photo slide view
                NavigationLink(
                    destination:
                        PhotoSlideShowView(
                            photoAssets: self.viewModel.photosIncludedInSlideShowByUser,
                            selectedPhotoAsset: nil
                        )
                        .navigationBarHidden(true)
                    ,
                    isActive: self.$shouldShowPhotoSlideShowView
                ) { EmptyView() }
            }
        }
        .navigationBarHidden(true)
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            self.initializeViewModels()
            self.viewModel.loadIdsOfUpdatedPhotos()
            self.viewModel.loadIdsOfPhotosThoseAreIncludedInSlideShow()
            self.loadUserDetails()
        }
        .onChange(of: self.viewModel.shouldShowProgressIndicator) { shouldShowProgressIndicator in
            self.overlayContainerContext.shouldShowProgressIndicator = shouldShowProgressIndicator
        }
        .onChange(of: self.viewModel.shouldShowFolderSelectionView) { shouldShow in
            self.shouldShowFolderSelectionView = shouldShow
        }
        .sheet(isPresented: self.$shouldShowFolderSelectionView) {
            if self.userProfile.mediaSource == .iCloud {
                ICloudAlbumSelectionView(
                    albums: self.viewModel.folders,
                    delegate: self
                )
            } else if self.userProfile.mediaSource == .googleDrive {
                GoogleDriveFolderSelectionView(
                    folders: self.viewModel.folders,
                    delegate: self
                )
            }
        }
        .sheet(isPresented: self.$shouldShowHelpView) {
            HelpView()
        }
    }
    
    // MARK: Private methods
    
    private func initializeViewModels() {
        self.viewModel.currentEnvironment = self.appContext.currentEnvironment
        self.viewModel.userProfile = self.userProfile
        self.authenticationViewModel.userProfile = self.userProfile
    }
    
    private func loadUserDetails() {
        self.overlayContainerContext.shouldShowProgressIndicator = true
        self.viewModel.loadUserDetailsFromDatabase { didLoadDetails in
            self.overlayContainerContext.shouldShowProgressIndicator = false
            self.viewModel.loadUserFoldersFromDatabaseIfAny()
            
            guard let mediaSource = self.userProfile.mediaSource,
                  self.userProfile.didAllowPhotoAccess else {
                return
            }
            
            // Empty viewModel.folders means that the app has been installed fresh
            // So instead of loading user assets, we need to present media selection consent.
            if self.viewModel.folders.isEmpty {
                self.presentMediaSelectionConsent(for: mediaSource)
            }
            // For non-empty viewModel.folders, this means that the user had previously
            // given media consent, so we can proceed with presenting album selection view
            else {
                self.loadCloudAssets()
            }
        }
    }
    
    private func loadCloudAssets() {
        guard let mediaSource = self.userProfile.mediaSource,
              self.userProfile.didAllowPhotoAccess else {
            return
        }
        self.overlayContainerContext.shouldShowProgressIndicator = true
        self.viewModel.downloadCloudAssets(for: mediaSource) { _ in
            self.didAttemptToDownloadAssets = true
            self.overlayContainerContext.shouldShowProgressIndicator = false
            self.viewModel.checkIfAnyOfTheLoadedPhotosUpdatedByUser()
        }
    }
    
    private func presentMediaSelectionConsent(for mediaSource: MediaSource) {
        if self.userProfile.didAllowPhotoAccess {
            self.loadCloudAssets()
        }
        else {
            self.viewModel.presentMediaSelectionConsent(for: mediaSource) { didAllow in
                self.userProfile.didAllowPhotoAccess = didAllow
                guard didAllow else { return }
                self.loadCloudAssets()
            }
        }
    }
}

// MARK: FolderSelectionViewDelegate delegate methods

extension HomeView: ICloudAlbumSelectionViewDelegate {
    func didCancelAlbumSelection() {
        self.shouldShowFolderSelectionView = false
    }
    
    func didChangeAlbumSelection(selectedAlbums: [CloudAsset]) {
        self.didAttemptToDownloadAssets = false
        self.shouldShowFolderSelectionView = false
        self.overlayContainerContext.shouldShowProgressIndicator = true
        self.viewModel.downloadPhotosFromICloudAlbums(selectedAlbums) { didLoadPhotos in
            self.overlayContainerContext.shouldShowProgressIndicator = false
            self.didAttemptToDownloadAssets = true
            self.viewModel.checkIfAnyOfTheLoadedPhotosUpdatedByUser()
        }
    }
}

// MARK: GoogleDriveFolderSelectionViewDelegate delegate methods

extension HomeView: GoogleDriveFolderSelectionViewDelegate {
    func didCancelFolderSelection() {
        self.shouldShowFolderSelectionView = false
    }
    
    func didChangeFolderSelection(selectedFolders: [CloudAsset]) {
        self.didAttemptToDownloadAssets = false
        self.shouldShowFolderSelectionView = false
        self.overlayContainerContext.shouldShowProgressIndicator = true
        self.viewModel.downloadPhotosFromGoogleDriveFolders(selectedFolders) { didLoadPhotos in
            self.overlayContainerContext.shouldShowProgressIndicator = false
            self.didAttemptToDownloadAssets = true
            self.viewModel.checkIfAnyOfTheLoadedPhotosUpdatedByUser()
        }
    }
}

// MARK: - CheckboxViewDelegate methods

extension HomeView: CheckboxViewDelegate {
    func didChangeSelection(isSelected: Bool) {
        self.viewModel.filterPhotosBasedOnCheckBoxSelectionChange(isSelected: isSelected)
    }
}
