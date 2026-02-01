//
//  StructureDiagramView.swift
//  Materia
//
//  Created by Anubhav Dubey on 01/02/26.
//
import SwiftUI


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
