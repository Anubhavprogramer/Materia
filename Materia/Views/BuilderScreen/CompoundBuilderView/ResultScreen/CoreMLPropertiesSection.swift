//
//  CoreMLPropertiesSection.swift
//  Materia
//
//  Display CoreML-predicted molecular properties
//

import SwiftUI

struct CoreMLPropertiesSection: View {
    let compound: IdentifiedCompound
    @State private var properties: MolecularPropertiesResult?
    @State private var isLoading = false
    @State private var coreMLService: CoreMLChemistryServiceProtocol?
    @State private var lastStructureSignature: String = ""

    // Lightweight signature so we know when to refresh.
    private var structureSignature: String {
        compound.structure.toSMILESLike()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                    .font(.title2)

                Text("AI-Predicted Properties")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            // Explain why predictions can look identical (because the model uses a 5-D feature vector).
            DisclosureGroup("Why can these look the same?") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("The current CoreML model is fed only 5 simplified features (chain length, functional-group score, unsaturation score, heteroatom score, priority score). Different compounds often collapse to similar inputs, so outputs can be very similar.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Structure signature: \(structureSignature)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
            }
            .font(.subheadline)

            if let props = properties {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    PropertyCard(
                        title: "Molecular Weight",
                        value: String(format: "%.1f Da", props.molecularWeight),
                        icon: "scalemass",
                        color: .blue
                    )

                    PropertyCard(
                        title: "LogP",
                        value: String(format: "%.2f", props.logP),
                        icon: "drop",
                        color: .cyan,
                        subtitle: props.isLipophilic ? "Lipophilic" : "Hydrophilic"
                    )

                    PropertyCard(
                        title: "H-Bond Donors",
                        value: "\(props.hBondDonors)",
                        icon: "link",
                        color: .green
                    )

                    PropertyCard(
                        title: "H-Bond Acceptors",
                        value: "\(props.hBondAcceptors)",
                        icon: "link.circle",
                        color: .green
                    )

                    PropertyCard(
                        title: "Rotatable Bonds",
                        value: "\(props.rotatableBonds)",
                        icon: "arrow.triangle.2.circlepath",
                        color: .orange
                    )

                    PropertyCard(
                        title: "TPSA",
                        value: String(format: "%.1f Ų", props.tpsa),
                        icon: "circle.dotted",
                        color: .purple
                    )

                    PropertyCard(
                        title: "Aromatic Rings",
                        value: "\(props.aromaticRings)",
                        icon: "hexagon",
                        color: .indigo
                    )

                    PropertyCard(
                        title: "Drug-likeness",
                        value: props.isLargeMolecule ? "Large" : "Drug-like",
                        icon: props.isLargeMolecule ? "exclamationmark.triangle" : "checkmark.circle",
                        color: props.isLargeMolecule ? .red : .green
                    )
                }

                // Drug-likeness indicators
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lipinski's Rule of Five")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    HStack(spacing: 16) {
                        RuleIndicator(
                            title: "MW < 500",
                            passed: props.molecularWeight < 500,
                            value: String(format: "%.0f", props.molecularWeight)
                        )

                        RuleIndicator(
                            title: "LogP < 5",
                            passed: props.logP < 5,
                            value: String(format: "%.1f", props.logP)
                        )

                        RuleIndicator(
                            title: "HBD ≤ 5",
                            passed: props.hBondDonors <= 5,
                            value: "\(props.hBondDonors)"
                        )

                        RuleIndicator(
                            title: "HBA ≤ 10",
                            passed: props.hBondAcceptors <= 10,
                            value: "\(props.hBondAcceptors)"
                        )
                    }
                }
                .padding(.top, 8)

            } else if !isLoading {
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)

                    Text("Tap to analyze molecular properties")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button {
                        loadProperties(force: true)
                    } label: {
                        Text("Analyze Properties")
                    }
                    .liquidGlassPrimaryButton(tint: .blue, size: .regular, isEnabled: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .task {
            // Create service once for the view lifecycle.
            if coreMLService == nil {
                coreMLService = CoreMLChemistryServiceFactory.createService()
            }

            // Auto-load on first appearance.
            if properties == nil {
                loadProperties(force: false)
            }
        }
        .onChange(of: structureSignature) { _, newValue in
            // If user opens a different compound, refresh.
            if newValue != lastStructureSignature {
                loadProperties(force: false)
            }
        }
    }

    private func loadProperties(force: Bool) {
        guard let service = coreMLService else { return }

        // Avoid repeating the same work unless forced.
        let sig = structureSignature
        if !force, sig == lastStructureSignature, properties != nil {
            return
        }

        lastStructureSignature = sig
        isLoading = true

        Task {
            do {
                let result = try await service.predictProperties(from: compound.structure)
                await MainActor.run {
                    self.properties = result
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("Failed to load properties: \(error)")
                }
            }
        }
    }
}

struct PropertyCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String?

    init(title: String, value: String, icon: String, color: Color, subtitle: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)

                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct RuleIndicator: View {
    let title: String
    let passed: Bool
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(passed ? .green : .red)
                .font(.caption)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(passed ? .green : .red)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let sampleStructure = ChemicalStructure(carbonChainLength: 2)
    let sampleCompound = IdentifiedCompound(
        structure: sampleStructure,
        name: "Ethanol",
        iupacName: "ethanol",
        formula: "C₂H₆O",
        category: "Organic"
    )

    CoreMLPropertiesSection(compound: sampleCompound)
}