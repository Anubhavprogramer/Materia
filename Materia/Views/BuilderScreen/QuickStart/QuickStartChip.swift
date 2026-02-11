//
//  QuickStartChip.swift
//  Materia
//
//  Created by Anubhav Dubey on 01/02/26.
//
import SwiftUI

struct QuickStartChip: View {
    let title: String
    let structure: ChemicalStructure
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                // Structure Preview
                StructureDiagramView(structure: structure)
                    .frame(height: 100)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                // Title
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(width: 140)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.accentLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.primaryMuted, lineWidth: 1.5)
            )
        }
    }
}
