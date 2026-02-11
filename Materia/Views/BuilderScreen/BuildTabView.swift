//
//  BuildTabView.swift
//  Materia
//
//  Created by Anubhav Dubey on 01/02/26.
//

import Foundation
import SwiftUI

// MARK: - Build Tab
struct BuildTabView: View {
    @StateObject private var homeVM = HomeViewModel()

    //Used to reset the embedded builder view model when switching quick-start templates.
    @State private var builderSessionID = UUID()
    @State private var initialStructure: ChemicalStructure?
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColors.gradientStart,
                        AppColors.gradientEnd
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
//                VStack(spacing: 0) {
                    
                    
                    // MARK: - Scrollable Content
                    ScrollView {
                        
                        // MARK: - Sticky Collapsing Header
                        VStack(alignment: .leading, spacing: 12) {
                            // Title with animation
                            Text("Materia")
                                .font(.system(size: max(20, 36 - abs(scrollOffset) / 5), weight: .bold, design: .default))
                                .foregroundColor(AppColors.primary)
                            
                            // Subtitle with fade
                            Text("Chemical Structure Identifier")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                                .opacity(max(0, 1 - abs(scrollOffset) * 0.01))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        
                        
                        VStack(spacing: AppConstants.defaultPadding) {
                            GeometryReader { geometry in
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                            }
                            .frame(height: 0)

                            QuickStartSection { structure in
                                initialStructure = structure
                                builderSessionID = UUID() // reset builder
                            }

                            // Embedded builder (no separate "Build Compound" button)
                            CompoundBuilderView(initialStructure: initialStructure) { compound in
                                homeVM.saveCompound(compound)
                            }
                            .id(builderSessionID)

                            // Small hint to access saved compounds
                            InfoCardView(
                                icon: "lightbulb.fill",
                                title: "Tip",
                                message: "Your saved compounds are available in the Saved tab."
                            )
                        }
                        .padding()
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        scrollOffset = value
                    }
//                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        initialStructure = nil
                        builderSessionID = UUID()
                    }
                    .foregroundColor(AppColors.primary)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
