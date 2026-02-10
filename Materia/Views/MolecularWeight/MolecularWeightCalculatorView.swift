//
//  MolecularWeightCalculatorView.swift
//  Materia
//
//  Molecular weight calculator tab view
//

import SwiftUI

struct MolecularWeightCalculatorView: View {
    @State private var carbonChainLength: Int = 2
    @State private var selectedFunctionalGroups: [FunctionalGroup] = []
    @State private var bonds: [Bond] = []
    
    var molecularWeight: Double {
        MolecularWeightCalculator.calculateMolecularWeight(
            carbonChainLength: carbonChainLength,
            bonds: bonds,
            functionalGroups: selectedFunctionalGroups.enumerated().map { 
                FunctionalGroupAttachment(position: 1, group: $0.element)
            }
        )
    }
    
    var molecularFormula: String {
        MolecularWeightCalculator.getMolecularFormula(
            carbonChainLength: carbonChainLength,
            bonds: bonds,
            functionalGroups: selectedFunctionalGroups.enumerated().map { 
                FunctionalGroupAttachment(position: 1, group: $0.element)
            }
        )
    }
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Carbon Chain Length
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Carbon Chain Length", systemImage: "chain")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            HStack(spacing: 16) {
                                Button(action: { if carbonChainLength > 1 { carbonChainLength -= 1 } }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(AppColors.primary)
                                }
                                
                                Text("\(carbonChainLength)")
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(AppColors.primaryFaded)
                                    .cornerRadius(8)
                                    .foregroundColor(AppColors.primary)
                                
                                Button(action: { if carbonChainLength < 20 { carbonChainLength += 1 } }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                        }
                        .padding()
                        .background(AppColors.surface)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // MARK: - Functional Groups
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Functional Groups", systemImage: "cube.transparent")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            VStack(spacing: 8) {
                                ForEach(FunctionalGroup.allCases, id: \.self) { group in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(group.displayName)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(AppColors.textPrimary)
                                            
                                            Text("Weight: \(String(format: "%.2f", getGroupWeight(group))) g/mol")
                                                .font(.caption)
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: selectedFunctionalGroups.contains(group) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(
                                                selectedFunctionalGroups.contains(group)
                                                    ? AppColors.accent
                                                    : AppColors.textSecondary
                                            )
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            if selectedFunctionalGroups.contains(group) {
                                                selectedFunctionalGroups.removeAll { $0 == group }
                                            } else {
                                                selectedFunctionalGroups.append(group)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        selectedFunctionalGroups.contains(group)
                                            ? AppColors.accentLight
                                            : Color.clear
                                    )
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(AppColors.surface)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // MARK: - Information Card
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Molecular Weight Info", systemImage: "info.circle")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                MWInfoRow(label: "Total Atoms", value: "\(getTotalAtoms())")
                                Divider()
                                MWInfoRow(label: "Carbon Atoms", value: "\(carbonChainLength)")
                                Divider()
                                MWInfoRow(label: "Functional Groups", value: "\(selectedFunctionalGroups.count)")
                            }
                            .padding(.vertical, 8)
                        }
                        .padding()
                        .background(AppColors.surface)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .padding(.vertical, 16)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Molecular Weight")
        }
    }
    
    private func getGroupWeight(_ group: FunctionalGroup) -> Double {
        switch group {
        case .methyl:           return 2 * AtomicMass.hydrogen
        case .alcohol:          return AtomicMass.oxygen + AtomicMass.hydrogen
        case .amine:            return AtomicMass.nitrogen + 2 * AtomicMass.hydrogen
        case .carboxylicAcid:   return AtomicMass.carbon + 2 * AtomicMass.oxygen + AtomicMass.hydrogen
        case .aldehyde:         return AtomicMass.carbon + AtomicMass.oxygen + AtomicMass.hydrogen
        case .ketone:           return AtomicMass.carbon + AtomicMass.oxygen
        case .nitrile:          return AtomicMass.carbon + AtomicMass.nitrogen
        case .nitro:            return 2 * AtomicMass.oxygen + AtomicMass.nitrogen
        case .thiol:            return AtomicMass.sulfur + AtomicMass.hydrogen
        case .fluorine:         return AtomicMass.fluorine
        case .chlorine:         return AtomicMass.chlorine
        case .bromine:          return AtomicMass.bromine
        case .iodine:           return AtomicMass.iodine
        }
    }
    
    private func getTotalAtoms() -> Int {
        let hydrogenCount = MolecularWeightCalculator.calculateHydrogenCount(
            carbonChainLength: carbonChainLength,
            bonds: bonds,
            functionalGroups: selectedFunctionalGroups.enumerated().map { 
                FunctionalGroupAttachment(position: 1, group: $0.element)
            }
        )
        return carbonChainLength + hydrogenCount + selectedFunctionalGroups.count
    }
}

// MARK: - Helper Views
struct MWInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.primary)
        }
    }
}

// MARK: - Preview
#Preview {
    MolecularWeightCalculatorView()
}
