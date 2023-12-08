//
//  AddPhotoDetailsView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 07/07/23.
//

import SwiftUI

/**
 AddPhotoDetailsViewMode enumeration defines the type of details to be added
 with AddPhotoDetailsView
 */
enum AddPhotoDetailsViewMode {
    case addLocation, addDate
    
    // MARK: Public properties
    
    var title: String {
        switch self {
        case .addLocation:
            return NSLocalizedString(
                "Adjust Location",
                comment: "Add photo details view - Add location title"
            )
        case .addDate:
            return NSLocalizedString(
                "Adjust Date & Time",
                comment: "Add photo details view - Add date and time title"
            )
        }
    }
}

/**
 AddPhotoDetailsViewDelegate notifies host view when the required
 details are added to the photo
 */
protocol AddPhotoDetailsViewDelegate {
    func didSelectLocation(location: AppleMapLocation?) async
    func didSelectDate(date: Date)
}

/**
 AddPhotoDetailsView provides UI/UX and functional flow for adding photo details like,
 1. Location
 2. Date
 */
struct AddPhotoDetailsView: View {
    
    // MARK: Public properties
    
    var photo: CloudAsset?
    @Binding var mode: AddPhotoDetailsViewMode?
    var selectedLocation: String? = nil
    var selectedDateString: String? = nil
    var delegate: AddPhotoDetailsViewDelegate?
    
    // MARK: Private properties
    
    @SwiftUI.Environment(\.presentationMode) private var presentationMode
    @StateObject private var appleMapsService = AppleMapsService.sharedInstance
    @State private var locationSearchString = ""
    @State private var date = Date()
    
    private var changeLocationDescriptionText: String? {
        guard let location = self.selectedLocation, location != PhotoDetailsViewModel.unknownLocationText else {
            return NSLocalizedString(
                "This photo's location is unknown. To add a location, please search for the desired location and select one from the search result",
                comment: "Add photo details view - add location description"
            )
        }
        
        let string = NSLocalizedString(
            "This photo's current location is '%@'. To change, please search for a new location and select one from the search result",
            comment: "Add photo details view - change location description"
        )
        let formattedString = String.StringLiteralType(format: string, location)
        return formattedString
    }
    
    private var changeDateAndTimeDescriptionText: String? {
        guard let dateString = self.selectedDateString, dateString != PhotoDetailsViewModel.unknownDateTimeText else {
            return NSLocalizedString(
                "This photo's date and time is unknown. Please select desired date and time to add these details",
                comment: "Add photo details view - add date and time description"
            )
        }
        
        let string = NSLocalizedString(
            "This photo's current date and time is '%@'. To change, please select a new data and time and tap on save button",
            comment: "Add photo details view - change date and time description"
        )
        let formattedString = String.StringLiteralType(format: string, dateString)
        return formattedString
    }
    
    // MARK: User interface
    var body: some View {
        ZStack {
            // Background
            Color.black300
                .ignoresSafeArea()
            
            // Main content
            VStack(alignment: .center, spacing: 16) {
                
                ZStack(alignment: .center) {
                    HStack(alignment: .center) {
                        // Dismiss button
                        Button(
                            action: {
                                self.presentationMode.wrappedValue.dismiss()
                            },
                            label: {
                                Text(NSLocalizedString("Cancel", comment: "Adjust photo details view - Cancel button title"))
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.blue)
                            }
                        )
                        
                        Spacer()
                        
                        if let editMode = self.mode, editMode == .addDate {
                            // Done button
                            Button(
                                action: {
                                    self.delegate?.didSelectDate(date: self.date)
                                    self.presentationMode.wrappedValue.dismiss()
                                },
                                label: {
                                    Text(NSLocalizedString("Adjust", comment: "Adjust photo details view - Adjust button title"))
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.blue)
                                }
                            )
                        }
                    }
                    
                    // Title text
                    Text(self.mode?.title ?? "")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.offwhite100)
                }
                
