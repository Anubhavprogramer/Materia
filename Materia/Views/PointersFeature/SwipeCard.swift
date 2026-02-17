//
//  SwipeCard.swift
//  Materia
//
//  Created by Anubhav Dubey on 17/02/26.
//

import SwiftUI

struct SwipeCard: View {
    let note: CompoundNote
    let onDelete: () -> Void
    let onEdit: () -> Void
    let index: Int
    let totalCards: Int
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var showDeleteAlert = false
    @State private var swipeDirection: SwipeDirection? = nil
    
    enum SwipeDirection {
        case left, right, up, down
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with dots indicator
            HStack {
                Text(String(index + 1))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Subtitle/Content
            Text(note.content)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // Footer with date
            Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 220)
        .background(AppColors.background)
        .cornerRadius(AppConstants.largeCornerRadius)
        
        // Stacked effect
        .offset(y: CGFloat(index) * 8)
        .offset(x: CGFloat(index) * 4)
        .scaleEffect(1 - CGFloat(index) * 0.02, anchor: .bottom)
        
        // Swipe gesture & tap to edit
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .opacity(swipeDirection == nil ? 1 : 0.8)
        .contentShape(Rectangle()) // Makes full card tappable
        .gesture(
            DragGesture()
                .onChanged { value in
                    if index == 0 {
                        offset = value.translation
                        rotation = Double(value.translation.width / 10)
                    }
                }
                .onEnded { value in
                    if index == 0 {
                        handleSwipe(value)
                    }
                }
        )
        .onTapGesture {
            if index == 0 && offset == .zero {
                onEdit()
            }
        }
        .alert("Delete Note", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                performDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this note?")
        }
    }
    
    private func handleSwipe(_ value: DragGesture.Value) {
        let horizontalAmount = value.translation.width
        let verticalAmount = value.translation.height
        let threshold: CGFloat = 50
        
        // Determine swipe direction
        if abs(verticalAmount) > threshold {
            if verticalAmount > 0 {
                // Swiped down - delete
                swipeDirection = .down
                deleteWithAnimation()
            } else {
                // Swiped up - delete
                swipeDirection = .up
                deleteWithAnimation()
            }
        } else if abs(horizontalAmount) > threshold {
            if horizontalAmount > 0 {
                // Swiped right - move to back
                swipeDirection = .right
                moveToBack()
            } else {
                // Swiped left - move to back
                swipeDirection = .left
                moveToBack()
            }
        } else {
            // Not enough movement - snap back
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                offset = .zero
                rotation = 0
            }
        }
    }
    
    private func deleteWithAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            offset = swipeDirection == .up
                ? CGSize(width: 0, height: -600)
                : CGSize(width: 0, height: 600)
            rotation = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                onDelete()
            }
        }
    }
    
    private func moveToBack() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            offset = .zero
            rotation = 0
        }
    }
    
    private func performDelete() {
        onDelete()
    }
}
