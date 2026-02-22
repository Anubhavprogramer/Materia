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
                        VStack(alignment: .leading, spacing: AppConstants.mediumGap) {
                            // Title with animation
                            Text(AppStrings.AppName)
                                .font(.system(size: max(20, 36 - abs(scrollOffset) / 5), weight: .bold, design: .default))
                                .foregroundColor(AppColors.textPrimary)
                            
                            InfoCardView(icon: AppTips.buildTabTip.icon, title: AppTips.buildTabTip.title, message: AppTips.buildTabTip.message , accentColor: AppColors.accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        
                        
                        VStack(spacing: AppConstants.defaultPadding) {

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
                                icon: AppTips.savedTabTip.icon,
                                title: AppTips.savedTabTip.title,
                                message: AppTips.savedTabTip.message
                            )
                        }
                        .padding()
                    }
                    .coordinateSpace(name: AppStrings.scroll)
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
                    .foregroundColor(AppColors.accent)
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
