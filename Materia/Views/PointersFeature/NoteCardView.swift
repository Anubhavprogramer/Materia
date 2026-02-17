import SwiftUI

struct NoteCardView: View {
    let note: CompoundNote
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Note Content
            Text(note.content)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // Footer
            HStack {
                Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                Button {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(width: 28, height: 28)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit) // ✅ Makes it square
        .background(AppColors.background)
        .cornerRadius(AppConstants.defaultCornerRadius)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 4)
        .contentShape(Rectangle()) // Makes full card tappable
        .onTapGesture {
            onTap() // ✅ Entire card opens edit
        }
        .alert("Delete Note", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this note?")
        }
    }
}
