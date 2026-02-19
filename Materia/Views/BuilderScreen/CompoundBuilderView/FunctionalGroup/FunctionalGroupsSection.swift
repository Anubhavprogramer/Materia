//
//  FunctionalGroupsSection.swift
//  Materia
//
//  Functional groups configuration UI
//

import SwiftUI

struct FunctionalGroupsSection: View {
    @ObservedObject var viewModel: CompoundBuilderViewModel
    @EnvironmentObject var toastManager: ToastManager
    @State private var selectedCarbon: Int = 1
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppStrings.functionalGroups)
                .font(.headline)
                .fontWeight(.semibold)
            
            // Carbon position selector
            VStack(alignment: .leading, spacing: 8) {
                Text(AppStrings.functionalGroupstext)
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
                                    .frame(width: AppConstants.functionalGroupCardWidth, height: AppConstants.functionalGroupCardHeight)
                                    .background(
                                        selectedCarbon == carbon
                                        ? AppColors.white
                                        : Color(AppColors.secondary)
                                    )
                                    .foregroundColor(
                                        selectedCarbon == carbon
                                        ? AppColors.accent
                                        : AppColors.textPrimary
                                    )
                                    .cornerRadius(AppConstants.smallCornerRadius)
                            }
                        }
                    }
//                    .padding(.horizontal)
                }
            }
            
            // Functional groups grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: AppConstants.defaultPadding) {
                ForEach(FunctionalGroup.allCases, id: \.self) { group in
                    FunctionalGroupButton(
                        group: group,
                        isAttached: viewModel.getFunctionalGroups(at: selectedCarbon).contains(group),
                        action: {
                            if viewModel.getFunctionalGroups(at: selectedCarbon).contains(group) {
                                viewModel.removeFunctionalGroup(group, at: selectedCarbon)
                                // Show removal toast
                                toastManager.show(
                                    "\(group.displayName) removed from C\(selectedCarbon)",
                                    type: .info
                                )
                            } else {
                                viewModel.addFunctionalGroup(group, at: selectedCarbon)
                                // Show addition toast
                                toastManager.show(
                                    "\(group.displayName) added to C\(selectedCarbon)",
                                    type: .success
                                )
                            }
                        }
                    )
                }
            }
            
            // Current attachments for selected carbon
            if !viewModel.getFunctionalGroups(at: selectedCarbon).isEmpty {
                VStack(alignment: .leading, spacing: AppConstants.defaultGap) {
                    Text("Attached to C\(selectedCarbon):")
                        .font(.caption)
                        .foregroundColor(.secondary)
                
                    HStack(spacing: 8) {
                        ForEach(viewModel.getFunctionalGroups(at: selectedCarbon), id: \.self) { group in
                            Text(group.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.accent)
                                .foregroundColor(AppColors.white)
                                .cornerRadius(AppConstants.smallCornerRadius)
                        }
                    }
                }
            }
        }
        .padding()
        .background(AppColors.Card)
        .cornerRadius(AppConstants.largeCornerRadius)
//        .padding(.horizontal)
        .onAppear {
            selectedCarbon = min(selectedCarbon, viewModel.carbonChainLength)
        }
        .onChange(of: viewModel.carbonChainLength) { _, newLength in
            selectedCarbon = min(selectedCarbon, newLength)
        }
    }
}

#Preview {
    FunctionalGroupsSection(viewModel: CompoundBuilderViewModel())
}
