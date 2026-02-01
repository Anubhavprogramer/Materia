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
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Image("HomeScreenIcon")
                            .frame(width: 15, height: 15)
                            .opacity(0.3)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Materia")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.accent)
                            Text("Chemical Structure Identifier")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                        }

                        Spacer()
                    }

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
                        Text("Tip")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Your saved compounds are available in the Saved tab.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.top)
            }
//            .navigationTitle("Materia")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        initialStructure = nil
                        builderSessionID = UUID()
                    }
                }
            }
            .background(AppColors.background)
        }
    }
}
