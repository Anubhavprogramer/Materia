//
//  EditNoteView.swift
//  Materia
//
//  Created by Anubhav Dubey on 17/02/26.
//
import SwiftUI

struct EditNoteView: View {
    @State var note: CompoundNote
    let onSave: (CompoundNote) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Pointers") {
                    TextField("Content", text: $note.content, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(4...6)
                }
            }
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { updateNote() }
                        .fontWeight(.semibold)
                        .disabled(note.content.isEmpty)
                }
            }
        }
    }
    
    private func updateNote() {
        note.update(content: note.content)
        onSave(note)
        dismiss()
    }
}
