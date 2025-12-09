//
//  RateAlertOverlayView.swift
//  225 Photo
//
//  Created by Сергей on 24.11.2025.
//

import SwiftUICore
import SwiftUI

struct RateAlertOverlayView: View {
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "app.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    )
                
                Text("Review Store Review Controller?")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Tap a star to rate it on the App Store.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 4) {
                    ForEach(0..<5) { _ in
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }
                
                Button("Not now") {
                    
                }
                .font(.system(size: 15, weight: .semibold))
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

