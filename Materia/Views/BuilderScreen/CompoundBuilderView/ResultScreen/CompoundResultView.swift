//
//  CompoundResultView.swift
//  Materia
//
//  Results screen showing identified compound information
//

import SwiftUI

struct CompoundResultView: View {
    let compound: IdentifiedCompound?
    let structure: ChemicalStructure?
    let canSave: Bool
    let onSave: (IdentifiedCompound) -> Void
    @Binding var notes: [CompoundNote]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var toastManager: ToastManager
    @State private var isSaved = false
    @State private var showToast = false
    @State private var show3DViewer = false

    @State private var showIUPACExplanation = false
    @State private var modifiedStructure: ChemicalStructure?
    @State private var showCompoundStory = false

    private var activeStructure: ChemicalStructure {
        modifiedStructure ?? structure ?? compound?.structure ?? ChemicalStructure(carbonChainLength: 1)
    }

    private var iupacExplanation: IUPACExplanation {
        // Deterministic + offline explanation.
        let service = CoreMLChemistryServiceFactory.createService()
        return service.explainIUPAC(from: activeStructure)
    }
    
    private var currentCompound: IdentifiedCompound? {
        if let compound = compound {
            // If we have an existing compound, update its notes
            var updatedCompound = compound
            updatedCompound.notes = notes
            return updatedCompound
        }
        
        let structure = activeStructure
        let iupac = iupacExplanation.finalName
        
        // Calculate molecular formula from structure
        let carbonCount = structure.carbonChainLength
        let hydrogenCount = (carbonCount * 2) + 2
        let formula = "C\(carbonCount)H\(hydrogenCount)"
        
        var newCompound = IdentifiedCompound(
            structure: structure,
            name: "Modified Structure",
            iupacName: iupac,
            formula: formula,
            category: "Custom"
        )
        // Include notes in the new compound
        newCompound.notes = notes
        return newCompound
    }
    
