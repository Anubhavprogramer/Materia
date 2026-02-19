import SwiftUI

struct ModePickerView: View {
    @State private var showingBuilderMode = false
    @State private var showingTeacherMode = false
    @State private var showingStudentMode = false
    @EnvironmentObject var toastManager: ToastManager

    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background matching the app theme
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColors.gradientStart,
                        AppColors.gradientEnd
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with title and subtitle
                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppStrings.live)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Connect and collaborate with others")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppConstants.defaultPadding)
                    .padding(.vertical, AppConstants.largePadding)
                    
                    ScrollView {
                        VStack(spacing: AppConstants.defaultPadding) {
                            // Info card explaining the feature
                            InfoCardView(
                                icon: "person.2.wave.2.fill",
                                title: "Collaborative Building",
                                message: "Work together in real-time on the same molecular structure with other users nearby.",
                                accentColor: AppColors.accent,
                                backgroundColor: AppColors.accent.opacity(0.1),
                                borderColor: AppColors.accent.opacity(0.3)
                            )
                            .padding(.horizontal, AppConstants.defaultPadding)
                            
                            // Collaborative Molecule Builder Card
                            ModeCardView(
                                icon: "cube.transparent",
                                title: AppStrings.collaborativeMoleculeBuilder,
                                description: "Build molecules together in real-time",
                                action: {
                                    showingBuilderMode = true
                                    toastManager.show("Opening Collaborative Builder...", type: .info)
                                }
                            )
                            .padding(.horizontal, AppConstants.defaultPadding)
                            
                            // Teacher Mode Card
//                            ModeCardView(
//                                icon: "person.fill.badge.plus",
//                                title: AppStrings.teacherMode,
//                                description: "Host a classroom session and guide students",
//                                action: {
//                                    showingTeacherMode = true
//                                    toastManager.show("Opening Teacher Mode...", type: .info)
//                                }
//                            )
//                            .padding(.horizontal, AppConstants.defaultPadding)
                            
                            // Student Mode Card
//                            ModeCardView(
//                                icon: "person.fill.checkmark",
//                                title: AppStrings.studentMode,
//                                description: "Join a classroom session as a student",
//                                action: {
//                                    showingStudentMode = true
//                                    toastManager.show("Opening Student Mode...", type: .info)
//                                }
//                            )
//                            .padding(.horizontal, AppConstants.defaultPadding)
                            
                            Spacer()
                                .frame(height: AppConstants.largePadding)
                        }
                        .padding(.vertical, AppConstants.defaultPadding)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingBuilderMode) {
                CollaborativeBuilderLobbyView()
                    .environmentObject(toastManager)
            }
            .sheet(isPresented: $showingTeacherMode) {
                ClassroomTeacherHostView()
            }
            .sheet(isPresented: $showingStudentMode) {
                ClassroomStudentJoinView()
            }
        }
    }
}

// MARK: - Mode Card Component
struct ModeCardView: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(AppColors.accent)
                        .frame(width: 44, height: 44)
                        .background(AppColors.accent.opacity(0.15))
                        .cornerRadius(AppConstants.defaultCornerRadius)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(description)
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(AppConstants.defaultPadding)
                .background(AppColors.Card)
                .cornerRadius(AppConstants.defaultCornerRadius)
            }
        }
    }
}

#Preview {
    ModePickerView()
        .environmentObject(ToastManager())
}

#Preview {
    ModePickerView()
}
