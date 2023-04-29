//
//  FormTextField.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 29/04/23.
//

import SwiftUI

struct FormTextField: View {
    
    @Binding var text: String
    var title: String
    var isSecuredField: Bool = false
    var backgroundColor: Color = .white
    var height: CGFloat = 40
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.offwhite100)
                .frame(height: self.height)
            
            if self.isSecuredField {
                SecureField(
                    self.title,
                    text: self.$text,
                    onCommit: {
                        print("entered secured text...")
                    }
                )
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.all, 10)
            } else {
                TextField(
                    self.title,
                    text: self.$text,
                    onCommit: {
                        print("entered text...")
                    }
                )
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.all, 10)
            }
        }
    }
}
