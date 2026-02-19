import SwiftUI
import Combine
import MultipeerConnectivity

struct ClassroomStudentJoinView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var toastManager: ToastManager

    @StateObject private var mpc: MPCSessionManager
    @StateObject private var viewModel: ClassroomStudentViewModel

    @State private var answerText: String = ""
    @State private var studentName: String = ""
    @State private var hasJoined = false
    @State private var availableTeachers: [MCPeerID] = []

    init() {
        let classroomID = UUID()

        let mpc = MPCSessionManager(configuration: .init(serviceType: "materia-class"))
        _mpc = StateObject(wrappedValue: mpc)
        _viewModel = StateObject(wrappedValue: ClassroomStudentViewModel(classroomID: classroomID, mpc: mpc))
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
                        if !hasJoined {
                            joinScreen
                        } else {
                            classroomScreen
                        }
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
                // Monitor for available teachers
                mpc.$foundPeers.sink { peers in
                    Task { @MainActor in
                        self.availableTeachers = peers.filter { peer in
                            let info = mpc.foundPeersInfo[peer] ?? [:]
                            return info["mode"] == "classroom" && info["role"] == "teacher"
                        }
                        
                        // Auto-connect to first available teacher
                        if !self.availableTeachers.isEmpty && !hasJoined {
                            mpc.invite(self.availableTeachers[0])
                        }
                    }
                }.store(in: &viewModel.cancellables)
                
                // Monitor for connection and auto-send join when connected
                mpc.$connectedPeers.sink { peers in
                    Task { @MainActor in
                        if !peers.isEmpty && !hasJoined {
                            // Wait a moment for connection to stabilize
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                            viewModel.sendJoin()
                            hasJoined = true
                            toastManager.show("Joined classroom!", type: .success)
                        }
                    }
                }.store(in: &viewModel.cancellables)
            }
        }
    }

    // MARK: - Join Screen
    private var joinScreen: some View {
        VStack(spacing: AppConstants.defaultPadding) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Join Classroom")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Connect with your teacher and classmates")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppConstants.defaultPadding)
            .padding(.vertical, AppConstants.defaultPadding)

            // Student Name Input
            VStack(alignment: .leading, spacing: 12) {
                Label("Your Name", systemImage: "person.crop.circle.badge.xmark")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                TextField("Enter your name", text: $studentName)
                    .textFieldStyle(.roundedBorder)
                    .padding(AppConstants.defaultPadding)
                    .background(AppColors.accent.opacity(0.05))
                    .cornerRadius(AppConstants.defaultCornerRadius)
            }
            .padding(AppConstants.defaultPadding)
            .background(AppColors.Card)
            .cornerRadius(AppConstants.defaultCornerRadius)
            .padding(.horizontal, AppConstants.defaultPadding)

            // Connection Status
            VStack(alignment: .leading, spacing: 12) {
                Label("Connection Status", systemImage: "wifi.circle.fill")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 12) {
                    Image(systemName: availableTeachers.isEmpty ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(availableTeachers.isEmpty ? .orange : .green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if availableTeachers.isEmpty {
                            Text("Searching for teachers...")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Make sure your teacher has started hosting")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        } else {
                            Text("\(availableTeachers.count) teacher\(availableTeachers.count > 1 ? "s" : "") found")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Ready to join classroom")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(AppConstants.defaultPadding)
                .background(availableTeachers.isEmpty ? Color.orange.opacity(0.1) : Color.green.opacity(0.1))
                .cornerRadius(AppConstants.defaultCornerRadius)
            }
            .padding(AppConstants.defaultPadding)
            .background(AppColors.Card)
            .cornerRadius(AppConstants.defaultCornerRadius)
            .padding(.horizontal, AppConstants.defaultPadding)

            // Join Button
            VStack(spacing: 12) {
                Button(action: {
                    if !studentName.isEmpty {
                        viewModel.studentName = studentName
                        viewModel.sendJoin()
                        hasJoined = true
                        toastManager.show("Joined classroom as \(studentName)", type: .success)
                    } else {
                        toastManager.show("Please enter your name", type: .error)
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Join Classroom")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(AppConstants.defaultPadding)
                    .background(studentName.isEmpty ? AppColors.accent : AppColors.accentLight)
                    .cornerRadius(AppConstants.defaultCornerRadius)
                }
                .disabled(studentName.isEmpty)

                Button(action: { viewModel.startJoining() }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Search for Teachers")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(AppColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.accent.opacity(0.1))
                    .cornerRadius(AppConstants.defaultCornerRadius)
                }
            }
            .padding(AppConstants.defaultPadding)
            .background(AppColors.Card)
            .cornerRadius(AppConstants.defaultCornerRadius)
            .padding(.horizontal, AppConstants.defaultPadding)

            Spacer()
        }
    }

    // MARK: - Classroom Screen
    private var classroomScreen: some View {
        VStack(spacing: AppConstants.defaultPadding) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Classroom")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Answer questions from your teacher")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppConstants.defaultPadding)
            .padding(.vertical, AppConstants.defaultPadding)

            // Student Info Card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(AppColors.accent)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your Name")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text(viewModel.studentName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
                .padding(AppConstants.defaultPadding)
                .background(AppColors.accent.opacity(0.1))
                .cornerRadius(AppConstants.defaultCornerRadius)
            }
            .padding(.horizontal, AppConstants.defaultPadding)

            // Current Question
            if let q = viewModel.currentQuestion {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Current Question", systemImage: "questionmark.circle.fill")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(q.prompt)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        if let structure = q.structure {
                            StructureDiagramView(structure: structure)
                                .frame(height: 150)
                                .background(AppColors.Card)
                                .cornerRadius(AppConstants.defaultCornerRadius)
                        }
                    }
                    .padding(AppConstants.defaultPadding)
                    .background(AppColors.accent.opacity(0.05))
                    .cornerRadius(AppConstants.defaultCornerRadius)
                    
                    // Answer Input
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Your Answer", systemImage: "pencil.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        TextField("Type your answer here", text: $answerText)
                            .textFieldStyle(.roundedBorder)
                            .padding(AppConstants.defaultPadding)
                            .background(AppColors.accent.opacity(0.05))
                            .cornerRadius(AppConstants.defaultCornerRadius)
                        
                        Button(action: {
                            if !answerText.isEmpty {
                                viewModel.submitAnswer(answerText)
                                toastManager.show("Answer submitted!", type: .success)
                                answerText = ""
                            } else {
                                toastManager.show("Please enter an answer", type: .error)
                            }
                        }) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Submit Answer")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(answerText.isEmpty ? AppColors.accent : AppColors.accentLight)
                            .cornerRadius(AppConstants.defaultCornerRadius)
                        }
                        .disabled(answerText.isEmpty)
                    }
                    .padding(AppConstants.defaultPadding)
                    .background(AppColors.Card)
                    .cornerRadius(AppConstants.defaultCornerRadius)
                }
                .padding(.horizontal, AppConstants.defaultPadding)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "hourglass.circle")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.textSecondary)
                    
                    VStack(spacing: 4) {
                        Text("Waiting for Question")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Your teacher hasn't posted a question yet")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(AppConstants.defaultPadding)
                .background(Color(.systemGray6))
                .cornerRadius(AppConstants.defaultCornerRadius)
                .padding(.horizontal, AppConstants.defaultPadding)
            }

            // Class Statistics (if available)
            if let results = viewModel.lastResults {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Class Statistics", systemImage: "chart.bar.xaxis")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 16) {
                        StatisticCardView(
                            title: "Submitted",
                            value: "\(results.totalSubmissions)",
                            icon: "checkmark.circle.fill",
                            color: AppColors.accent
                        )
                        
                        StatisticCardView(
                            title: "Accuracy",
                            value: "\(Int(results.correctnessRate * 100))%",
                            icon: "star.fill",
                            color: .orange
                        )
                        
                        Spacer()
                    }
                }
                .padding(AppConstants.defaultPadding)
                .background(AppColors.Card)
                .cornerRadius(AppConstants.defaultCornerRadius)
                .padding(.horizontal, AppConstants.defaultPadding)
            }

            Spacer()
        }
    }
}

// MARK: - Statistic Card View
struct StatisticCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppConstants.defaultPadding)
        .background(color.opacity(0.1))
        .cornerRadius(AppConstants.defaultCornerRadius)
    }
}
