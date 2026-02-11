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
                
                ScrollView {
                    VStack(spacing: AppConstants.defaultPadding) {
                        // Header
                        VStack(alignment: .leading) {
                            HStack {
//                                Image("HomeScreenIcon")
//                                    .frame(width: 1, height: 1)
//                                    .opacity(0.3)

                                VStack(alignment: .leading, spacing: 4) {
//                                    Text("Materia")
//                                        .font(.largeTitle)
//                                        .fontWeight(.bold)
//                                        .foregroundColor(AppColors.primary)
                                    Text("Chemical Structure Identifier")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.textPrimary)
                                }
//
                                Spacer()
                            }
                        }
//                        .padding(.horizontal, 16)
//                        .padding(.vertical, 12)

                    QuickStartSection { structure in
                        initialStructure = structure
                        builderSessionID = UUID() // reset builder
                    }
//                    .padding(20)

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
            
            }
            .navigationTitle("Materia")
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
