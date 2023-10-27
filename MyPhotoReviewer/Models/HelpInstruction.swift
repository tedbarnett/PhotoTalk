//
//  HelpInstruction.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 27/10/23.
//

import Foundation

/**
 HelpInstruction data object contains details about the instructions to show to the user
 */
struct HelpInstruction {
    let id: String = UUID().uuidString
    let text: String
    let subInstructions: [HelpInstruction]?
    
    init(text: String, subInstructions: [HelpInstruction]? = nil) {
        self.text = text
        self.subInstructions = subInstructions
    }
}
