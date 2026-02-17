//
//  SwipeableNoteCardView.swift
//  Materia
//
//  Created by Anubhav Dubey on 17/02/26.
//

import SwiftUI

struct SwipeableNoteCardView: View {
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
                ZStack {
                    ForEach(Array(notes.enumerated()), id: \.element.id) { index, note in
                        SwipeCard(
                            note: note,
                            onDelete: {
                                deleteNote(at: index)
                            },
                            onEdit: {
                                selectedNote = note
                                isEditingNote = true
                            },
                            index: index,
                            totalCards: notes.count
                        )
                    }
                }
                .frame(height: 280)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
            }
            
            // Instructions
            if !notes.isEmpty {
                HStack(spacing: 12) {
                    VStack(spacing: 2) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Swipe")
                            .font(.caption2)
                    }
                    
                    Divider()
                    
                    VStack(spacing: 2) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Delete")
                            .font(.caption2)
                    }
                    
                    Spacer()
                    
                    Text("\(notes.count) note\(notes.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .foregroundColor(AppColors.textSecondary)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
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
    
    private func deleteNote(at index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            notes.remove(at: index)
        }
    }
}



