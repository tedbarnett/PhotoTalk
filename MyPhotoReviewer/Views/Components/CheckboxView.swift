//
//  CheckboxView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 15/11/23.
//

import SwiftUI

/**
 CheckboxViewDelegate handles change in the selection state of the checkbox
 */
protocol CheckboxViewDelegate {
    func didChangeSelection(isSelected: Bool)
}

/**
 CheckboxView presents a checkbox control
 */
struct CheckboxView: View {
    
    // MARK: - Public properties
    
    var title: String
    var delegate: CheckboxViewDelegate?
    
    // MARK: - Private properties
    
    @State private var isSelected: Bool = false
    
    // MARK: - User interface
    
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            Image(self.isSelected ? "icon-checkbox-checked" : "icon-checkbox-unchecked")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
            Text(self.title)
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
        .onTapGesture {
            self.isSelected.toggle()
            self.delegate?.didChangeSelection(isSelected: self.isSelected)
        }
    }
}
