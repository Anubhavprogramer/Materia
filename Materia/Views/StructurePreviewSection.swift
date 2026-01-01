//
//  StructurePreviewSection.swift
//  Materia
//
//  2D structure preview for the compound builder
//

import SwiftUI

struct StructurePreviewSection: View {
    @ObservedObject var viewModel: CompoundBuilderViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Structure Preview")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // 2D Structure Visualization
                StructureDiagramView(structure: viewModel.structure)
                    .frame(height: 200)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                // SMILES-like representation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Structure Notation:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.structure.toSMILESLike())
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StructureDiagramView: View {
    let structure: ChemicalStructure
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let carbonSpacing = min(width / max(Double(structure.carbonChainLength), 1), 80)
            let startX = (width - carbonSpacing * Double(structure.carbonChainLength - 1)) / 2
            
            ZStack {
                // Draw bonds
                ForEach(structure.bonds, id: \.id) { bond in
                    let fromX = startX + carbonSpacing * Double(bond.fromCarbon - 1)
                    let toX = startX + carbonSpacing * Double(bond.toCarbon - 1)
                    let y = height / 2
                    
                    BondView(
                        from: CGPoint(x: fromX, y: y),
                        to: CGPoint(x: toX, y: y),
                        type: bond.type
                    )
                }
                
                // Draw carbons
                ForEach(1...structure.carbonChainLength, id: \.self) { carbon in
                    let x = startX + carbonSpacing * Double(carbon - 1)
                    let y = height / 2
                    
                    CarbonAtomView(
                        position: CGPoint(x: x, y: y),
                        carbonNumber: carbon,
                        functionalGroups: structure.functionalGroups
                            .filter { $0.carbonPosition == carbon }
                            .map { $0.group }
                    )
                }
            }
        }
    }
}

struct BondView: View {
    let from: CGPoint
    let to: CGPoint
    let type: BondType
    
    var body: some View {
        ZStack {
            switch type {
            case .single:
                Path { path in
                    path.move(to: from)
                    path.addLine(to: to)
                }
                .stroke(Color.black, lineWidth: 2)
                
            case .double:
                Path { path in
                    let offset: CGFloat = 3
                    path.move(to: CGPoint(x: from.x, y: from.y - offset))
                    path.addLine(to: CGPoint(x: to.x, y: to.y - offset))
                    path.move(to: CGPoint(x: from.x, y: from.y + offset))
                    path.addLine(to: CGPoint(x: to.x, y: to.y + offset))
                }
                .stroke(Color.black, lineWidth: 2)
                
            case .triple:
                Path { path in
                    let offset: CGFloat = 4
                    path.move(to: from)
                    path.addLine(to: to)
                    path.move(to: CGPoint(x: from.x, y: from.y - offset))
                    path.addLine(to: CGPoint(x: to.x, y: to.y - offset))
                    path.move(to: CGPoint(x: from.x, y: from.y + offset))
                    path.addLine(to: CGPoint(x: to.x, y: to.y + offset))
                }
                .stroke(Color.black, lineWidth: 2)
            }
        }
    }
}

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

#Preview {
    StructurePreviewSection(viewModel: CompoundBuilderViewModel())
}