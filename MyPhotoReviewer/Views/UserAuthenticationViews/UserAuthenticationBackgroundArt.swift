//
//  UserAuthenticationBackgroundArt.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 29/04/23.
//

import SwiftUI

struct UserAuthenticationBackgroundArt: View {
    var body: some View {
        VStack {
            Image(systemName: "photo.on.rectangle.angled")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .rotationEffect(.degrees(-25))
                .frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.height * 0.7)
                .opacity(0.3)
            
            Spacer()
            
            Image(systemName: "photo.on.rectangle.angled")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .rotationEffect(.degrees(10))
                .frame(width: UIScreen.main.bounds.width * 0.4, height: UIScreen.main.bounds.height * 0.4)
                .opacity(0.3)
                .padding(.bottom, 100)
        }
    }
}

struct UserAuthenticationBackgroundArt_Previews: PreviewProvider {
    static var previews: some View {
        UserAuthenticationBackgroundArt()
    }
}
