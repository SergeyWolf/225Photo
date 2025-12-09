//
//  OnboardingNotificationsPage.swift
//  225 Photo
//
//  Created by Сергей on 24.11.2025.
//

import SwiftUICore
import SwiftUI

struct OnboardingNotificationsPage: View {
    let imageName: String
    let title: String
    let subtitle: String
    let onAllow: () -> Void
    let onMaybeLater: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Image(imageName)
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fit)
                    .clipped()
                    .cornerRadius(32)
                    .shadow(radius: 20)
                    .overlay(alignment: .top) {
                        NotificationBannerMock()
                            .offset(y: 24)
                    }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 24)
                
                Button(action: onAllow) {
                    Text("Next")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color("OnboardingYellow"))
                        .cornerRadius(12)
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 24)
                
                Button(action: onMaybeLater) {
                    Text("Maybe later")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 8)
                }
                .padding(.bottom, 24)
            }
        }
    }
}

struct NotificationBannerMock: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Fresh update! ⚠️")
                    .font(.system(size: 13, weight: .semibold))
                Text("New trending video effects are waiting for you in the app!")
                    .font(.system(size: 11))
                    .lineLimit(2)
            }
            .foregroundColor(.black)
            
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
        )
        .padding(.horizontal, 24)
    }
}
