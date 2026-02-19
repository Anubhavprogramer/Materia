import SwiftUI

struct ClassroomTeacherHostView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var toastManager: ToastManager

    @StateObject private var mpc: MPCSessionManager
    @StateObject private var viewModel: ClassroomHostViewModel

    @State private var prompt: String = ""
    @State private var showQuestionBuilder = false

    init() {
        let mpc = MPCSessionManager(configuration: .init(serviceType: "materia-class"))
        _mpc = StateObject(wrappedValue: mpc)
        _viewModel = StateObject(wrappedValue: ClassroomHostViewModel(mpc: mpc))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColors.gradientStart.opacity(0.1),
                        AppColors.gradientEnd.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppConstants.defaultPadding) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Teacher Dashboard")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Manage your classroom and post questions")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppConstants.defaultPadding)
                        .padding(.vertical, AppConstants.defaultPadding)

                        // Status Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Session Status")
                                        .font(.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: viewModel.isHosting ? "wifi" : "wifi.slash")
                                            .foregroundColor(viewModel.isHosting ? .green : .orange)
                                        
                                        Text(viewModel.isHosting ? "Hosting" : "Not Hosting")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(AppColors.textPrimary)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    if viewModel.isHosting {
                                        viewModel.stopHosting()
                                        toastManager.show("Classroom closed", type: .info)
                                    } else {
                                        viewModel.startHosting()
                                        toastManager.show("Classroom opened for students", type: .success)
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: viewModel.isHosting ? "stop.circle.fill" : "play.circle.fill")
                                        Text(viewModel.isHosting ? "Stop" : "Start")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(viewModel.isHosting ? Color.red : AppColors.accent)
                                    .cornerRadius(AppConstants.defaultCornerRadius)
                                }
                            }
                            .padding(AppConstants.defaultPadding)
                            .background(AppColors.Card)
                            .cornerRadius(AppConstants.defaultCornerRadius)
                        }
                        .padding(.horizontal, AppConstants.defaultPadding)

                        // Connected Students
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Connected Students", systemImage: "person.2.fill")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Spacer()
                                
                                Text("\(viewModel.connectedStudents.count)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.accent)
                            }
                            
                            if viewModel.connectedStudents.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "person.crop.circle.dashed")
                                        .font(.system(size: 32))
                                        .foregroundColor(AppColors.textSecondary)
                                    
                                    Text("No students connected yet")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(AppConstants.defaultPadding)
                                .background(Color(.systemGray6))
                                .cornerRadius(AppConstants.defaultCornerRadius)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(viewModel.connectedStudents, id: \.self) { student in
                                        HStack(spacing: 12) {
                                            Image(systemName: "person.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(AppColors.accent)
                                            
                                            Text(student)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(AppColors.textPrimary)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(.green)
                                        }
                                        .padding(AppConstants.defaultPadding)
                                        .background(AppColors.accent.opacity(0.1))
                                        .cornerRadius(AppConstants.defaultCornerRadius)
                                    }
                                }
                            }
                        }
                        .padding(AppConstants.defaultPadding)
                        .background(AppColors.Card)
                        .cornerRadius(AppConstants.defaultCornerRadius)
                        .padding(.horizontal, AppConstants.defaultPadding)

                        // Post Question Section
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Post Question", systemImage: "square.and.pencil")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Question prompt", text: $prompt)
                                .textFieldStyle(.roundedBorder)
                                .padding(AppConstants.defaultPadding)
                                .background(AppColors.accent.opacity(0.05))
                                .cornerRadius(AppConstants.defaultCornerRadius)
                            
                            Button(action: { showQuestionBuilder = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Create Question")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(colors: [AppColors.accent, AppColors.accent.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(AppConstants.defaultCornerRadius)
                            }
                        }
                        .padding(AppConstants.defaultPadding)
                        .background(AppColors.Card)
                        .cornerRadius(AppConstants.defaultCornerRadius)
                        .padding(.horizontal, AppConstants.defaultPadding)

                        // Current Question
                        if let q = viewModel.currentQuestion {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Current Question", systemImage: "questionmark.circle.fill")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text(q.prompt)
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                if let structure = q.structure {
                                    StructureDiagramView(structure: structure)
                                        .frame(height: 150)
                                        .background(AppColors.Card)
                                        .cornerRadius(AppConstants.defaultCornerRadius)
                                }
                                
                                Button(action: { viewModel.endQuestion() }) {
                                    Text("End Question")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(AppConstants.defaultCornerRadius)
                                }
                            }
                            .padding(AppConstants.defaultPadding)
                            .background(AppColors.accent.opacity(0.1))
                            .cornerRadius(AppConstants.defaultCornerRadius)
                            .padding(.horizontal, AppConstants.defaultPadding)

                            // Results
                            if let results = viewModel.lastResults {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("Student Responses", systemImage: "chart.bar.fill")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Submitted")
                                                .font(.caption)
                                                .foregroundColor(AppColors.textSecondary)
                                            Text("\(results.totalSubmissions)")
                                                .font(.headline)
                                                .fontWeight(.bold)
                                                .foregroundColor(AppColors.accent)
                                        }
                                        
                                        Divider()
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Accuracy")
                                                .font(.caption)
                                                .foregroundColor(AppColors.textSecondary)
                                            Text("\(Int(results.correctnessRate * 100))%")
                                                .font(.headline)
                                                .fontWeight(.bold)
                                                .foregroundColor(.green)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(AppConstants.defaultPadding)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(AppConstants.defaultCornerRadius)
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Answers")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        
                                        ForEach(results.answers, id: \.submittedAt) { ans in
                                            HStack(spacing: 12) {
                                                Text(ans.studentName)
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(AppColors.textPrimary)
                                                
                                                Spacer()
                                                
                                                Text(ans.answerText)
                                                    .font(.caption)
                                                    .foregroundColor(AppColors.textSecondary)
                                            }
                                            .padding(8)
                                            .background(AppColors.accent.opacity(0.05))
                                            .cornerRadius(AppConstants.smallCornerRadius)
                                        }
                                    }
                                }
                                .padding(AppConstants.defaultPadding)
                                .background(AppColors.Card)
                                .cornerRadius(AppConstants.defaultCornerRadius)
                                .padding(.horizontal, AppConstants.defaultPadding)
                            }
                        }

                        Spacer()
                            .frame(height: AppConstants.largePadding)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppColors.accent)
                }
            }
            .onAppear {
                // Trigger initial update when view appears
                // The view will automatically update when @Published properties change
            }
        }
    }
}
