//
//  QuickStartChip.swift
//  Materia
//
//  Created by Anubhav Dubey on 01/02/26.
//
import SwiftUI

struct QuickStartChip: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppColors.secondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.textSecondary, lineWidth: 1)
            )
        }
    }
}
