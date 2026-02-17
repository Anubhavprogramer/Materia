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
    
    let compoundId: UUID
    @State private var content = ""
    
    var body: some View {
        NavigationStack {
            formContent
                .navigationTitle("Add Note")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarItems
                }
        }
    }
    
    private var formContent: some View {
        Form {
            Section("Note") {
                noteTextField
            }
        }
    }
    
    private var noteTextField: some View {
        TextField("What you want to note...", text: $content, axis: .vertical)
            .lineLimit(4...8)
    }
    
    private var toolbarItems: some ToolbarContent {
        Group {
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
    
    private func saveNote() {
        let note = CompoundNote(
            compoundId: compoundId,
            content: content
        )
        
        CommonFunctions.debugNoteAdd(
            noteId: note.id.uuidString,
            compoundId: compoundId.uuidString,
            content: content
        )
        
        notes.append(note)
        CommonFunctions.debugNote(
            action: "APPEND",
            noteId: note.id.uuidString,
            compoundId: compoundId.uuidString,
            message: "Note appended to notes array. Total notes: \(notes.count)"
        )
        
        dismiss()
    }
}
