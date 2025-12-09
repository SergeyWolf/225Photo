//
//  SplashScreenView.swift
//  225 Photo
//
//  Created by Сергей on 05.12.2025.
//

import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            Image("AppIconSplash")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .clipShape(
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                )
        }
    }
}
