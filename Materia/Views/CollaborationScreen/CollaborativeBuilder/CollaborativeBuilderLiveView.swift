import SwiftUI

struct CollaborativeBuilderLiveView: View {
    @ObservedObject var viewModel: CollaborativeBuilderViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Role:")
                    .foregroundColor(.secondary)
                Text(viewModel.role?.rawValue ?? "—")
                    .fontWeight(.semibold)
                Spacer()
            }

            if let v = viewModel.lastValidation {
                HStack {
                    Image(systemName: v.isValid ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(v.isValid ? .green : .orange)
                    Text(v.message ?? (v.isValid ? "Valid" : "Invalid"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }

                Text("IUPAC: \(v.iupacName)")
                    .font(.headline)
                    .foregroundColor(.purple)
            }

            // Live structure diagram
            StructureDiagramView(structure: viewModel.sessionState.structure)
                .frame(height: 150)
                .background(AppColors.Card)
                .cornerRadius(AppConstants.largeCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )

            // Controls: A gets chain/bonds. B gets functional groups.
            if viewModel.role == .builderA {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Builder A Controls")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    HStack {
                        Text("Chain")
                        Spacer()
                        Stepper("\(viewModel.sessionState.structure.carbonChainLength)", value: Binding(
                            get: { viewModel.sessionState.structure.carbonChainLength },
                            set: { viewModel.setCarbonChainLength($0) }
                        ), in: 1...10)
                        .labelsHidden()
                    }

                    if viewModel.sessionState.structure.carbonChainLength > 1 {
                        ForEach(1..<viewModel.sessionState.structure.carbonChainLength, id: \.self) { i in
                            HStack {
                                Text("C\(i)–C\(i+1)")
                                Spacer()
                                ForEach(BondType.allCases, id: \.self) { t in
                                    Button(t.symbol) {
                                        viewModel.setBond(from: i, to: i + 1, type: t)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }

            if viewModel.role == .builderB {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Builder B Controls")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    let structure = viewModel.sessionState.structure
                    ForEach(1...structure.carbonChainLength, id: \.self) { carbon in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                Text("C\(carbon)")
                                    .frame(width: 44, alignment: .leading)

                                ForEach([FunctionalGroup.alcohol, .amine, .carboxylicAcid, .aldehyde, .ketone, .nitrile, .nitro], id: \.self) { group in
                                    let attached = structure.functionalGroups.contains { $0.carbonPosition == carbon && $0.group == group }
                                    Button(attached ? "✓ \(group.rawValue)" : group.rawValue) {
                                        if attached {
                                            viewModel.removeFunctionalGroup(group, at: carbon)
                                        } else {
                                            viewModel.addFunctionalGroup(group, at: carbon)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }

            Text("Structure: \(viewModel.sessionState.structure.toSMILESLike())")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
}