                if let editMode = self.mode {
                    if editMode == .addLocation {
                        VStack(alignment: .leading, spacing: 16) {
                            // Search field
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray900, lineWidth: 1)
                                    .frame(height: 35)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.gray900)
                                    }
                                
                                HStack(alignment: .center, spacing: 12) {
                                    Image("searchIcon")
                                        .resizable()
                                        .renderingMode(.template)
                                        .scaledToFit()
                                        .tint(.gray800)
                                        .frame(width: 20, height: 20)
                                    
                                    HStack(alignment: .center, spacing: 0) {
                                        TextField(
                                            NSLocalizedString("Enter New Location", comment: "Add photo details view - Enter new location"),
                                            text: self.$locationSearchString
                                        )
                                        .font(.system(size: 18, weight: .regular))
                                        .foregroundColor(Color.offwhite100)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        
                                        // Clear search text button
                                        Button {
                                            self.locationSearchString = ""
                                        } label: {
                                            Image(systemName: "multiply.circle.fill")
                                        }
                                        .foregroundColor(.secondary)
                                        .opacity(self.locationSearchString.isEmpty ? 0 : 1)
                                    }
                                }
                                .padding(.horizontal, 8)
                            }
                            
                            // Set location to none (nil) button
                            if let location = self.selectedLocation, location != PhotoDetailsViewModel.unknownLocationText {
                                HStack(alignment: .top, spacing: 12) {
                                    Image("icon-no-location")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(NSLocalizedString("No Location", comment: "Add photo details view - No location"))
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(Color.offwhite100)
                                        Rectangle()
                                            .fill(Color.gray900)
                                            .frame(height: 1)
                                            .padding(.top, 6)
                                    }
                                    
                                }
                                .padding(.top, 16)
                                .onTapGesture {
                                    Task {
                                        await self.delegate?.didSelectLocation(location: nil)
                                    }
                                    self.presentationMode.wrappedValue.dismiss()
                                }
                            }
                            
                            // Location search result
                            if !self.appleMapsService.places.isEmpty {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(NSLocalizedString("Map Locations", comment: "Add photo details view - Map location"))
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(Color.gray600)
                                    Rectangle()
                                        .fill(Color.gray900)
                                        .frame(height: 1)
                                }
                                .padding(.top, 16)
                                
                                ScrollView(.vertical, showsIndicators: false) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        ForEach(self.appleMapsService.places, id: \.id) { place in
                                            ZStack(alignment: .leading) {
                                                HStack(alignment: .top, spacing: 12) {
                                                    Image("icon-location")
                                                        .resizable()
                                                        .frame(width: 40, height: 40)
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(place.title)
                                                            .font(.system(size: 18, weight: .semibold))
                                                            .foregroundColor(Color.offwhite100)
                                                        Text(place.subTitle)
                                                            .font(.system(size: 14, weight: .regular))
                                                            .foregroundColor(Color.gray600)
                                                        Rectangle()
                                                            .fill(Color.gray900)
                                                            .frame(height: 1)
                                                            .padding(.top, 6)
                                                    }
                                                }
                                            }
                                            .onTapGesture {
                                                Task {
                                                    await self.delegate?.didSelectLocation(location: place)
                                                }
                                                self.presentationMode.wrappedValue.dismiss()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 24)
                    } else if editMode == .addDate {
                        DatePicker(
                            NSLocalizedString("Pick a date and time", comment: "Add photo details view - pick date and time"),
                            selection: self.$date,
                            in: ...Date(),
                            displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .padding(.top, 24)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .onChange(of: self.locationSearchString, perform: { string in
                guard !string.isEmpty else {
                    self.appleMapsService.clearSearchResults()
                    return
                }
                self.appleMapsService.getLocations(for: string)
            })
            .onAppear {
                if let photo = self.photo, let photoDate = photo.date {
                    self.date = photoDate
                }
                
                if let photoLocation = self.selectedLocation, photoLocation != PhotoDetailsViewModel.unknownLocationText {
                    self.locationSearchString = photoLocation
                }
            }
            .onDisappear {
                self.appleMapsService.clearSearchResults()
            }
        }
    }
}
