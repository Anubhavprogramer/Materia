import SwiftUI

struct QuickStartChip: View {
    let title: String
    let structure: ChemicalStructure
    let action: () -> Void

    var body: some View {
            
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                
                // Structure Preview
                StructureDiagramView(structure: structure)
                    .frame(height: 180)
                    .background(AppColors.Card.opacity(0.5))
                    .cornerRadius(AppConstants.largeCornerRadius)

                // Title
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
            }
            .frame(width: 210)
        }
        .frame(height: 230) // Set a fixed height for GeometryReader container
    }
}
