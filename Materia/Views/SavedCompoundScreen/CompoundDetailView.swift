//
//  CompoundDetailView.swift
//  Materia
//
//  Created by Anubhav Dubey on 01/02/26.
//
import SwiftUI

struct CompoundDetailView: View {
    let compound: IdentifiedCompound
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            CompoundResultView(compound: compound, canSave: false)
                .navigationTitle("Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}
