//
//  HomeView.swift
//  Materia
//
//  Home screen showing saved compounds and navigation to builder
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingBuilder = false
    @State private var quickStartStructure: ChemicalStructure?
    @State private var selectedCompound: IdentifiedCompound?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "atom")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Materia")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Chemical Structure Identifier")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Quick Start examples
                QuickStartSection { structure in
                    quickStartStructure = structure
                    showingBuilder = true
                }
                .padding(.horizontal)
                
                // Build Compound Button
                Button(action: {
                    quickStartStructure = nil
                    showingBuilder = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Build Compound")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.top)
            .background(Color(.systemGroupedBackground))
            
            // Saved Compounds List
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading compounds...")
                Spacer()
            } else if viewModel.hasCompounds {
                List {
                    Section {
                        ForEach(viewModel.savedCompounds) { compound in
                            Button {
                                selectedCompound = compound
                            } label: {
                                CompoundRowView(compound: compound)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: viewModel.deleteCompound)
                    } header: {
                        HStack {
                            Text("Saved Compounds")
                            Spacer()
                            Text("\(viewModel.compoundCount)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            } else {
                // Empty State
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "flask")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 8) {
                        Text("No Compounds Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Start with an example, or build your first molecular structure to identify chemical compounds")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingBuilder) {
            CompoundBuilderView(initialStructure: quickStartStructure) { compound in
                viewModel.saveCompound(compound)
            }
        }
        .sheet(item: $selectedCompound) { compound in
            CompoundDetailView(compound: compound)
        }
    }
}

// MARK: - Quick Start
private struct QuickStartSection: View {
    let onSelect: (ChemicalStructure) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Quick Start")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            Text("Tap an example to prefill the builder")
                .font(.caption)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    QuickStartChip(title: "Ethanol", subtitle: "C₂H₆O") {
                        var s = ChemicalStructure(carbonChainLength: 2)
                        s.functionalGroups.append(FunctionalGroupAttachment(position: 2, group: .alcohol))
                        onSelect(s)
                    }

                    QuickStartChip(title: "Ethene", subtitle: "C₂H₄") {
                        var s = ChemicalStructure(carbonChainLength: 2)
                        s.bonds.removeAll()
                        s.bonds.append(Bond(from: 1, to: 2, type: .double))
                        onSelect(s)
                    }

                    QuickStartChip(title: "Ethyne", subtitle: "C₂H₂") {
                        var s = ChemicalStructure(carbonChainLength: 2)
                        s.bonds.removeAll()
                        s.bonds.append(Bond(from: 1, to: 2, type: .triple))
                        onSelect(s)
                    }

                    QuickStartChip(title: "Acetic acid", subtitle: "C₂H₄O₂") {
                        var s = ChemicalStructure(carbonChainLength: 2)
                        s.functionalGroups.append(FunctionalGroupAttachment(position: 2, group: .carboxylicAcid))
                        onSelect(s)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

private struct QuickStartChip: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

struct CompoundRowView: View {
    let compound: IdentifiedCompound
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(compound.compoundName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(compound.iupacName)
                        .font(.subheadline)
                        .foregroundColor(.purple)
                        .fontWeight(.medium)
                    
                    Text(compound.molecularFormula)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(compound.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        
                        // CoreML validation indicator
                        if let isValidated = compound.isValidated {
                            Image(systemName: isValidated ? "brain.head.profile" : "exclamationmark.triangle")
                                .foregroundColor(isValidated ? .green : .orange)
                                .font(.caption)
                        }
                    }
                    
                    // Confidence indicator
                    if let confidence = compound.confidence {
                        HStack(spacing: 2) {
                            Image(systemName: "brain.head.profile")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            
                            Text("\(Int(confidence * 100))%")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(compound.identifiedAt, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Structure preview
            HStack {
                Text("Structure:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(compound.structure.toSMILESLike())
                    .font(.system(.caption, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray6))
                    .cornerRadius(4)
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Compound Details
private struct CompoundDetailView: View {
    let compound: IdentifiedCompound
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CompoundResultView(compound: compound, canSave: false) { _ in
            // no-op (read-only)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}