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
            VStack(spacing: 4) {
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
                    ? Color.green.opacity(0.2)
                    : Color(.systemGray5)
            )
            .foregroundColor(
                isAttached
                    ? .green
                    : .primary
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isAttached ? Color.green : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}
