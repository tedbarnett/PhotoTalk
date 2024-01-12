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
    
    @SwiftUI.Environment(\.presentationMode) private var presentationMode
    
    // MARK: - User interface
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Spacer()
                
                Text(NSLocalizedString("Help and FAQ", comment: "Menu option - Help and FAQ"))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.offwhite100)
                    .offset(x: 15)
                
                Spacer()
                
                Button(
                    action: {
                        self.presentationMode.wrappedValue.dismiss()
                    },
                    label: {
                        ZStack {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 30, height: 30)
                            Image("closeButtonIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 25)
                        }
                    }
                )
            }
            .padding(.bottom, 24)
            
            // Heading description
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
                    ForEach(HelpInstruction.instructions, id: \.self.id) { instruction in
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
        .padding(.all, 16)
    }
}
