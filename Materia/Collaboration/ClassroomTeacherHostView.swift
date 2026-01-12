import SwiftUI

struct ClassroomTeacherHostView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var mpc: MPCSessionManager
    @StateObject private var viewModel: ClassroomHostViewModel

    @State private var prompt: String = "Name this compound (IUPAC):"

    init() {
        let mpc = MPCSessionManager(configuration: .init(serviceType: "materia-class"))
        _mpc = StateObject(wrappedValue: mpc)
        _viewModel = StateObject(wrappedValue: ClassroomHostViewModel(mpc: mpc))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Teacher Host")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(viewModel.statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Start Hosting Classroom") {
                        viewModel.startHosting()
                    }
                    .buttonStyle(.borderedProminent)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Connected students: \(viewModel.connectedStudents.count)")
                            .font(.headline)

                        ForEach(viewModel.connectedStudents, id: \.self) { s in
                            Text("• \(s)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    TextField("Question prompt", text: $prompt)
                        .textFieldStyle(.roundedBorder)

                    Button("Broadcast Question") {
                        // Use a simple sample structure: 4-carbon with double bond at 2 (2-butene)
                        var s = ChemicalStructure(carbonChainLength: 4)
                        s.bonds.removeAll()
                        s.bonds.append(Bond(from: 1, to: 2, type: .single))
                        s.bonds.append(Bond(from: 2, to: 3, type: .double))
                        s.bonds.append(Bond(from: 3, to: 4, type: .single))

                        viewModel.sendQuestion(prompt: prompt, structure: s)
                    }
                    .buttonStyle(.bordered)

                    if let q = viewModel.currentQuestion {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Current Question")
                                .font(.headline)

                            Text(q.prompt)

                            if let structure = q.structure {
                                StructureDiagramView(structure: structure)
                                    .frame(height: 150)
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    if let results = viewModel.lastResults {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Results")
                                .font(.headline)

                            Text("Submissions: \(results.totalSubmissions)")
                            Text("Correct: \(results.correctSubmissions)")
                            Text("Rate: \(Int(results.correctnessRate * 100))%")

                            ForEach(results.answers, id: \.submittedAt) { ans in
                                Text("\(ans.studentName): \(ans.answerText)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Classroom")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
