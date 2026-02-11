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
    @State private var manualHydrogenCount: Int = 0
    
    var molecularWeight: Double {
        MolecularWeightCalculator.calculateMolecularWeight(
            carbonChainLength: carbonChainLength,
            bonds: bonds,
            functionalGroups: selectedFunctionalGroups.enumerated().map { 
                FunctionalGroupAttachment(position: 1, group: $0.element)
            }
        ) + (Double(manualHydrogenCount) * AtomicMass.hydrogen)
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
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColors.gradientStart,
                        AppColors.gradientEnd
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            // MARK: - Molecular Weight Card (Prominent)
                            VStack(spacing: 16) {
                                VStack(spacing: 8) {
                                    Text("Molecular Weight")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.textSecondary)
                                    
                                    Text(String(format: "%.2f", molecularWeight))
                                        .font(.system(size: 44, weight: .bold, design: .monospaced))
                                        .foregroundColor(AppColors.primary)
                                    
                                    Text("g/mol")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                
                                Divider()
                                    .padding(.vertical, 8)
                                
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Molecular Formula")
                                            .font(.subheadline)
                                            .foregroundColor(AppColors.textSecondary)
                                        
                                        Spacer()
                                        
                                        Text(molecularFormula)
                                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                            .foregroundColor(AppColors.primary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(AppColors.primaryFaded)
                                            .cornerRadius(8)
                                    }
                                    
                                    HStack {
                                        Text("Total Atoms")
                                            .font(.subheadline)
                                            .foregroundColor(AppColors.textSecondary)
                                        
                                        Spacer()
                                        
                                        Text("\(getTotalAtoms())")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(AppColors.primary)
                                    }
                                }
                            }
                            .padding(20)
                            .background(AppColors.surface)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.primary.opacity(0.2), lineWidth: 2)
                            )
                            .shadow(color: AppColors.primary.opacity(0.1), radius: 8, x: 0, y: 4)
                            .padding(.horizontal)
                            .padding(.top, 16)
                            
                            // MARK: - Carbon Chain Length
                            VStack(alignment: .leading, spacing: 12) {
                                Label(AppStrings.carbonChain, systemImage: "chain")
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
                                Label(AppStrings.functionalGroupsSection, systemImage: "cube.transparent")
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
            }
            .navigationTitle("Molecular Weight")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        resetCalculator()
                    }
                    .foregroundColor(AppColors.primary)
                    .fontWeight(.semibold)
                }
            }
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
        let baseAtoms = carbonChainLength + selectedFunctionalGroups.count
        return baseAtoms + manualHydrogenCount
    }
    
    private func resetCalculator() {
        withAnimation(.easeInOut(duration: 0.3)) {
            carbonChainLength = 2
            selectedFunctionalGroups = []
            bonds = []
            manualHydrogenCount = 0
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
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
