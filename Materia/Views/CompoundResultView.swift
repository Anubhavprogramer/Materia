//
//  CompoundResultView.swift
//  Materia
//
//  Results screen showing identified compound information
//

import SwiftUI

struct CompoundResultView: View {
    let compound: IdentifiedCompound
    let canSave: Bool
    let onSave: (IdentifiedCompound) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isSaved = false

    @State private var showIUPACExplanation = true

    private var iupacExplanation: IUPACExplanation {
        // Deterministic + offline explanation.
        let service = CoreMLChemistryServiceFactory.createService()
        return service.explainIUPAC(from: compound.structure)
    }
    
    init(compound: IdentifiedCompound,
         canSave: Bool = true,
         onSave: @escaping (IdentifiedCompound) -> Void = { _ in }) {
        self.compound = compound
        self.canSave = canSave
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Success Header
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Compound Identified!")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .padding(.top)

                    // Educational Mode: IUPAC explanation
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "graduationcap")
                                .foregroundColor(.purple)
                            Text("Educational Mode")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Toggle("", isOn: $showIUPACExplanation)
                                .labelsHidden()
                        }

                        if showIUPACExplanation {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("How the IUPAC name is built")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                ForEach(iupacExplanation.steps) { step in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(step.title)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text(step.detail)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(10)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(.systemGray5), lineWidth: 1)
                                    )
                                }

                                if !iupacExplanation.notes.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Notes")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        ForEach(iupacExplanation.notes, id: \.self) { note in
                                            Text("• \(note)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.top, 2)
                                }
                            }
                        } else {
                            Text("Turn this on to see step-by-step naming.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Compound Information Card
                    VStack(spacing: 20) {
                        // Common Name
                        VStack(spacing: 8) {
                            Text("Common Name")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(compound.compoundName)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                        }
                        
                        Divider()
                        
                        // IUPAC Name
                        VStack(spacing: 8) {
                            Text("IUPAC Name")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(compound.iupacName)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.purple)
                                .multilineTextAlignment(.center)
                        }
                        
                        Divider()
                        
                        // Molecular Formula
                        VStack(spacing: 8) {
                            Text("Molecular Formula")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(compound.molecularFormula)
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        
                        Divider()
                        
                        // Category
                        VStack(spacing: 8) {
                            Text("Category")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(compound.category)
                                .font(.title2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                        }
                    }
                    .padding(24)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Structure Information with CoreML Properties
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Structure Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            InfoRow(
                                title: "Carbon Chain Length",
                                value: "\(compound.structure.carbonChainLength)"
                            )
                            
                            InfoRow(
                                title: "Total Bonds",
                                value: "\(compound.structure.bonds.count)"
                            )
                            
                            InfoRow(
                                title: "Functional Groups",
                                value: "\(compound.structure.functionalGroups.count)"
                            )
                            
                            InfoRow(
                                title: "Structure Notation",
                                value: compound.structure.toSMILESLike()
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // CoreML Properties Section
                    CoreMLPropertiesSection(compound: compound)
                    
                    // Structure Preview
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Structure Diagram")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        StructureDiagramView(structure: compound.structure)
                            .frame(height: 200)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        if canSave {
                            Button(action: saveCompound) {
                                HStack {
                                    Image(systemName: isSaved ? "checkmark" : "square.and.arrow.down")
                                    Text(isSaved ? "Saved!" : "Save Compound")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    isSaved
                                        ? LinearGradient(colors: [.green], startPoint: .leading, endPoint: .trailing)
                                        : LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(12)
                            }
                            .disabled(isSaved)
                        }
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Done")
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveCompound() {
        onSave(compound)
        isSaved = true

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(.subheadline, design: title == "Structure Notation" ? .monospaced : .default))
                .fontWeight(.medium)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    let sampleStructure = ChemicalStructure(carbonChainLength: 2)
    let sampleCompound = IdentifiedCompound(
        structure: sampleStructure,
        name: "Ethanol",
        iupacName: "ethanol",
        formula: "C₂H₆O",
        category: "Organic"
    )
    
    CompoundResultView(compound: sampleCompound) { _ in }
}