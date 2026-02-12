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
                
                List {
                    Section("Modes") {
                        Button("Mode 1 — Collaborative Molecule Builder") {
                            showingBuilderMode = true
                        }
                        .foregroundColor(AppColors.primary)
                        .fontWeight(.semibold)

                        Button("Mode 2 — Teacher (Host Classroom)") {
                            showingTeacherMode = true
                        }
                        .foregroundColor(AppColors.primary)
                        .fontWeight(.semibold)

                        Button("Mode 2 — Student (Join Classroom)") {
                            showingStudentMode = true
                        }
                        .foregroundColor(AppColors.primary)
                        .fontWeight(.semibold)
                    }

                    Section("Notes") {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(AppColors.primary)
                            Text("Offline-first. Nearby-only. No backend.")
                        }
                        
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(AppColors.accent)
                            Text("All sessions are encrypted using Multipeer Connectivity.")
                        }
                    }
                    .padding(AppConstants.defaultPadding)
                    .background(AppColors.Card)
                    .cornerRadius(AppConstants.largeCornerRadius)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
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
