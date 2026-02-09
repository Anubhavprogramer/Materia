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

    /// Used to reset the embedded builder view model when switching quick-start templates.
    @State private var builderSessionID = UUID()
    @State private var initialStructure: ChemicalStructure?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColors.gradientStart,
                        AppColors.gradientEnd
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Header
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image("HomeScreenIcon")
                                    .frame(width: 15, height: 15)
                                    .opacity(0.3)

                                VStack(alignment: .leading, spacing: 4) {
//                                    Text("Materia")
//                                        .font(.largeTitle)
//                                        .fontWeight(.bold)
//                                        .foregroundColor(AppColors.primary)
                                    Text("Chemical Structure Identifier")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.textPrimary)
                                }

                                Spacer()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                    QuickStartSection { structure in
                        initialStructure = structure
                        builderSessionID = UUID() // reset builder
                    }
                    .padding(20)

                    // Embedded builder (no separate "Build Compound" button)
                    CompoundBuilderView(initialStructure: initialStructure) { compound in
                        homeVM.saveCompound(compound)
                    }
                    .id(builderSessionID)

                    // Small hint to access saved compounds
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(AppColors.primary)
                                .font(.system(size: 16))
                            
                            Text("Tip")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        
                        Text("Your saved compounds are available in the Saved tab.")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.primaryLight)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.primaryMuted, lineWidth: 1)
                            )
                    )
                }
                .padding(.top)
            }
            .navigationTitle("Materia")
//            .navigationBarTitleDisplayMode(.automatic)
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
}
