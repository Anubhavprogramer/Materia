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
                
                // Build Compound Button
                Button(action: {
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
                            CompoundRowView(compound: compound)
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
                        
                        Text("Build your first molecular structure to identify chemical compounds")
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
            CompoundBuilderView { compound in
                viewModel.saveCompound(compound)
            }
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

#Preview {
    NavigationStack {
        HomeView()
    }
}