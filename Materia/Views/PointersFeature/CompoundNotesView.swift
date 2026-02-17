//
//  CompoundNotesView.swift
//  Materia
//
//  Created by Anubhav Dubey on 17/02/26.
//

import SwiftUI

struct CompoundNotesView: View {
    @Binding var notes: [CompoundNote]
    @State private var showAddNote = false
    @State private var selectedNote: CompoundNote?
    @State private var isEditingNote = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Notes", systemImage: "note.text")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button(action: { showAddNote = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.accent)
                    .cornerRadius(AppConstants.defaultCornerRadius)
                }
            }
            
            if notes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "note.text")
                        .font(.system(size: 32))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("No notes yet")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("Add a note to keep track of important information about this compound")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(AppConstants.defaultPadding)
                .background(Color(.systemGray6))
                .cornerRadius(AppConstants.defaultCornerRadius)
            } else {
                VStack(spacing: 8) {
                    ForEach(notes) { note in
                        NoteCardView(note: note) {
                            selectedNote = note
                            isEditingNote = true
                        } onDelete: {
                            notes.removeAll { $0.id == note.id }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, AppConstants.defaultPadding)
        .sheet(isPresented: $showAddNote) {
            AddNoteView(notes: $notes)
        }
        .sheet(item: $selectedNote) { note in
            EditNoteView(note: note) { updatedNote in
                if let index = notes.firstIndex(where: { $0.id == updatedNote.id }) {
                    notes[index] = updatedNote
                }
                isEditingNote = false
            }
        }
    }
}