    init(compound: IdentifiedCompound? = nil,
         structure: ChemicalStructure? = nil,
         canSave: Bool = true,
         notes: Binding<[CompoundNote]> = .constant([]),
         onSave: @escaping (IdentifiedCompound) -> Void = { _ in }) {
        self.compound = compound
        self.structure = structure
        self.canSave = canSave
        self._notes = notes
        self.onSave = onSave
        _modifiedStructure = State(initialValue: structure ?? compound?.structure)
    }

    
    var body: some View {
        // ZStack {
            // NavigationStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Educational Mode: Story Button
                        VStack(alignment: .leading, spacing: AppConstants.defaultGap) {
                            HStack {
                                Image(systemName: "graduationcap")
                                    .foregroundColor(AppColors.accent)
                                Text("Learn How It's Built")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                
                                // Circular Button with Apple Intelligence Icon
                                Button(action: { showCompoundStory = true }) {
                                    Image(systemName: "sparkles")
                                        .font(.headline)
                                        .foregroundColor(AppColors.accent)
                                }
                                .frame(width: 30, height: 30)
                                .background(AppColors.Card)
                                .clipShape(Circle())
                            }
                            
                            InfoCardView(
                                icon: "info.circle.fill",
                                title: "Info",
                                message: "Tap the button to see how this compound is built step by step.",
                                accentColor: AppColors.accent,
                                backgroundColor: AppColors.accentLight,
                                borderColor: Color.blue.opacity(0.3)
                            )
                        }
                        .padding(AppConstants.defaultPadding)
                        .background(AppColors.surface)
                        .cornerRadius(AppConstants.defaultCornerRadius)
                        .padding(.horizontal)
                        .sheet(isPresented: $showCompoundStory) {
                            if let comp = currentCompound {
                                CompoundStoryScreen(compound: comp, iupacExplanation: iupacExplanation)
                            }
                        }
                        
                        // Compound Information Card
                        VStack(spacing: 20) {
                            // Common Name
                            HStack(spacing: 8) {
                                Text("Common Name")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(currentCompound?.compoundName ?? "—")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(AppColors.accent)
                            }
                            
                            Divider()
                            
                            // IUPAC Name
                            HStack(spacing: 8) {
                                Text("IUPAC Name")
                                    .font(.headline)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text(currentCompound?.iupacName ?? "—")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.accent.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                            
                            Divider()
                            
                            // Molecular Formula
                            HStack(spacing: 8) {
                                Text("Molecular Formula")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()

                                Text(currentCompound?.molecularFormula ?? "—")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.accent.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                            
                            Divider()
                            
                            // Category
                            HStack(spacing: 8) {
                                Text("Category")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(currentCompound?.category ?? "—")
                                    .font(.title2)
                                    .padding(.horizontal, AppConstants.defaultPadding)
                                    .padding(.vertical, AppConstants.defaultPadding/2)
                                    .background(AppColors.accentLight)
                                    .foregroundColor(AppColors.accent.opacity(0.8))
                                    .cornerRadius(AppConstants.defaultPadding)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(AppConstants.defaultPadding)
                        .background(AppColors.surface)
                        .cornerRadius(AppConstants.defaultCornerRadius)
                        .padding(.horizontal)
                        
                        // Notes Section
                        notesSection
                        
                        // Structure Information with CoreML Properties
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Structure Details")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 12) {
                                InfoRow(
                                    title: "Carbon Chain Length",
                                    value: "\(activeStructure.carbonChainLength)"
                                )
                                
                                InfoRow(
                                    title: "Total Bonds",
                                    value: "\(activeStructure.bonds.count)"
                                )
                                
                                InfoRow(
                                    title: "Functional Groups",
                                    value: "\(activeStructure.functionalGroups.count)"
                                )
                                
                                InfoRow(
                                    title: "Structure Notation",
                                    value: activeStructure.toSMILESLike()
                                )
                            }
                        }
                        .padding(AppConstants.defaultPadding)
                        .background(AppColors.surface)
                        .cornerRadius(AppConstants.defaultCornerRadius)
                        .padding(.horizontal)
                        
                        // CoreML Properties Section
                        //                    CoreMLPropertiesSection(compound: compound)
                        
                        // Structure Preview
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Structure Diagram")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                if let compound = currentCompound {
                                    Button(action: { show3DViewer = true }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "cube.transparent")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, AppConstants.smallPadding)
                                        .padding(.vertical, AppConstants.smallPadding/2)
                                        .background(AppColors.accent)
                                        .cornerRadius(AppConstants.largeCornerRadius)
                                    }
                                }
                            }
                            
                            StructureDiagramView(structure: activeStructure)
                                .frame(height: 200)
                                .background(AppColors.Card)
                                .cornerRadius(AppConstants.defaultCornerRadius)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                        .padding(AppConstants.defaultPadding)
                        .background(AppColors.surface)
                        .cornerRadius(AppConstants.defaultCornerRadius)
                        .padding(.horizontal)
                        .sheet(isPresented: $show3DViewer) {
                            if let compound = currentCompound {
                                Model3DViewerScreen(compound: compound)
                            }
                        }
                        
                        
                    
                        
                    }
                    .padding(.vertical, AppConstants.defaultPadding)
                }
            // }
            .navigationTitle("Compound details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if canSave {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .foregroundColor(AppColors.accent)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            saveCompound()
                        }
                    }
                }
            }
        }
    
    private var notesSection: some View {
        VStack {
            let compId = currentCompound?.id.uuidString ?? "UNKNOWN"
            if currentCompound != nil {
                let _ = CommonFunctions.debugNote(
                    action: "INIT",
                    noteId: "N/A",
                    compoundId: compId,
                    message: "CompoundResultView initialized with \(notes.count) notes"
                )
            }
            SwipeableNoteCardView(notes: $notes, compoundId: currentCompound?.id ?? UUID())
        }
    }

    private func saveCompound() {
        guard let comp = currentCompound else { return }
        onSave(comp)
        isSaved = true
        
        CommonFunctions.debugNoteSave(
            compoundId: comp.id.uuidString,
            noteCount: comp.notes.count
        )
        
        // Show toast
        toastManager.show(AppStrings.compoundSaved, type: .success)

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Dismiss after a short delay to allow toast to show
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
    
    // private func resetForm() {
    //     // Reset all states
    //     isSaved = false
    //     showIUPACExplanation = false
    //     toastManager.show("Form reset", type: .info)
        
    //     // Haptic feedback
    //     let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    //     impactFeedback.impactOccurred()
    // }
}
