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
    @Binding var isInputValid: Bool
    var isSecuredField: Bool = false
    var backgroundColor: Color = .white
    var height: CGFloat = 70
    
    @State private var didValidateInput = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(self.type.title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color.offwhite100)
            
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray800, lineWidth: 1)
                    .frame(height: self.height)
                
                if self.isSecuredField {
                    SecureField(
                        "",
                        text: self.$text,
                        onCommit: {
                            self.validateInput()
                        }
                    )
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color.gray800)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.all, 10)
                } else {
                    TextField(
                        "",
                        text: self.$text,
                        onCommit: {
                            self.validateInput()
                        }
                    )
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color.gray800)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.all, 10)
                }
            }
            
            Text(self.type.validationMessage)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.red400)
                .opacity(self.isInputValid ? 0 : 1)
                .animation(.easeIn(duration: 0.2), value: self.isInputValid)
        }
    }
    
    private func validateInput() {
        self.didValidateInput = true
        
        switch self.type {
        case .name: self.isInputValid = !self.text.isEmpty
        case .email: return self.isInputValid = !self.text.isEmpty && self.text.contains("@") && self.text.contains(".")
        case .password: self.isInputValid = !self.text.isEmpty && self.text.count >= 8
        }
    }
}

/**
 FormTextFieldType defines different types of form text fields like name, email, password, etc
 It also provides text field details like placeholder text, validation message, etc
 */
enum FormTextFieldType {
    case name, email, password
    
    var title: String {
        switch self {
        case .name: return NSLocalizedString("Name", comment: "User registration - name field title")
        case .email: return NSLocalizedString("Email", comment: "User registration - email field title")
        case .password: return NSLocalizedString("Password", comment: "User registration - password field title")
        }
    }
    
    var validationMessage: String {
        switch self {
        case .name: return NSLocalizedString(
            "Please enter valid name",
            comment: "User registration - name field validation text"
        )
        case .email: return NSLocalizedString(
            "Please enter a valid email",
            comment: "User registration - email field validation text"
        )
        case .password: return NSLocalizedString(
            "Please enter minimum of 8 characters for password",
            comment: "User registration - password field validation text"
        )
        }
    }
}
