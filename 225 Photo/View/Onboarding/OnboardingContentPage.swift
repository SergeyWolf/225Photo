//
//  OnboardingContentPage.swift
//  225 Photo
//
//  Created by Сергей on 24.11.2025.
//

//import SwiftUICore
import SwiftUI

struct OnboardingContentPage<Overlay: View>: View {
    let imageName: String
    let title: String
    let subtitle: String?
    let pageIndex: Int
    let totalPages: Int
    let nextActionTitle: String
    let onNext: () -> Void
    let overlay: Overlay
    
    init(
        imageName: String,
        title: String,
        subtitle: String?,
        pageIndex: Int,
        totalPages: Int,
        nextActionTitle: String,
        onNext: @escaping () -> Void,
        @ViewBuilder overlay: () -> Overlay = { EmptyView() }
    ) {
        self.imageName = imageName
        self.title = title
        self.subtitle = subtitle
        self.pageIndex = pageIndex
        self.totalPages = totalPages
        self.nextActionTitle = nextActionTitle
        self.onNext = onNext
        self.overlay = overlay()
    }
    
    var body: some View {
        ZStack {
            Color.black
            
            VStack(spacing: 0) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fit)
                    .frame(maxWidth: .infinity, alignment: .top)
                
                Spacer()
                
                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if let subtitle {
                            Text(subtitle)
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.bottom, 24)
                    
                    Button(action: onNext) {
                        Text(nextActionTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color("OnboardingYellow"))
                            .cornerRadius(12)
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 24)
                    
                    HStack(spacing: 6) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(
                                    index == pageIndex ? .white : .white.opacity(0.3)
                                )
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            
            overlay
        }
        .ignoresSafeArea()
    }
}

