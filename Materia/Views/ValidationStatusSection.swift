//
//  ValidationStatusSection.swift
//  Materia
//
//  Real-time structure validation display using CoreML
//

import SwiftUI

struct ValidationStatusSection: View {
    @ObservedObject var viewModel: CompoundBuilderViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Structure Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Basic Validation Status
                HStack {
                    Image(systemName: viewModel.isValidStructure ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(viewModel.isValidStructure ? .green : .red)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Basic Validation")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(viewModel.validationError ?? "Structure follows basic chemistry rules")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                // CoreML Validation Status
                HStack {
                    Group {
                        if viewModel.isValidating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if let result = viewModel.validationResult {
                            Image(systemName: result.isValid ? "brain.head.profile" : "exclamationmark.triangle.fill")
                                .foregroundColor(result.isValid ? .blue : .orange)
                        } else {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.gray)
                        }
                    }
                    .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("AI Analysis")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if let result = viewModel.validationResult {
                                Text("\(Int(result.confidence * 100))%")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(validationStatusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Detailed Analysis (if available)
                if let result = viewModel.validationResult, !viewModel.isValidating {
                    VStack(spacing: 8) {
                        Divider()
                        
                        HStack {
                            Text("Confidence Breakdown")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Valid")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                
                                ProgressView(value: result.isValid ? result.confidence : (1.0 - result.confidence))
                                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                    .frame(height: 4)
                                
                                Text("\(Int((result.isValid ? result.confidence : (1.0 - result.confidence)) * 100))%")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Invalid")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                
                                ProgressView(value: result.isValid ? (1.0 - result.confidence) : result.confidence)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .red))
                                    .frame(height: 4)
                                
                                Text("\(Int((result.isValid ? (1.0 - result.confidence) : result.confidence) * 100))%")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var validationStatusText: String {
        if viewModel.isValidating {
            return "Analyzing structure with AI models..."
        } else if let result = viewModel.validationResult {
            return result.validationMessage ?? (result.isValid ? "Structure appears chemically feasible" : "Structure may have issues")
        } else {
            return "Waiting for structure analysis"
        }
    }
}

#Preview {
    ValidationStatusSection(viewModel: CompoundBuilderViewModel())
}