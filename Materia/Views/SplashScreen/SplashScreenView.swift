//
//  SplashScreenView.swift
//  Materia
//
//  Simple splash screen with app logo
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var scaleValue: CGFloat = 0.8
    @State private var opacityValue: Double = 0
    
    var body: some View {
        ZStack {
            // MARK: - Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.gradientStart,
                    AppColors.gradientEnd
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // MARK: - App Logo
            VStack {
                Spacer()
                
                Image("app_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .scaleEffect(scaleValue)
                    .opacity(opacityValue)
                    .cornerRadius(20)
                
                Spacer()
            }
        }
        .onAppear {
            // Animate the logo on appearance
            withAnimation(.easeInOut(duration: 0.8)) {
                scaleValue = 1.0
                opacityValue = 1.0
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SplashScreenView()
}
