//
//  FormTextField.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 29/04/23.
//

import SwiftUI

struct FormTextField: View {
    
    var type: FormTextFieldType
    @Binding var text: String
    var isSecuredField: Bool = false
    var backgroundColor: Color = .white
    var height: CGFloat = 40
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.offwhite100)
                    .frame(height: self.height)
                
                if self.isSecuredField {
                    SecureField(
                        self.type.placeholderText,
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
                        self.type.placeholderText,
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
            
            Text(self.type.validationMessage)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.red400)
        }
    }
}

/**
 FormTextFieldType defines different types of form text fields like name, email, password, etc
 It also provides text field details like placeholder text, validation message, etc
 */
enum FormTextFieldType {
    case name, email, password
    
    var placeholderText: String {
        switch self {
        case .name: return "Name"
        case .email: return "Email"
        case .password: return "Password"
        }
    }
    
    var validationMessage: String {
        switch self {
        case .name: return "Please enter valid name"
        case .email: return "Please enter a valid email"
        case .password: return "Please enter minimum of 8 characters for password"
        }
    }
}
