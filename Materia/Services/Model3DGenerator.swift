//
//  Model3DGenerator.swift
//  Materia
//
//  Service to convert ChemicalStructure to 3D model with caching and optimization
//

import Foundation
import SceneKit

class Model3DGenerator {
    
    // MARK: - Constants
    private static let carbonBondLength: Float = 1.54      // Angstroms
    private static let carbonHydrogenLength: Float = 1.09  // Angstroms
    private static let structureSpacing: Float = 2.5       // Scaling factor
    
    // MARK: - Cache (Thread-safe)
    private static let cacheLock = NSLock()
    private static var modelCache: [String: Model3D] = [:]
    
    // MARK: - Cache Management
    static func clearCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        modelCache.removeAll()
    }
    
    static func getCacheSize() -> Int {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return modelCache.count
    }
    
    // MARK: - Generate 3D Model from ChemicalStructure
    static func generate3DModel(from structure: ChemicalStructure, name: String) -> Model3D {
        // Generate cache key from structure
        let cacheKey = generateCacheKey(structure: structure, name: name)
        
        // Check cache first
        cacheLock.lock()
        if let cachedModel = modelCache[cacheKey] {
            cacheLock.unlock()
            return cachedModel
        }
        cacheLock.unlock()
        
        // Generate new model
        let model = generateModelUncached(from: structure, name: name)
        
        // Cache the result
        cacheLock.lock()
        modelCache[cacheKey] = model
        cacheLock.unlock()
        
        return model
    }
    
    private static func generateCacheKey(structure: ChemicalStructure, name: String) -> String {
        // Create deterministic cache key from structure properties
        let bondKey = structure.bonds
            .map { "\($0.fromCarbon)-\($0.toCarbon)-\($0.type.rawValue)" }
            .joined(separator: "|")
        
        let groupKey = structure.functionalGroups
            .map { "\($0.carbonPosition)-\($0.group.rawValue)" }
            .joined(separator: "|")
        
        return "model_\(structure.carbonChainLength)_\(bondKey)_\(groupKey)"
    }
    
    private static func generateModelUncached(from structure: ChemicalStructure, name: String) -> Model3D {
        var model = Model3D(name: name)
        
        // Handle edge case: zero-carbon compounds
        if structure.carbonChainLength == 0 {
            return generateNonCarbonStructure(from: structure, name: name)
        }
        
        // Generate carbon backbone
        let carbonPositions = generateCarbonBackbone(length: structure.carbonChainLength)
        var carbonAtoms: [Int] = []
        
        for (index, position) in carbonPositions.enumerated() {
            let atom = Atom3D(element: .carbon, position: position)
            model.addAtom(atom)
            carbonAtoms.append(index)
        }
        
        // Add C-C bonds
        for bond in structure.bonds {
            let bondType = convertBondType(bond.type)
            let length = Self.carbonBondLength
            
            let bondModel = Bond3D(
                from: bond.fromCarbon,
                to: bond.toCarbon,
                type: bondType,
                length: length
            )
            model.addBond(bondModel)
        }
        
        // Add hydrogen atoms
        var hydrogenIndex = model.atoms.count
        for (carbonIndex, carbon) in carbonAtoms.enumerated() {
            let hydrogenCount = calculateHydrogenCount(
                carbonIndex: carbonIndex,
                totalCarbons: structure.carbonChainLength,
                bonds: structure.bonds,
                functionalGroups: structure.functionalGroups
            )
            
            let hydrogenPositions = generateHydrogenPositions(
                aroundAtom: model.atoms[carbon],
                count: hydrogenCount
            )
            
            for hydrogenPos in hydrogenPositions {
                let hydrogen = Atom3D(element: .hydrogen, position: hydrogenPos)
                model.addAtom(hydrogen)
                
                let chBond = Bond3D(
                    from: carbon,
                    to: hydrogenIndex,
                    type: .single,
                    length: Self.carbonHydrogenLength
                )
                model.addBond(chBond)
                hydrogenIndex += 1
            }
        }
        
        // Add functional groups
        for functionalGroup in structure.functionalGroups {
            addFunctionalGroup(
                functionalGroup,
                to: &model,
                carbonChain: carbonAtoms,
                startingAtomIndex: hydrogenIndex
            )
        }
        
        return model
    }
    
    // MARK: - Non-Carbon Structures (Ammonia, Water, etc.)
    private static func generateNonCarbonStructure(from structure: ChemicalStructure, name: String) -> Model3D {
        var model = Model3D(name: name)
        
        // Try to determine structure from name
        if name.lowercased().contains("ammonia") || name.lowercased().contains("nh3") {
            // NH3: Nitrogen at center, 3 hydrogens
            let nitrogen = Atom3D(element: .nitrogen, position: SCNVector3(0, 0, 0))
            model.addAtom(nitrogen)
            
            let hydrogenPositions = [
                SCNVector3(0, 1.0, 0),
                SCNVector3(0.943, -0.333, 0),
                SCNVector3(-0.943, -0.333, 0)
            ]
            
            for (index, pos) in hydrogenPositions.enumerated() {
                let hydrogen = Atom3D(element: .hydrogen, position: pos)
                model.addAtom(hydrogen)
                
                let bond = Bond3D(
                    from: 0,
                    to: index + 1,
                    type: .single,
                    length: 1.01
                )
                model.addBond(bond)
            }
        } else if name.lowercased().contains("water") || name.lowercased().contains("h2o") {
            // H2O: Oxygen at center, 2 hydrogens
            let oxygen = Atom3D(element: .oxygen, position: SCNVector3(0, 0, 0))
            model.addAtom(oxygen)
            
            let angle: Float = 104.5 * Float.pi / 180
            let hydrogenPositions = [
                SCNVector3(0.96 * sin(angle/2), 0.96 * cos(angle/2), 0),
                SCNVector3(-0.96 * sin(angle/2), 0.96 * cos(angle/2), 0)
            ]
            
            for (index, pos) in hydrogenPositions.enumerated() {
                let hydrogen = Atom3D(element: .hydrogen, position: pos)
                model.addAtom(hydrogen)
                
                let bond = Bond3D(
                    from: 0,
                    to: index + 1,
                    type: .single,
                    length: 0.96
                )
                model.addBond(bond)
            }
        }
        
        return model
    }
    
    // MARK: - Carbon Backbone Generation
    private static func generateCarbonBackbone(length: Int) -> [SCNVector3] {
        var positions: [SCNVector3] = []
        
        let angleY = Float.pi / 6  // 30 degrees for zigzag
        
        for i in 0..<length {
            let angle = Float(i) * angleY
            let x = Float(i) * Self.structureSpacing * cos(angle)
            let y = Float(i) * Self.structureSpacing * sin(angle)
            let z: Float = 0
            
            positions.append(SCNVector3(x, y, z))
        }
        
        return positions
    }
    
    // MARK: - Hydrogen Position Generation
    private static func generateHydrogenPositions(
        aroundAtom atom: Atom3D,
        count: Int
    ) -> [SCNVector3] {
        var positions: [SCNVector3] = []
        let distance = Self.carbonHydrogenLength
        
        switch count {
        case 0:
            break
        case 1:
            positions.append(SCNVector3(
                atom.position.x + distance,
                atom.position.y,
                atom.position.z
            ))
        case 2:
            positions.append(SCNVector3(
                atom.position.x + distance * cos(0),
                atom.position.y + distance * sin(0),
                atom.position.z
            ))
            positions.append(SCNVector3(
                atom.position.x + distance * cos(Float.pi * 2/3),
                atom.position.y + distance * sin(Float.pi * 2/3),
                atom.position.z
            ))
        case 3:
            for j in 0..<3 {
                let angle = Float(j) * Float.pi * 2 / 3
                positions.append(SCNVector3(
                    atom.position.x + distance * cos(angle),
                    atom.position.y + distance * sin(angle),
                    atom.position.z
                ))
            }
        default:
            for j in 0..<count {
                let angle = Float(j) * Float.pi * 2 / Float(count)
                positions.append(SCNVector3(
                    atom.position.x + distance * cos(angle),
                    atom.position.y + distance * sin(angle),
                    atom.position.z + Float(j % 2) * 0.5
                ))
            }
        }
        
        return positions
    }
    
    // MARK: - Helper Methods
    private static func calculateHydrogenCount(
        carbonIndex: Int,
        totalCarbons: Int,
        bonds: [Bond],
        functionalGroups: [FunctionalGroupAttachment]
    ) -> Int {
        var hydrogenCount = 4
        
        // Subtract bonds to other carbons
        for bond in bonds {
            if bond.fromCarbon == carbonIndex || bond.toCarbon == carbonIndex {
                hydrogenCount -= 1
            }
        }
        
        // Subtract bonds to functional groups
        for group in functionalGroups {
            if group.carbonPosition == carbonIndex {
                hydrogenCount -= 1
            }
        }
        
        return max(0, hydrogenCount)
    }
    
    private static func convertBondType(_ bondType: BondType) -> BondType3D {
        switch bondType {
        case .single:
            return .single
        case .double:
            return .double
        case .triple:
            return .triple
        }
    }
    
    // MARK: - Functional Groups
    private static func addFunctionalGroup(
        _ group: FunctionalGroupAttachment,
        to model: inout Model3D,
        carbonChain: [Int],
        startingAtomIndex: Int
    ) {
        guard carbonChain.indices.contains(group.carbonPosition) else { return }
        
        let carbonAtomIndex = carbonChain[group.carbonPosition]
        let carbonAtom = model.atoms[carbonAtomIndex]
        
        switch group.group {
        case .alcohol:
            addHydroxylGroup(to: &model, attachedToAtom: carbonAtomIndex, carbonAtom: carbonAtom)
        case .ketone:
            addCarbonylGroup(to: &model, attachedToAtom: carbonAtomIndex, carbonAtom: carbonAtom)
        case .carboxylicAcid:
            addCarboxylGroup(to: &model, attachedToAtom: carbonAtomIndex, carbonAtom: carbonAtom)
        case .amine:
            addAminoGroup(to: &model, attachedToAtom: carbonAtomIndex, carbonAtom: carbonAtom)
        case .nitro:
            addNitroGroup(to: &model, attachedToAtom: carbonAtomIndex, carbonAtom: carbonAtom)
        default:
            break
        }
    }
    
    private static func addHydroxylGroup(
        to model: inout Model3D,
        attachedToAtom: Int,
        carbonAtom: Atom3D
    ) {
        let oxygenPos = SCNVector3(
            carbonAtom.position.x,
            carbonAtom.position.y + 1.4,
            carbonAtom.position.z
        )
        let oxygen = Atom3D(element: .oxygen, position: oxygenPos)
        let oxygenIndex = model.atoms.count
        model.addAtom(oxygen)
        
        let cOBond = Bond3D(from: attachedToAtom, to: oxygenIndex, type: .single, length: 1.43)
        model.addBond(cOBond)
        
        let hydrogenPos = SCNVector3(
            oxygenPos.x,
            oxygenPos.y + 0.96,
            oxygenPos.z
        )
        let hydrogen = Atom3D(element: .hydrogen, position: hydrogenPos)
        let hydrogenIndex = model.atoms.count
        model.addAtom(hydrogen)
        
        let oHBond = Bond3D(from: oxygenIndex, to: hydrogenIndex, type: .single, length: 0.96)
        model.addBond(oHBond)
    }
    
    private static func addCarbonylGroup(
        to model: inout Model3D,
        attachedToAtom: Int,
        carbonAtom: Atom3D
    ) {
        let oxygenPos = SCNVector3(
            carbonAtom.position.x,
            carbonAtom.position.y + 1.2,
            carbonAtom.position.z
        )
        let oxygen = Atom3D(element: .oxygen, position: oxygenPos)
        let oxygenIndex = model.atoms.count
        model.addAtom(oxygen)
        
        let cOBond = Bond3D(from: attachedToAtom, to: oxygenIndex, type: .double, length: 1.23)
        model.addBond(cOBond)
    }
    
    private static func addCarboxylGroup(
        to model: inout Model3D,
        attachedToAtom: Int,
        carbonAtom: Atom3D
    ) {
        // Add C=O and O-H
        let c1Pos = SCNVector3(
            carbonAtom.position.x,
            carbonAtom.position.y + 1.5,
            carbonAtom.position.z
        )
        let carbon = Atom3D(element: .carbon, position: c1Pos)
        let carbonIndex = model.atoms.count
        model.addAtom(carbon)
        
        let ccBond = Bond3D(from: attachedToAtom, to: carbonIndex, type: .single, length: 1.54)
        model.addBond(ccBond)
        
        addCarbonylGroup(to: &model, attachedToAtom: carbonIndex, carbonAtom: carbon)
        
        let oxygenPos = SCNVector3(c1Pos.x - 1.2, c1Pos.y, c1Pos.z)
        let oxygen = Atom3D(element: .oxygen, position: oxygenPos)
        let oxygenIndex = model.atoms.count
        model.addAtom(oxygen)
        
        let cOBond = Bond3D(from: carbonIndex, to: oxygenIndex, type: .single, length: 1.36)
        model.addBond(cOBond)
        
        let hydrogenPos = SCNVector3(oxygenPos.x - 0.96, oxygenPos.y, oxygenPos.z)
        let hydrogen = Atom3D(element: .hydrogen, position: hydrogenPos)
        let hydrogenIndex = model.atoms.count
        model.addAtom(hydrogen)
        
        let oHBond = Bond3D(from: oxygenIndex, to: hydrogenIndex, type: .single, length: 0.96)
        model.addBond(oHBond)
    }
    
    private static func addAminoGroup(
        to model: inout Model3D,
        attachedToAtom: Int,
        carbonAtom: Atom3D
    ) {
        let nitrogenPos = SCNVector3(
            carbonAtom.position.x,
            carbonAtom.position.y + 1.47,
            carbonAtom.position.z
        )
        let nitrogen = Atom3D(element: .nitrogen, position: nitrogenPos)
        let nitrogenIndex = model.atoms.count
        model.addAtom(nitrogen)
        
        let cNBond = Bond3D(from: attachedToAtom, to: nitrogenIndex, type: .single, length: 1.47)
        model.addBond(cNBond)
        
        for i in 0..<2 {
            let angle = Float(i) * Float.pi / 1.5
            let hydrogenPos = SCNVector3(
                nitrogenPos.x + 1.01 * cos(angle),
                nitrogenPos.y + 1.01 * sin(angle),
                nitrogenPos.z
            )
            let hydrogen = Atom3D(element: .hydrogen, position: hydrogenPos)
            let hydrogenIndex = model.atoms.count
            model.addAtom(hydrogen)
            
            let nHBond = Bond3D(from: nitrogenIndex, to: hydrogenIndex, type: .single, length: 1.01)
            model.addBond(nHBond)
        }
    }
    
    private static func addNitroGroup(
        to model: inout Model3D,
        attachedToAtom: Int,
        carbonAtom: Atom3D
    ) {
        let nitrogenPos = SCNVector3(
            carbonAtom.position.x,
            carbonAtom.position.y + 1.47,
            carbonAtom.position.z
        )
        let nitrogen = Atom3D(element: .nitrogen, position: nitrogenPos)
        let nitrogenIndex = model.atoms.count
        model.addAtom(nitrogen)
        
        let cNBond = Bond3D(from: attachedToAtom, to: nitrogenIndex, type: .single, length: 1.47)
        model.addBond(cNBond)
        
        let oxygen1Pos = SCNVector3(nitrogenPos.x + 1.2, nitrogenPos.y, nitrogenPos.z)
        let oxygen1 = Atom3D(element: .oxygen, position: oxygen1Pos)
        let oxygen1Index = model.atoms.count
        model.addAtom(oxygen1)
        
        let nO1Bond = Bond3D(from: nitrogenIndex, to: oxygen1Index, type: .double, length: 1.21)
        model.addBond(nO1Bond)
        
        let oxygen2Pos = SCNVector3(nitrogenPos.x - 1.2, nitrogenPos.y, nitrogenPos.z)
        let oxygen2 = Atom3D(element: .oxygen, position: oxygen2Pos)
        let oxygen2Index = model.atoms.count
        model.addAtom(oxygen2)
        
        let nO2Bond = Bond3D(from: nitrogenIndex, to: oxygen2Index, type: .single, length: 1.27)
        model.addBond(nO2Bond)
    }
}
