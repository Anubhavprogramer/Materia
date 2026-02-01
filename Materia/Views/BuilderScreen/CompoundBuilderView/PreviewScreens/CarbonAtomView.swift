//
//  CarbonAtomView.swift
//  Materia
//
//  Created by Anubhav Dubey on 01/02/26.
//


import SwiftUI

struct CarbonAtomView: View {
    let position: CGPoint
    let carbonNumber: Int
    let functionalGroups: [FunctionalGroup]
    
    var body: some View {
        VStack(spacing: 2) {
            // Functional groups above
            if !functionalGroups.isEmpty {
                VStack(spacing: 1) {
                    ForEach(Array(functionalGroups.enumerated()), id: \.offset) { index, group in
                        Text(group.rawValue)
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                }
            }
            
            // Carbon atom
            Circle()
                .fill(Color.gray.opacity(0.8))
                .frame(width: 24, height: 24)
                .overlay(
                    Text("C")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            // Carbon number
            Text("\(carbonNumber)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .position(position)
    }
}
