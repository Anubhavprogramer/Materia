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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppConstants.defaultGap) {
                    CompoundResultView(compound: compound, canSave: false)
                    
                    SwipeableNoteCardView(notes: $compound.notes)
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
