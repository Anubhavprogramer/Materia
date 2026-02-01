//
//  CompoundRowView.swift
//  Materia
//
//  Created by Anubhav Dubey on 01/02/26.
//
import SwiftUI

struct CompoundRowView: View {
    let compound: IdentifiedCompound
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(compound.compoundName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(compound.iupacName)
                        .font(.subheadline)
                        .foregroundColor(.purple)
                        .fontWeight(.medium)
                    
                    Text(compound.molecularFormula)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(compound.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        
                        // CoreML validation indicator
                        if let isValidated = compound.isValidated {
                            Image(systemName: isValidated ? "brain.head.profile" : "exclamationmark.triangle")
                                .foregroundColor(isValidated ? .green : .orange)
                                .font(.caption)
                        }
                    }
                    
                    // Confidence indicator
                    if let confidence = compound.confidence {
                        HStack(spacing: 2) {
                            Image(systemName: "brain.head.profile")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            
                            Text("\(Int(confidence * 100))%")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(compound.identifiedAt, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Structure preview
            HStack {
                Text("Structure:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(compound.structure.toSMILESLike())
                    .font(.system(.caption, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray6))
                    .cornerRadius(4)
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}
