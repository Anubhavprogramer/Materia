//
//  Model3DControlPanel.swift
//  Materia
//
//  Control panel for 3D molecular viewer
//

import SwiftUI

struct Model3DControlPanel: View {
    let model3D: Model3D
    let compound: IdentifiedCompound
    
    @Binding var shouldAutoRotate: Bool
    @Binding var showLabels: Bool
    @Binding var isRotating: Bool
    
    var onReset: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Info section
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label(
                        "\(model3D.atomCount) atoms",
                        systemImage: "circle.fill"
                    )
                    .font(.caption)
                    
                    Label(
                        "\(model3D.bondCount) bonds",
                        systemImage: "line.diagonal"
                    )
                    .font(.caption)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(compound.molecularFormula)
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text(compound.compoundName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Control buttons row 1
            HStack(spacing: 12) {
                // Auto-rotate toggle
                Button(action: { shouldAutoRotate.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: shouldAutoRotate ? "pause.circle.fill" : "play.circle.fill")
                        Text(shouldAutoRotate ? "Pause" : "Auto-rotate")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.blue)
                    .cornerRadius(6)
                }
                
                // Labels toggle
                Button(action: { showLabels.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: showLabels ? "abc.fill" : "abc")
                        Text("Labels")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(showLabels ? Color.green : Color.gray)
                    .cornerRadius(6)
                }
            }
            
            // Control buttons row 2
            HStack(spacing: 12) {
                // Reset button
                Button(action: { onReset?() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.orange)
                    .cornerRadius(6)
                }
                
                // Info button (placeholder for future expansion)
                Button(action: { }) {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                        Text("Info")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.purple)
                    .cornerRadius(6)
                }
            }
            
            // Gesture hints
            VStack(alignment: .leading, spacing: 4) {
                Text("Gesture Controls")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("• Drag with 1 finger → Rotate")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("• Pinch with 2 fingers → Zoom")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("• 2-finger rotate → Tilt view")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(6)
        }
        .padding()
        .background(Color.white.opacity(0.95))
        .cornerRadius(8)
    }
}
