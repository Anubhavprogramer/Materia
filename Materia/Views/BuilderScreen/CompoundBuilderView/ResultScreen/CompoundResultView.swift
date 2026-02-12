//
//  CompoundResultView.swift
//  Materia
//
//  Results screen showing identified compound information
//

import SwiftUI

struct CompoundResultView: View {
    let compound: IdentifiedCompound?
    let structure: ChemicalStructure?
    let canSave: Bool
    let onSave: (IdentifiedCompound) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var toastManager: ToastManager
    @State private var isSaved = false
    @State private var showToast = false

    @State private var showIUPACExplanation = false
    @State private var modifiedStructure: ChemicalStructure?

    private var activeStructure: ChemicalStructure {
        modifiedStructure ?? structure ?? compound?.structure ?? ChemicalStructure(carbonChainLength: 1)
    }

    private var iupacExplanation: IUPACExplanation {
        // Deterministic + offline explanation.
        let service = CoreMLChemistryServiceFactory.createService()
        return service.explainIUPAC(from: activeStructure)
    }
    
    private var currentCompound: IdentifiedCompound? {
        if let compound = compound {
            return compound
        }
        
        let structure = activeStructure
        let iupac = iupacExplanation.finalName
        
        // Calculate molecular formula from structure
        let carbonCount = structure.carbonChainLength
        let hydrogenCount = (carbonCount * 2) + 2 // Simplified: CnH(2n+2)
        let formula = "C\(carbonCount)H\(hydrogenCount)"
        
        return IdentifiedCompound(
            structure: structure,
            name: "Modified Structure",
            iupacName: iupac,
            formula: formula,
            category: "Custom"
        )
    }
    
    init(compound: IdentifiedCompound? = nil,
         structure: ChemicalStructure? = nil,
         canSave: Bool = true,
         onSave: @escaping (IdentifiedCompound) -> Void = { _ in }) {
        self.compound = compound
        self.structure = structure
        self.canSave = canSave
        self.onSave = onSave
        _modifiedStructure = State(initialValue: structure ?? compound?.structure)
    }

    
    var body: some View {
        ZStack {
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
                                InfoCardView(
                                    icon: "info.circle.fill",
                                    title: "Info",
                                    message: "Turn this on to see step-by-step naming.",
                                    accentColor: .blue,
                                    backgroundColor: Color.blue.opacity(0.1),
                                    borderColor: Color.blue.opacity(0.3)
                                )
                                
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
                                
                                Text(currentCompound?.compoundName ?? "—")
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
                                
                                Text(currentCompound?.iupacName ?? "—")
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
                                
                                Text(currentCompound?.molecularFormula ?? "—")
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
                                
                                Text(currentCompound?.category ?? "—")
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
                                    value: "\(activeStructure.carbonChainLength)"
                                )
                                
                                InfoRow(
                                    title: "Total Bonds",
                                    value: "\(activeStructure.bonds.count)"
                                )
                                
                                InfoRow(
                                    title: "Functional Groups",
                                    value: "\(activeStructure.functionalGroups.count)"
                                )
                                
                                InfoRow(
                                    title: "Structure Notation",
                                    value: activeStructure.toSMILESLike()
                                )
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // CoreML Properties Section
                        //                    CoreMLPropertiesSection(compound: compound)
                        
                        // Structure Preview
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Structure Diagram")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            StructureDiagramView(structure: activeStructure)
                                .frame(height: 200)
                                .background(AppColors.Card)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Add Functional Groups Section
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Add Functional Groups", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Select a carbon position and add functional groups to modify the structure")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                            
                            VStack(spacing: 10) {
                                ForEach(1...activeStructure.carbonChainLength, id: \.self) { carbon in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Carbon \(carbon)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(AppColors.textPrimary)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 8) {
                                                ForEach([FunctionalGroup.methyl, .alcohol, .amine, .carboxylicAcid, .aldehyde, .ketone, .nitrile, .nitro], id: \.self) { group in
                                                    let isAttached = activeStructure.functionalGroups.contains { $0.carbonPosition == carbon && $0.group == group }
                                                    
                                                    Button(action: {
                                                        var newStruct = modifiedStructure ?? activeStructure
                                                        if isAttached {
                                                            newStruct.functionalGroups.removeAll { $0.carbonPosition == carbon && $0.group == group }
                                                        } else {
                                                            newStruct.functionalGroups.append(FunctionalGroupAttachment(position: carbon, group: group))
                                                        }
                                                        modifiedStructure = newStruct
                                                        toastManager.show("\(group.displayName) \(isAttached ? "removed" : "added") to C\(carbon)", type: .info)
                                                    }) {
                                                        VStack(spacing: 4) {
                                                            Image(systemName: isAttached ? "checkmark.circle.fill" : "circle")
                                                                .font(.system(size: 14, weight: .bold))
                                                            
                                                            Text(group.rawValue)
                                                                .font(.caption2)
                                                                .fontWeight(.semibold)
                                                                .lineLimit(1)
                                                        }
                                                        .foregroundColor(isAttached ? AppColors.white : AppColors.accent)
                                                        .frame(width: 50)
                                                        .padding(.vertical, 8)
                                                        .background(isAttached ? AppColors.accent : AppColors.accent.opacity(0.1))
                                                        .cornerRadius(AppConstants.smallCornerRadius)
                                                    }
                                                }
                                            }
                                            .padding(.vertical, 4)
                                        }
                                    }
                                    .padding(AppConstants.defaultPadding)
                                    .background(AppColors.Card)
                                    .cornerRadius(AppConstants.defaultCornerRadius)
                                }
                            }
                        }
                        .padding()
                        .background(AppColors.accent.opacity(0.1))
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
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
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
        guard let comp = currentCompound else { return }
        onSave(comp)
        isSaved = true
        
        // Show toast
        toastManager.show(AppStrings.compoundSaved, type: .success)

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func resetForm() {
        // Reset all states
        isSaved = false
        showIUPACExplanation = false
        toastManager.show("Form reset", type: .info)
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
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
