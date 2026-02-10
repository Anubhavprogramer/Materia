//
//  TipView.swift
//  Materia
//
//  Created by Anubhav Dubey on 10/02/26.
//

import SwiftUI

struct InfoCardView: View {

    // MARK: - Inputs
    let icon: String
    let title: String
    let message: String

    var accentColor: Color = AppColors.primary
    var backgroundColor: Color = AppColors.primaryLight
    var borderColor: Color = AppColors.primaryMuted

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(accentColor)
                    .font(.system(size: 16))

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
            }

            Text(message)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
    }
}

