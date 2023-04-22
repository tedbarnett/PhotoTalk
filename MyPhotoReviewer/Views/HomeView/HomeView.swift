//
//  ContentView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 22/04/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 3) {
                Text("Welcome back")
                    .font(.system(size: 16, weight: .regular))
                Text("Theodore")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.teal)
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
