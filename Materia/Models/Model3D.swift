//
//  Model3D.swift
//  Materia
//
//  3D molecular structure data model
//

import Foundation
import SceneKit

// MARK: - Atom Data
struct Atom3D {
    let id: UUID
    let element: ElementType
    let position: SCNVector3
    let radius: Float
    let customColor: SCNVector3?  // For functional group highlighting
    
    init(element: ElementType, position: SCNVector3, customColor: SCNVector3? = nil) {
        self.id = UUID()
        self.element = element
        self.position = position
        self.radius = element.vanDerWaalsRadius
        self.customColor = customColor
    }
}

// MARK: - Bond Data
struct Bond3D {
    let id: UUID
    let fromAtom: Int  // Index in atoms array
    let toAtom: Int    // Index in atoms array
    let bondType: BondType3D
    let length: Float
    
    init(from: Int, to: Int, type: BondType3D, length: Float) {
        self.id = UUID()
        self.fromAtom = min(from, to)
        self.toAtom = max(from, to)
        self.bondType = type
        self.length = length
    }
}

// MARK: - Bond Types for 3D
enum BondType3D: String, Codable {
    case single
    case double
    case triple
    
    var cylinderCount: Int {
        switch self {
        case .single: return 1
        case .double: return 2
        case .triple: return 3
        }
    }
    
    var cylinderRadius: Float {
        switch self {
        case .single: return 0.08
        case .double: return 0.06
        case .triple: return 0.05
        }
    }
}

// MARK: - Element Type for 3D
enum ElementType: String, Codable {
    case carbon = "C"
    case hydrogen = "H"
    case oxygen = "O"
    case nitrogen = "N"
    case sulfur = "S"
    case phosphorus = "P"
    case chlorine = "Cl"
    case fluorine = "F"
    case bromine = "Br"
    case iodine = "I"
    
    // MARK: - Visual Properties
    var color: SCNVector3 {
        switch self {
        case .carbon: return SCNVector3(0.3, 0.3, 0.3)      // Gray
        case .hydrogen: return SCNVector3(1.0, 1.0, 1.0)    // White
        case .oxygen: return SCNVector3(1.0, 0.0, 0.0)      // Red
        case .nitrogen: return SCNVector3(0.0, 0.0, 1.0)    // Blue
        case .sulfur: return SCNVector3(1.0, 1.0, 0.0)      // Yellow
        case .phosphorus: return SCNVector3(1.0, 0.65, 0.0) // Orange
        case .chlorine: return SCNVector3(0.0, 1.0, 0.0)    // Green
        case .fluorine: return SCNVector3(0.0, 1.0, 0.5)    // Cyan
        case .bromine: return SCNVector3(0.65, 0.16, 0.16)  // Brown
        case .iodine: return SCNVector3(0.5, 0.0, 0.5)      // Purple
        }
    }
    
    var vanDerWaalsRadius: Float {
        // In Angstroms (scaled for visualization)
        switch self {
        case .carbon: return 1.7
        case .hydrogen: return 1.2
        case .oxygen: return 1.52
        case .nitrogen: return 1.55
        case .sulfur: return 1.8
        case .phosphorus: return 1.8
        case .chlorine: return 1.75
        case .fluorine: return 1.47
        case .bromine: return 1.85
        case .iodine: return 1.98
        }
    }
    
    var displayName: String {
        switch self {
        case .carbon: return "Carbon"
        case .hydrogen: return "Hydrogen"
        case .oxygen: return "Oxygen"
        case .nitrogen: return "Nitrogen"
        case .sulfur: return "Sulfur"
        case .phosphorus: return "Phosphorus"
        case .chlorine: return "Chlorine"
        case .fluorine: return "Fluorine"
        case .bromine: return "Bromine"
        case .iodine: return "Iodine"
        }
    }
}

// MARK: - 3D Molecule Model
struct Model3D {
    let id: UUID
    var atoms: [Atom3D]
    var bonds: [Bond3D]
    let name: String
    let bounds: (min: SCNVector3, max: SCNVector3)
    
    init(name: String) {
        self.id = UUID()
        self.atoms = []
        self.bonds = []
        self.name = name
        self.bounds = (min: SCNVector3(0, 0, 0), max: SCNVector3(0, 0, 0))
    }
    
    mutating func addAtom(_ atom: Atom3D) {
        atoms.append(atom)
    }
    
    mutating func addBond(_ bond: Bond3D) {
        bonds.append(bond)
    }
    
    mutating func calculateBounds() -> (min: SCNVector3, max: SCNVector3) {
        guard !atoms.isEmpty else {
            return (min: SCNVector3(0, 0, 0), max: SCNVector3(0, 0, 0))
        }
        
        var minX = atoms[0].position.x
        var minY = atoms[0].position.y
        var minZ = atoms[0].position.z
        var maxX = atoms[0].position.x
        var maxY = atoms[0].position.y
        var maxZ = atoms[0].position.z
        
        for atom in atoms {
            minX = min(minX, atom.position.x)
            minY = min(minY, atom.position.y)
            minZ = min(minZ, atom.position.z)
            maxX = max(maxX, atom.position.x)
            maxY = max(maxY, atom.position.y)
            maxZ = max(maxZ, atom.position.z)
        }
        
        return (min: SCNVector3(minX, minY, minZ), max: SCNVector3(maxX, maxY, maxZ))
    }
    
    var atomCount: Int { atoms.count }
    var bondCount: Int { bonds.count }
}
