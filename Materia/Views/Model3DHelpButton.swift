//
//  Model3DHelpButton.swift
//  Materia
//
//  Floating help button for 3D viewer with first-time hint
//

import SwiftUI

struct Model3DHelpButton: View {
    @State private var showGuide = false
    @State private var hasSeenGuide = false
    @State private var showHint = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Hidden button that triggers the sheet
            Button(action: { showGuide = true }) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.blue.opacity(0.8)))
                    .frame(width: 44, height: 44)
            }
//            .offset(x: -16, y: 16)
            
            // Hint tooltip (first time only)
            if showHint && !hasSeenGuide {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Tap for gesture help")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    Text("Learn how to rotate, zoom, and tilt the molecule")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 4)
                .offset(x: -120, y: 50)
            }
        }
        .sheet(isPresented: $showGuide) {
            Model3DUserGuide()
                .onDisappear {
                    hasSeenGuide = true
                }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if !hasSeenGuide {
                    withAnimation {
                        showHint = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        withAnimation {
                            showHint = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct Model3DHelpButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.systemBackground)
            
            Model3DHelpButton()
        }
    }
}
#endif
