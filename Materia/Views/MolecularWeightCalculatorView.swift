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
        ZStack {
            Color("MateriaBackground")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with gradient
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Molecular Weight")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("MateriaTextPrimary"))
                            
                            Text("Calculate and explore molecular properties")
                                .font(.caption)
                                .foregroundColor(Color("MateriaTextSecondary"))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color("MateriaPrimary"))
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color("MateriaSurface"),
                            Color("MateriaSurface").opacity(0.5)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Molecular Weight Card
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Molecular Weight")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color("MateriaTextSecondary"))
                                    
                                    Text(String(format: "%.3f", molecularWeight))
                                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color("MateriaPrimary"))
                                    
                                    Text("g/mol")
                                        .font(.caption)
                                        .foregroundColor(Color("MateriaTextSecondary"))
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Formula")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color("MateriaTextSecondary"))
                                    
                                    Text(molecularFormula)
                                        .font(.system(.headline, design: .monospaced))
                                        .foregroundColor(Color("MateriaAccent"))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color("MateriaPrimary").opacity(0.15))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color("MateriaSurface"))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // MARK: - Carbon Chain Length
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Carbon Chain Length", systemImage: "chain")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("MateriaTextPrimary"))
                            
                            HStack(spacing: 16) {
                                Button(action: { if carbonChainLength > 1 { carbonChainLength -= 1 } }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color("MateriaPrimary"))
                                }
                                
                                Text("\(carbonChainLength)")
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color("MateriaPrimary").opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundColor(Color("MateriaPrimary"))
                                
                                Button(action: { if carbonChainLength < 20 { carbonChainLength += 1 } }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color("MateriaPrimary"))
                                }
                            }
                        }
                        .padding()
                        .background(Color("MateriaSurface"))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // MARK: - Functional Groups
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Functional Groups", systemImage: "cube.transparent")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("MateriaTextPrimary"))
                            
                            VStack(spacing: 8) {
                                ForEach(FunctionalGroup.allCases, id: \.self) { group in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(group.displayName)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(Color("MateriaTextPrimary"))
                                            
                                            Text("Weight: \(String(format: "%.2f", getGroupWeight(group))) g/mol")
                                                .font(.caption)
                                                .foregroundColor(Color("MateriaTextSecondary"))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: selectedFunctionalGroups.contains(group) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(
                                                selectedFunctionalGroups.contains(group)
                                                    ? Color("MateriaAccent")
                                                    : Color("MateriaTextSecondary")
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
                                            ? Color("MateriaAccent").opacity(0.08)
                                            : Color.clear
                                    )
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color("MateriaSurface"))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // MARK: - Information Card
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Molecular Weight Info", systemImage: "info.circle")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("MateriaTextPrimary"))
                            
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
                        .background(Color("MateriaSurface"))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .padding(.vertical, 16)
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
                .foregroundColor(Color("MateriaTextSecondary"))
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color("MateriaPrimary"))
        }
    }
}

// MARK: - Preview
#Preview {
    MolecularWeightCalculatorView()
}
