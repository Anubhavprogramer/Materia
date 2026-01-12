import SwiftUI

struct ModePickerView: View {
    @State private var showingBuilderMode = false
    @State private var showingTeacherMode = false
    @State private var showingStudentMode = false

    var body: some View {
        NavigationStack {
            List {
                Section("Modes") {
                    Button("Mode 1 — Collaborative Molecule Builder") {
                        showingBuilderMode = true
                    }

                    Button("Mode 2 — Teacher (Host Classroom)") {
                        showingTeacherMode = true
                    }

                    Button("Mode 2 — Student (Join Classroom)") {
                        showingStudentMode = true
                    }
                }

                Section("Notes") {
                    Text("Offline-first. Nearby-only. No backend.")
                    Text("All sessions are encrypted using Multipeer Connectivity.")
                }
            }
            .navigationTitle("Materia Live")
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
