//
//  CompoundStoryScreen.swift
//  Materia
//
//  Screen showing the complete story of how a compound is built
//


import SwiftUI
import FoundationModels

@available(iOS 18.0, *)
struct CompoundStoryScreen: View {

    let compound: IdentifiedCompound
    let iupacExplanation: IUPACExplanation

    @Environment(\.dismiss) private var dismiss

    @State private var story: GeneratedCompoundStory.PartiallyGenerated?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let service = AppleIntelligenceCompoundService.shared

    var body: some View {

        NavigationStack {

            ScrollView {

                if !service.isAvailable() {

                    unavailableView

                } else if isLoading {

                    loadingView

                } else if let errorMessage {

                    errorView(message: errorMessage)

                } else if let story {

                    contentView(story: story)

                }
            }
            
            .navigationTitle("Compound Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(AppColors.accent)
                    }
                }
            }
            .task {
                await generateStory()
            }
        }
    }

    // MARK: - Generate

    private func generateStory() async {

        isLoading = true
        errorMessage = nil

        do {
            let stream = service.streamStory(
                compound: compound,
                structure: compound.structure
            )

            for try await partial in stream {
                self.story = partial
            }

            isLoading = false

        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    // MARK: - Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Generating AI Story...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var unavailableView: some View {
        VStack(spacing: 16) {

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Apple Intelligence Not Available")
                .font(.headline)

            Text("Enable Apple Intelligence in Settings or use a supported device (iOS 18+).")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Text("Error")
                .font(.headline)
            Text(message)
                .font(.caption)
        }
        .padding()
    }

    private func contentView(story: GeneratedCompoundStory.PartiallyGenerated) -> some View {

        VStack(alignment: .leading, spacing: AppConstants.defaultGap) {

            headerSection

            if let howItsBuilt = story.howItsBuilt {
                sectionCard(title: "The Building Process") {
                    MarkdownTextView(markdown: howItsBuilt)
                }
            }

            if let chemicalBasis = story.chemicalBasis {
                sectionCard(title: "Chemical Foundation") {
                    MarkdownTextView(markdown: chemicalBasis)
                }
            }

            if let features = story.structuralFeatures {
                sectionList(title: "Structural Features",
                            items: features,
                            icon: "sparkles")
            }

            if let points = story.keyPoints {
                sectionList(title: "Key Learning Points",
                            items: points,
                            icon: "checkmark.circle.fill")
            }

            if let insights = story.learningInsights {
                sectionList(title: "Real-World Insights",
                            items: insights,
                            icon: "lightbulb.fill")
            }
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.smallGap) {

            Text("How This Compound Is Built")
                .font(.title2)
                .fontWeight(.bold)

            Text(compound.compoundName)
                .font(.headline)
                .foregroundColor(AppColors.accent)

            Text(compound.iupacName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .padding(.horizontal)
    }

    private func sectionCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {

        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            content()
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(AppConstants.defaultCornerRadius)
        .padding(.horizontal)
    }

    private func sectionList(
        title: String,
        items: [String],
        icon: String
    ) -> some View {

        VStack(alignment: .leading, spacing: 12) {

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: icon)
                            .foregroundColor(AppColors.accent)
                            .font(.caption)

                        MarkdownTextView(markdown: item)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(AppConstants.defaultCornerRadius)
        .padding(.horizontal)
    }
}

// MARK: - Markdown Text View
struct MarkdownTextView: View {
    let markdown: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(markdown.split(separator: "\n", omittingEmptySubsequences: false).map(String.init), id: \.self) { line in
                if line.isEmpty {
                    Divider()
                        .padding(.vertical, 4)
                } else if line.hasPrefix("**") && line.hasSuffix("**") {
                    Text(line.replacingOccurrences(of: "**", with: ""))
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                } else if line.hasPrefix("•") {
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        Text(line.replacingOccurrences(of: "• ", with: ""))
                    }
                    .padding(.vertical, 4)
                } else if line.contains("**") {
                    // Handle inline bold
                    let parts = line.components(separatedBy: "**")
                    HStack(spacing: 0) {
                        ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                            if index % 2 == 0 {
                                Text(part)
                            } else {
                                Text(part).fontWeight(.semibold)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    Text(line)
                        .padding(.vertical, 4)
                }
            }
        }
    }
}

#Preview {
    let sampleStructure = ChemicalStructure(carbonChainLength: 3)
    let sampleCompound = IdentifiedCompound(
        structure: sampleStructure,
        name: "Propane",
        iupacName: "propane",
        formula: "C3H8",
        category: "Alkane"
    )
    let service = CoreMLChemistryServiceFactory.createService()
    let explanation = service.explainIUPAC(from: sampleStructure)
    
    return CompoundStoryScreen(compound: sampleCompound, iupacExplanation: explanation)
}
