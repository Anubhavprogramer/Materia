//
//  CompoundDetailView.swift
//  Materia
//
//  Created by Anubhav Dubey on 01/02/26.
//
import SwiftUI

struct CompoundDetailView: View {
    @State var compound: IdentifiedCompound
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var homeViewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppConstants.defaultGap) {
                    CompoundResultView(compound: compound, canSave: false, notes: $compound.notes)
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAndDismiss()
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(AppColors.accent)
                    }
                }
            }
        }
    }
    
    private func saveAndDismiss() {
        // Debug: Log save operation
        CommonFunctions.debugNoteSave(
            compoundId: compound.id.uuidString,
            noteCount: compound.notes.count
        )
        
        // Update the compound in the view model
        homeViewModel.updateCompound(compound)
        
        CommonFunctions.debugNote(
            action: "SAVE_COMPLETE",
            noteId: "N/A",
            compoundId: compound.id.uuidString,
            message: "Compound saved with \(compound.notes.count) notes"
        )
        
        // Show success feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        dismiss()
    }
}

