import SwiftUI

struct ClassroomStudentJoinView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var mpc: MPCSessionManager
    @StateObject private var viewModel: ClassroomStudentViewModel

    @State private var answerText: String = ""

    init() {
        // For MVP, classroomID is not discovered/advertised in UI.
        // In Phase 2, discoveryInfo will include a classroom code.
        let classroomID = UUID() // placeholder; teacher and student must match in Phase 2

        let mpc = MPCSessionManager(configuration: .init(serviceType: "materia-class"))
        _mpc = StateObject(wrappedValue: mpc)
        _viewModel = StateObject(wrappedValue: ClassroomStudentViewModel(classroomID: classroomID, mpc: mpc))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Student")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(viewModel.statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Your name", text: $viewModel.studentName)
                    .textFieldStyle(.roundedBorder)

                Button("Start Joining") {
                    viewModel.startJoining()
                }
                .buttonStyle(.borderedProminent)

                Button("Send Join") {
                    viewModel.sendJoin()
                }
                .buttonStyle(.bordered)

                if let q = viewModel.currentQuestion {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Question")
                            .font(.headline)

                        Text(q.prompt)

                        if let structure = q.structure {
                            StructureDiagramView(structure: structure)
                                .frame(height: 150)
                                .background(AppColors.Card)
                                .cornerRadius(12)
                        }

                        TextField("Your answer", text: $answerText)
                            .textFieldStyle(.roundedBorder)

                        Button("Submit") {
                            viewModel.submitAnswer(answerText)
                            answerText = ""
                        }
                        .buttonStyle(.borderedProminent)

                        if let results = viewModel.lastResults, results.questionID == q.id {
                            Text("Class rate: \(Int(results.correctnessRate * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Join Classroom")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
