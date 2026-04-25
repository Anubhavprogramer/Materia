//
//  StructureDiagramView.swift
//  Materia
//
//  Created by Anubhav Dubey on 01/02/26.
//
import SwiftUI


struct StructureDiagramView: View {
    let structure: ChemicalStructure
    @State private var showFullScreen = false
    
    var body: some View {
        ZStack {
            // Diagram content
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let carbonSpacing = min(width / max(Double(structure.carbonChainLength), 1), 80)
                let startX = (width - carbonSpacing * Double(max(structure.carbonChainLength - 1, 0))) / 2
                
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
                    if structure.carbonChainLength > 0 {
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
            
            // Tap overlay
            VStack {
                HStack {
                    Spacer()
                    Button(action: { showFullScreen = true }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
                Spacer()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showFullScreen = true
        }
        .sheet(isPresented: $showFullScreen) {
            InteractiveStructureDiagramScreen(structure: structure, isPresented: $showFullScreen)
        }
    }
}

// MARK: - Interactive Full-Screen Diagram View
struct InteractiveStructureDiagramScreen: View {
    let structure: ChemicalStructure
    @Binding var isPresented: Bool
    @StateObject private var motionManager = MotionManager()
    @State private var tiltScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.background.opacity(0.95),
                    AppColors.surface.opacity(0.95)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header with close button
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Interactive Diagram")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Tilt your device to explore")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                // Main diagram with tilt effect
                ZStack {
                    // Background card
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AppColors.Card)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    // Diagram content with rotation
                    GeometryReader { geometry in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        let carbonSpacing = min(width / max(Double(structure.carbonChainLength), 1), 100)
                        let startX = (width - carbonSpacing * Double(max(structure.carbonChainLength - 1, 0))) / 2
                        
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
                            if structure.carbonChainLength > 0 {
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
                    .padding(30)
                }
                .frame(height: 300)
                .modifier(
                    TiltModifier(
                        pitch: motionManager.pitch,
                        roll: motionManager.roll
                    )
                )
                .padding()
                
                // Motion information display
                if motionManager.isMotionAvailable {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Device Orientation")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.semibold)
                                
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Pitch").font(.caption2).foregroundColor(.secondary)
                                        Text(String(format: "%.1f°", motionManager.pitch))
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Roll").font(.caption2).foregroundColor(.secondary)
                                        Text(String(format: "%.1f°", motionManager.roll))
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.headline)
                            .foregroundColor(.orange)
                        Text("Motion tracking unavailable")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Info message
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(AppColors.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tilt Interaction").font(.caption).fontWeight(.semibold)
                            Text("Rotate your device to see the structure from different angles")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(AppColors.accent.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .onAppear {
            motionManager.start()
        }
        .onDisappear {
            motionManager.stop()
        }
    }
}

// MARK: - Tilt Modifier
struct TiltModifier: ViewModifier {
    let pitch: Double
    let roll: Double
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(pitch * 0.1),
                axis: (x: 1, y: 0, z: 0)
            )
            .rotation3DEffect(
                .degrees(roll * 0.1),
                axis: (x: 0, y: 0, z: 1)
            )
            .shadow(color: Color.black.opacity(Double(abs(pitch) + abs(roll)) * 0.0005), radius: 8)
    }
}

