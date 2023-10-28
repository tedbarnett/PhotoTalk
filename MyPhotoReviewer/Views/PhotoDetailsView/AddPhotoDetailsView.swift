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
                "Add location",
                comment: "Add photo details view - Add location title"
            )
        case .addDate:
            return NSLocalizedString(
                "Add date and time",
                comment: "Add photo details view - Add date title"
            )
        }
    }
}

/**
 AddPhotoDetailsViewDelegate notifies host view when the required
 details are added to the photo
 */
protocol AddPhotoDetailsViewDelegate {
    func didSelectLocation(location: GooglePlace)
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
    @StateObject private var placesService = GooglePlacesService()
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
                        Spacer()
                        
                        // Dismiss button
                        Button(
                            action: {
                                self.presentationMode.wrappedValue.dismiss()
                            },
                            label: {
                                ZStack {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(width: 40, height: 40)
                                    Image("closeButtonIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 25, height: 25)
                                }
                            }
                        )
                    }
                    
                    // Title text
                    Text(self.mode?.title ?? "")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color.blue500)
                }
                
                if let editMode = self.mode {
                    if editMode == .addLocation {
                        VStack(alignment: .leading, spacing: 16) {
                            
                            // Currently selected location, if available
                            if let descriptionText = self.changeLocationDescriptionText {
                                Text(descriptionText)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(Color.offwhite100)
                                    .padding(.top, 8)
                            }
                            
                            // Search field
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray600, lineWidth: 1)
                                    .frame(height: 44)
                                    .background {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.offwhite100)
                                    }
                                // Text field
                                HStack(alignment: .center, spacing: 12) {
                                    Image("searchIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 15, height: 15)
                                    
                                    TextField(
                                        NSLocalizedString("Search", comment: "Add photo details view - search"),
                                        text: self.$locationSearchString
                                    )
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color.black300)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                            }
                            
                            // Search result
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(alignment: .leading, spacing: 5) {
                                    ForEach(self.placesService.places, id: \.id) { place in
                                        ZStack(alignment: .leading) {
                                            
                                            Text(place.name)
                                                .font(.system(size: 16))
                                                .foregroundColor(Color.black300)
                                                .padding(.all, 8)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(Color.gray200)
                                                        .frame(maxWidth: .infinity)
                                                )
                                        }
                                        .onTapGesture {
                                            self.delegate?.didSelectLocation(location: place)
                                            self.presentationMode.wrappedValue.dismiss()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                    } else if editMode == .addDate {
                        
                        // Currently selected location, if available
                        if let descriptionText = self.changeDateAndTimeDescriptionText {
                            Text(descriptionText)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(Color.offwhite100)
                                .padding(.top, 8)
                        }
                        
                        DatePicker(
                            NSLocalizedString("Pick a date and time", comment: "Add photo details view - pick date and time"),
                            selection: self.$date,
                            in: ...Date(),
                            displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .padding(.top, 24)
                        
                        Button(
                            action: {
                                self.delegate?.didSelectDate(date: self.date)
                                self.presentationMode.wrappedValue.dismiss()
                            },
                            label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue)
                                        .frame(height: 40)
                                    Text(NSLocalizedString("Save", comment: "Common - Save button title"))
                                        .font(.system(size: 16))
                                        .foregroundColor(Color.white)
                                }
                            }
                        )
                        .padding(.top, 8)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .onChange(of: self.locationSearchString, perform: { string in
                self.placesService.findPlaces(query: string)
            })
            .onAppear {
                if let photo = self.photo, let photoDate = photo.date {
                    self.date = photoDate
                }
            }
        }
    }
}
