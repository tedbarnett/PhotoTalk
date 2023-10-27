//
//  HelpView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 27/10/23.
//

import SwiftUI

/**
 HelpView shows instructions about how to use the app
 */
struct HelpView: View {
    
    // MARK: - Private properties
    
    private let instructions: [HelpInstruction] = [
        HelpInstruction(text: "Add photos from your Apple Photos, Google Photos, or Dropbox to get started. Choose photos you want to include in your slide show."),
        HelpInstruction(text: "Once added, you can tap any photo to...", subInstructions: [
            HelpInstruction(text: "Add your own voice narration describing the photo (or just telling a story!). After you add voice narration to any photo, you can tap either Save (the floppy disk icon) or Delete the Narration (trash can icon) and try again."),
            HelpInstruction(text: "Set (or change) the location where the photo was taken"),
            HelpInstruction(text: "Set (or change) the date and time of the photo. If you don't know the exact time, leave it blank"),
            HelpInstruction(text: "Add the photo to your slide show by tapping the slide show icon in the top right")
        ]),
        HelpInstruction(text: "If you do edit the Location or Date/time for a photo in your Apple Photos or Google Photos collection, PhotoTalk will update the original photo in your library too (i.e. we update the \"EXIF\" data for that photo).", subInstructions: [
            HelpInstruction(text: "Unfortunately, there is no way to add voice narration to photos in your collection. Your voice narration will only appear in PhotoTalk itself and in any slide shows you create and share.")
        ]),
        HelpInstruction(text: "Photos that will be included in the slide show appear with a small \"slide\" icon on the main screen"),
        HelpInstruction(text: "Press and drag any photo to change its order in the slide show"),
        HelpInstruction(text: "When you are happy with your photo updates, tap the Menu icon and choose \"Show Slide Show\" to see the results"),
        HelpInstruction(text: "You can share your slide show (complete with voice narration) by choosing \"Share Slide Show\" from the menu")
    ]
    
    // MARK: - User interface
    
    var body: some View {
        ZStack {
            // Background
            Color.black900
                .ignoresSafeArea()
            
            // Content
            VStack(alignment: .leading) {
                // Title text
                Text(NSLocalizedString("PhotoTalk lets you easily edit the location and date of any of your photos -- and add voice narration to make a shareable \"slide show\" from your own photos.", comment: "Help view - title"))
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(Color.offwhite100)
                
                // Title text
                Text(NSLocalizedString("Instructions:", comment: "Help view - Subtitle"))
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(Color.offwhite100)
                    .padding(.top, 16)
                
                // Instructions
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(self.instructions, id: \.self.id) { instruction in
                            Text("• \(instruction.text)")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(Color.gray600)
                            if let subInstructions = instruction.subInstructions {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(subInstructions, id: \.self.id) { instruction in
                                        Text("• \(instruction.text)")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(Color.gray600)
                                            .padding(.leading, 24)
                                    }
                                }
                            }
                        }
                    }
                    
                }
            }
            .padding(.all, 24)
        }
    }
}
