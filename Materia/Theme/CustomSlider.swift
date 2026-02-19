//
//  CustomSlider.swift
//  Materia
//
//  Created by Anubhav Dubey on 01/02/26.
//

import SwiftUI

struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let label: String?
    let tintColor: Color
    let trackHeight: CGFloat
    
    init(
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double = 1,
        label: String? = nil,
        tintColor: Color = Color("MateriaPrimary"),
        trackHeight: CGFloat = 8
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.label = label
        self.tintColor = tintColor
        self.trackHeight = trackHeight
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let label = label {
                HStack {
                    Text(label)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("MateriaTextPrimary"))
                    
                    Spacer()
                    
                    Text(String(format: "%.0f", value))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color("MateriaAccent"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(tintColor.opacity(0.15))
                        .cornerRadius(6)
                }
            }
            
            // Custom slider track
            GeometryReader { geometry in
                let progress = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
                let filledWidth = progress * geometry.size.width

                ZStack(alignment: .leading) {

                    // MARK: - Track
                    RoundedRectangle(cornerRadius: trackHeight / 2)
                        .fill(Color("MateriaSurface"))
                        .overlay(
                            RoundedRectangle(cornerRadius: trackHeight / 2)
                                .stroke(Color("MateriaTextPrimary").opacity(0.1), lineWidth: 1)
                        )

                    // MARK: - Filled Track
                    RoundedRectangle(cornerRadius: trackHeight / 2)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    tintColor,
                                    tintColor.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: filledWidth)

                }
                .frame(height: trackHeight)
//                .overlay(
//                    // MARK: - Thumb (Overlayed ABOVE track)
//                    Circle()
//                        .fill(Color.white)
//                        .frame(width: 24, height: 24)
//                        .shadow(color: tintColor.opacity(0.35), radius: 6, x: 0, y: 3)
//                        .overlay(
//                            Circle()
//                                .stroke(tintColor, lineWidth: 2.5)
//                        )
//                        .offset(
//                            x: filledWidth - 12,
//                            y: -(12 - trackHeight) / 2
//                        )
//                )
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let percentage = min(max(gesture.location.x / geometry.size.width, 0), 1)
                            let newValue = range.lowerBound + percentage * (range.upperBound - range.lowerBound)
                            let steppedValue = (newValue / step).rounded() * step
                            value = min(range.upperBound, max(range.lowerBound, steppedValue))
                        }
                        .onEnded { _ in
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                )
            }
            .frame(height: trackHeight)

        }
    }
}

// MARK: - Preview
#Preview {
    @State var value: Double = 5
    return VStack(spacing: 30) {
        CustomSlider(
            value: $value,
            in: 1...10,
            step: 1,
            label: "Carbon Chain Length"
        )
        
        CustomSlider(
            value: $value,
            in: 0...100,
            step: 5,
            label: "Temperature",
            tintColor: Color("MateriaAccent")
        )
        
        CustomSlider(
            value: $value,
            in: 1...5,
            step: 0.5,
            label: "Bond Strength",
            tintColor: Color("MateriaSecondary")
        )
    }
    .padding()
    .background(Color("MateriaBackground"))
}
