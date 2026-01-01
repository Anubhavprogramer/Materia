//
//  FunctionalGroupsSection.swift
//  Materia
//
//  Functional groups configuration UI
//

import SwiftUI

struct FunctionalGroupsSection: View {
    @ObservedObject var viewModel: CompoundBuilderViewModel
    @State private var selectedCarbon: Int = 1
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Functional Groups")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Carbon position selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Add to carbon position:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(1...viewModel.carbonChainLength, id: \.self) { carbon in
                            Button(action: {
                                selectedCarbon = carbon
                            }) {
                                Text("C\(carbon)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(width: 40, height: 32)
                                    .background(
                                        selectedCarbon == carbon
                                            ? Color.blue
                                            : Color(.systemGray5)
                                    )
                                    .foregroundColor(
                                        selectedCarbon == carbon
                                            ? .white
                                            : .primary
                                    )
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Functional groups grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(FunctionalGroup.allCases, id: \.self) { group in
                    FunctionalGroupButton(
                        group: group,
                        isAttached: viewModel.getFunctionalGroups(at: selectedCarbon).contains(group),
                        action: {
                            if viewModel.getFunctionalGroups(at: selectedCarbon).contains(group) {
                                viewModel.removeFunctionalGroup(group, at: selectedCarbon)
                            } else {
                                viewModel.addFunctionalGroup(group, at: selectedCarbon)
                            }
                        }
                    )
                }
            }
            
            // Current attachments for selected carbon
            if !viewModel.getFunctionalGroups(at: selectedCarbon).isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Attached to C\(selectedCarbon):")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.getFunctionalGroups(at: selectedCarbon), id: \.self) { group in
                                Text(group.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(6)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .onAppear {
            selectedCarbon = min(selectedCarbon, viewModel.carbonChainLength)
        }
        .onChange(of: viewModel.carbonChainLength) { newLength in
            selectedCarbon = min(selectedCarbon, newLength)
        }
    }
}

struct FunctionalGroupButton: View {
    let group: FunctionalGroup
    let isAttached: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(group.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(group.displayName.components(separatedBy: " (").first ?? "")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isAttached
                    ? Color.green.opacity(0.2)
                    : Color(.systemGray5)
            )
            .foregroundColor(
                isAttached
                    ? .green
                    : .primary
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isAttached ? Color.green : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}

#Preview {
    FunctionalGroupsSection(viewModel: CompoundBuilderViewModel())
}