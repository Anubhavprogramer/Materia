import SwiftUI

struct CollaborativeBuilderLiveView: View {
    @ObservedObject var viewModel: CollaborativeBuilderViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.gradientStart.opacity(0.1),
                    AppColors.gradientEnd.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppConstants.defaultPadding) {
                    // Header with role and status
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your Role")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                HStack(spacing: 8) {
                                    Image(systemName: viewModel.role == .builderA ? "person.fill.badge.plus" : "person.fill.checkmark")
                                        .foregroundColor(AppColors.accent)
                                    
                                    Text(viewModel.role?.rawValue ?? "—")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(AppColors.textPrimary)
                                }
                            }
                            
                            Spacer()
                            
                            // Validation status
                            if let v = viewModel.lastValidation {
                                VStack(alignment: .trailing, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Image(systemName: v.isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                            .foregroundColor(v.isValid ? .green : .orange)
                                            .font(.system(size: 16))
                                        
                                        Text(v.isValid ? "Valid" : "Invalid")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(v.isValid ? .green : .orange)
                                    }
                                    
                                    Text(v.message ?? "")
                                        .font(.caption2)
                                        .foregroundColor(AppColors.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(AppConstants.defaultPadding)
                        .background(AppColors.Card)
                        .cornerRadius(AppConstants.defaultCornerRadius)
                    }
                    .padding(.horizontal, AppConstants.defaultPadding)
                    
                    // IUPAC Name
                    if let v = viewModel.lastValidation, !v.iupacName.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("IUPAC Name", systemImage: "book.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(v.iupacName)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.purple)
                                .padding(AppConstants.defaultPadding)
                                .background(AppColors.Card)
                                .cornerRadius(AppConstants.defaultCornerRadius)
                        }
                        .padding(.horizontal, AppConstants.defaultPadding)
                    }
                    
                    // Structure Diagram
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Structure Preview", systemImage: "cube.transparent")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        StructureDiagramView(structure: viewModel.sessionState.structure)
                            .frame(height: 180)
                            .background(AppColors.Card)
                            .cornerRadius(AppConstants.defaultCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppConstants.defaultCornerRadius)
                                    .stroke(AppColors.accent.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, AppConstants.defaultPadding)
                    
                    // Builder A Controls
                    if viewModel.role == .builderA {
                        builderAControls
                    }
                    
                    // Builder B Controls
                    if viewModel.role == .builderB {
                        builderBControls
                    }
                    
                    // Structure Notation
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Structure Notation", systemImage: "text.alignleft")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(viewModel.sessionState.structure.toSMILESLike())
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(AppConstants.defaultPadding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.Card)
                            .cornerRadius(AppConstants.defaultCornerRadius)
                    }
                    .padding(.horizontal, AppConstants.defaultPadding)
                    
                    Spacer()
                        .frame(height: AppConstants.largePadding)
                }
                .padding(.vertical, AppConstants.defaultPadding)
            }
        }
    }
    
    // MARK: - Builder A Controls (Chain & Bonds)
    private var builderAControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "1.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.accent)
                
                Text("Builder A - Structure Controls")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            // Carbon Chain Length
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Carbon Chain Length", systemImage: "link.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            if viewModel.sessionState.structure.carbonChainLength > 1 {
                                viewModel.setCarbonChainLength(viewModel.sessionState.structure.carbonChainLength - 1)
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(AppColors.accent)
                                .font(.system(size: 22))
                        }
                        
                        Text("\(viewModel.sessionState.structure.carbonChainLength)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                            .frame(width: 40, alignment: .center)
                        
                        Button(action: {
                            if viewModel.sessionState.structure.carbonChainLength < 10 {
                                viewModel.setCarbonChainLength(viewModel.sessionState.structure.carbonChainLength + 1)
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(AppColors.accent)
                                .font(.system(size: 22))
                        }
                    }
                }
                .padding(AppConstants.defaultPadding)
                .background(AppColors.Card)
                .cornerRadius(AppConstants.defaultCornerRadius)
            }
            
            // Bond Configuration
            if viewModel.sessionState.structure.carbonChainLength > 1 {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Configure Bonds", systemImage: "bolt.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    VStack(spacing: 10) {
                        ForEach(Array(1..<viewModel.sessionState.structure.carbonChainLength), id: \.self) { i in
                            HStack(spacing: 12) {
                                Text("C\(i)–C\(i+1)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.textPrimary)
                                    .frame(width: 50, alignment: .leading)
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    ForEach(BondType.allCases, id: \.self) { bondType in
                                        let bondKey = viewModel.getBondType(from: i, to: i + 1)
                                        let isSelected = bondKey == bondType
                                        
                                        Button(action: { viewModel.setBond(from: i, to: i + 1, type: bondType) }) {
                                            Text(bondType.symbol)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(isSelected ? AppColors.white : AppColors.accent)
                                                .frame(width: 36, height: 36)
                                                .background(isSelected ? AppColors.accent : AppColors.accent.opacity(0.1))
                                                .cornerRadius(AppConstants.smallCornerRadius)
                                        }
                                    }
                                }
                            }
                            .padding(AppConstants.defaultPadding)
                            .background(AppColors.Card)
                            .cornerRadius(AppConstants.defaultCornerRadius)
                        }
                    }
                }
            }
        }
        .padding(AppConstants.defaultPadding)
        .background(AppColors.accent.opacity(0.1))
        .cornerRadius(AppConstants.defaultCornerRadius)
        .padding(.horizontal, AppConstants.defaultPadding)
    }
    
    // MARK: - Builder B Controls (Functional Groups)
    private var builderBControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "2.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.accent)
                
                Text("Builder B - Functional Groups")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            let structure = viewModel.sessionState.structure
            
            VStack(spacing: 10) {
                ForEach(1...structure.carbonChainLength, id: \.self) { carbon in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("C\(carbon)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach([FunctionalGroup.alcohol, .amine, .carboxylicAcid, .aldehyde, .ketone, .nitrile, .nitro], id: \.self) { group in
                                    let isAttached = structure.functionalGroups.contains { $0.carbonPosition == carbon && $0.group == group }
                                    
                                    Button(action: {
                                        if isAttached {
                                            viewModel.removeFunctionalGroup(group, at: carbon)
                                        } else {
                                            viewModel.addFunctionalGroup(group, at: carbon)
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: isAttached ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 12, weight: .bold))
                                            
                                            Text(group.rawValue)
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundColor(isAttached ? AppColors.white : AppColors.accent)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(isAttached ? AppColors.accent : AppColors.accent.opacity(0.1))
                                        .cornerRadius(AppConstants.smallCornerRadius)
                                    }
                                }
                            }
                        }
                    }
                    .padding(AppConstants.defaultPadding)
                    .background(AppColors.Card)
                    .cornerRadius(AppConstants.defaultCornerRadius)
                }
            }
        }
        .padding(AppConstants.defaultPadding)
        .background(AppColors.accent.opacity(0.1))
        .cornerRadius(AppConstants.defaultCornerRadius)
        .padding(.horizontal, AppConstants.defaultPadding)
    }
}
