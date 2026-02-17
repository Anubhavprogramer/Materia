//
//  AddNoteView.swift
//  Materia
//
//  Created by Anubhav Dubey on 17/02/26.
//
import SwiftUI

struct AddNoteView: View {
    @Binding var notes: [CompoundNote]
    @Environment(\.dismiss) var dismiss
    
    @State private var content = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Pointers") {                    
                    TextField("Content", text: $content, axis: .vertical)
                        .lineLimit(4...6)
                }
            }
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveNote() }
                        .fontWeight(.semibold)
                        .disabled(content.isEmpty)
                }
            }
        }
    }
    
    private func saveNote() {
        let note = CompoundNote(
            compoundId: UUID(),
            content: content,
        )
        
        notes.append(note)
        dismiss()
    }
}
