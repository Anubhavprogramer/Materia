//
//  Model3DUserGuide.swift
//  Materia
//

import SwiftUI

struct Model3DUserGuide: View {
    
    @State private var currentPage = 0
    @Environment(\.dismiss) private var dismiss
    
    private let totalPages = 4
    
    var body: some View {
        ZStack {
            
            // Soft background
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // MARK: - Pages
                TabView(selection: $currentPage) {
                    
                    GuidePageView(
                        icon: "hand.draw",
                        title: "Rotation",
                        steps: [
                            ("1 Finger", "Drag with one finger"),
                            ("All Directions", "Rotate freely in 3D space"),
                            ("Smooth Motion", "Experience fluid rotation")
                        ]
                    )
                    .tag(0)
                    
                    GuidePageView(
                        icon: "hand.pinch",
                        title: "Zoom & Scale",
                        steps: [
                            ("2 Fingers", "Use pinch gesture"),
                            ("Pinch In", "Zoom out"),
                            ("Pinch Out", "Zoom in for detail")
                        ]
                    )
                    .tag(1)
                    
                    GuidePageView(
                        icon: "rotate.3d",
                        title: "Tilt & Perspective",
                        steps: [
                            ("Two Fingers Rotate", "Twist to change angle"),
                            ("Vertical Drag", "Tilt up or down"),
                            ("Explore Depth", "View from any perspective")
                        ]
                    )
                    .tag(2)
                    
                    GuidePageView(
                        icon: "slider.horizontal.3",
                        title: "Pro Tips",
                        steps: [
                            ("Double Tap", "Reset instantly"),
                            ("Long Press", "Toggle labels"),
                            ("Swipe Pages", "Navigate quickly")
                        ]
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // MARK: - Page Indicator
                HStack {
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? .primary : .secondary)
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.easeInOut(duration: 0.25), value: currentPage)
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(currentPage + 1)/\(totalPages)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                Divider()
                
                // MARK: - Footer Buttons
                HStack(spacing: 12) {
                    
                    if currentPage > 0 {
                        Button {
                            withAnimation(.easeInOut) {
                                currentPage -= 1
                            }
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.glass)
                        .tint(AppColors.accent)
                    }
                    
                    Button {
                        if currentPage < totalPages - 1 {
                            withAnimation(.easeInOut) {
                                currentPage += 1
                            }
                        } else {
                            dismiss()
                        }
                    } label: {
                        Label(
                            currentPage == totalPages - 1 ? "Got It" : "Next",
                            systemImage: currentPage == totalPages - 1 ? "checkmark.circle.fill" : "chevron.right"
                        )
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.glassProminent)   // ← no custom color applied
                    .tint(AppColors.accent)
                }
                .padding(20)
            }
        }
        .navigationTitle("3D Viewer Guide")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
}


struct GuidePageView: View {
    
    let icon: String
    let title: String
    let steps: [(String, String)]
    
    var body: some View {
        VStack(spacing: 28) {
            
            // MARK: - Icon Card
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                
                VStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 52, weight: .semibold))
                    
                    Text(title)
                        .font(.title3.bold())
                }
                .padding()
            }
            .frame(height: 160)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            
            // MARK: - Steps
            VStack(spacing: 14) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    
                    HStack(spacing: 16) {
                        
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 40, height: 40)
                            
                            Text("\(index + 1)")
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.0)
                                .font(.subheadline.weight(.semibold))
                            
                            Text(step.1)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}
