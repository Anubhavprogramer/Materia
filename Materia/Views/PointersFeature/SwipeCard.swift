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
    let onMoveToBack: () -> Void
    let index: Int
    let totalCards: Int
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var showDeleteAlert = false
    @State private var swipeDirection: SwipeDirection? = nil
    @State private var velocity: CGSize = .zero
    @State private var shadowDepth: CGFloat = 2
    @State private var cardScale: CGFloat = 1.0
    @State private var isAnimating = false
    
    enum SwipeDirection {
        case left, right, up, down
    }
    
    // Calculate dynamic shadow based on offset
    private var shadowRadius: CGFloat {
        let distance = sqrt(offset.width * offset.width + offset.height * offset.height)
        return 2 + (distance / 100) * 8
    }
    
    // Calculate dynamic shadow opacity based on movement
    private var shadowOpacity: Double {
        let distance = sqrt(offset.width * offset.width + offset.height * offset.height)
        return 0.1 + min(distance / 300, 0.15)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Note Content
            Text(note.content)
                .font(.system(size: AppConstants.body, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Created Date
            Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: AppConstants.caption, weight: .regular))
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppConstants.largePadding)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 280)
        .background(AppColors.Card)
        .cornerRadius(AppConstants.largeCornerRadius)
        
        // Enhanced shadow with depth effect
        .shadow(color: Color.black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: shadowRadius * 0.5)
        
        // Stacked effect with smooth transitions
        .offset(y: CGFloat(index) * 8)
        .offset(x: CGFloat(index) * 4)
        .scaleEffect(1 - CGFloat(index) * 0.02, anchor: .bottom)
        
        // Swipe gesture & tap to edit
        .offset(offset)
        .rotationEffect(.degrees(rotation), anchor: .center)
        .scaleEffect(cardScale, anchor: .center)
        .opacity(swipeDirection == nil ? 1 : 0.8)
        .contentShape(Rectangle())
        .allowsHitTesting(index == 0) // Only top card can be interacted with
        .gesture(
            DragGesture()
                .onChanged { value in
                    if index == 0 && !isAnimating {
                        offset = value.translation
                        velocity = value.velocity
                        
                        // Determine primary direction
                        let isVertical = abs(value.translation.height) > abs(value.translation.width)
                        
                        if isVertical {
                            // Vertical swipe - apply scale effect
                            cardScale = 1 - (abs(value.translation.height) / 1000)
                            rotation = 0
                        } else {
                            // Horizontal swipe - apply rotation
                            rotation = Double(value.translation.width / 10)
                            cardScale = 1.0
                        }
                    }
                }
                .onEnded { value in
                    if index == 0 && !isAnimating {
                        handleSwipe(value)
                    }
                }
        )
        .highPriorityGesture(
            TapGesture()
                .onEnded { _ in
                    if index == 0 && offset == .zero && !isAnimating {
                        let tapFeedback = UIImpactFeedbackGenerator(style: .light)
                        tapFeedback.impactOccurred()
                        onEdit()
                    }
                }
        )
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
        // Prevent multiple swipes while animating
        guard !isAnimating else { return }
        
        let horizontalAmount = value.translation.width
        let verticalAmount = value.translation.height
        let threshold: CGFloat = 50
        
        // Determine primary direction based on which is larger
        let isVerticalSwipe = abs(verticalAmount) > abs(horizontalAmount)
        
        // Calculate velocity magnitude for responsive animations
        let velocityMagnitude = sqrt(velocity.width * velocity.width + velocity.height * velocity.height)
        
        // Determine swipe direction
        if isVerticalSwipe && abs(verticalAmount) > threshold {
            // VERTICAL SWIPE - Delete
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            if verticalAmount > 0 {
                swipeDirection = .down
            } else {
                swipeDirection = .up
            }
            deleteWithAnimation(velocity: velocityMagnitude)
        } else if !isVerticalSwipe && abs(horizontalAmount) > threshold {
            // HORIZONTAL SWIPE - Cycle cards
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
            
            if horizontalAmount > 0 {
                swipeDirection = .right
            } else {
                swipeDirection = .left
            }
            moveToBack(velocity: velocityMagnitude)
        } else {
            // Not enough movement - snap back with responsive spring
            withAnimation(.spring(response: 0.25, dampingFraction: 0.65, blendDuration: 0.1)) {
                offset = .zero
                rotation = 0
                cardScale = 1.0
            }
        }
    }
    
    private func deleteWithAnimation(velocity: CGFloat) {
        isAnimating = true
        
        // Velocity-responsive animation timing
        let duration = max(0.2, min(0.4, 0.3 / (velocity / 300)))
        
        withAnimation(.easeInOut(duration: duration)) {
            offset = swipeDirection == .up
                ? CGSize(width: 0, height: -600)
                : CGSize(width: 0, height: 600)
            rotation = 0
            cardScale = 0.8
        }
        
        // Haptic feedback on delete
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0.2, min(0.4, 0.3 / (velocity / 300)))) {
            isAnimating = false
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7, blendDuration: 0.1)) {
                onDelete()
            }
        }
    }
    
    private func moveToBack(velocity: CGFloat) {
        isAnimating = true
        
        // Velocity-responsive spring animation
        let response = max(0.2, min(0.4, 0.35 / (velocity / 300)))
        
        withAnimation(.spring(response: response, dampingFraction: 0.6, blendDuration: 0.1)) {
            offset = .zero
            rotation = 0
            cardScale = 1.0
        }
        
        // Light haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Call the callback to move card to back in array
            onMoveToBack()
            isAnimating = false
        }
    }
    
    private func performDelete() {
        onDelete()
    }
}
