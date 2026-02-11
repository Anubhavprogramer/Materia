//
//  FunctionalGroupButton.swift
//  Materia
//
//  Created by Anubhav Dubey on 01/02/26.
//

import SwiftUI

struct FunctionalGroupButton: View {
    let group: FunctionalGroup
    let isAttached: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppConstants.defaultGap / 2) {
                Text(group.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(group.displayName.components(separatedBy: " (").first ?? "")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isAttached
                ? AppColors.accent.opacity(0.3)
                : AppColors.secondary
            )
            .foregroundColor(
                isAttached
                ? AppColors.accent
                : AppColors.textPrimary
            )
            .cornerRadius(AppConstants.defaultCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.defaultCornerRadius)
                    .stroke(
                        isAttached ? AppColors.accent: Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}
