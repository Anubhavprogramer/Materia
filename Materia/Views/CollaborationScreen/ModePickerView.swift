import SwiftUI

struct ModePickerView: View {
    @State private var showingBuilderMode = false
    @State private var showingTeacherMode = false
    @State private var showingStudentMode = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColors.gradientStart,
                        AppColors.gradientEnd
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                VStack{
                
                    List {
                        Section(AppStrings.modeSection) {
                            Button(AppStrings.collaborativeMoleculeBuilder) {
                                showingBuilderMode = true
                            }
                            .foregroundColor(AppColors.primary)
                            .fontWeight(.semibold)

                            Button(AppStrings.teacherMode) {
                                showingTeacherMode = true
                            }
                            .foregroundColor(AppColors.primary)
                            .fontWeight(.semibold)

                            Button(AppStrings.studentMode) {
                                showingStudentMode = true
                            }
                            .foregroundColor(AppColors.primary)
                            .fontWeight(.semibold)
                        }
                        .listRowBackground(AppColors.Card) // ✅ correct placement
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)

                    
                InfoCardView(icon: AppTips.collaborationTip.icon, title: AppTips.collaborationTip.title, message: AppTips.collaborationTip.message)
                    .padding(.horizontal, AppConstants.defaultPadding)
                    .padding(.bottom, AppConstants.largeGap)
                }
                
            }
            .navigationTitle(AppStrings.live)
            .sheet(isPresented: $showingBuilderMode) {
                CollaborativeBuilderLobbyView()
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

#Preview {
    ModePickerView()
}
