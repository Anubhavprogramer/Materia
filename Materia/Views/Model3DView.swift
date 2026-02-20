//
//  Model3DView.swift
//  Materia
//
//  Main SwiftUI view for displaying 3D molecular structure with enhanced UX
//

import SwiftUI
import SceneKit

struct Model3DView: View {
    let compound: IdentifiedCompound
    let load = "Model3DView"
    @State private var model3D: Model3D?
    @State private var isRotating = false
    @State private var shouldAutoRotate = false
    @State private var showLabels = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var zoomLevel: Float = 1.0
    @State private var rotationAngle: Float = 0.0
    @State private var showControlPanel = true
    @State private var coordinator: SceneKitViewRepresentable.Coordinator?
    
    var body: some View {
        ZStack {
            if let model = model3D {
                // 3D Viewer Background
                SceneKitViewRepresentable(
                    model3D: model,
                    isRotating: $isRotating,
                    shouldAutoRotate: $shouldAutoRotate,
                    showLabels: $showLabels,
                    onRotationStart: { withAnimation { isRotating = true } },
                    onRotationEnd: { withAnimation { isRotating = false } },
                    onReset: { resetView() },
                    onCoordinatorReady: { coord in
                        CommonFunctions.debugPrint(load: load, message: "🎯 Coordinator READY! Deferring state assignment")
                        DispatchQueue.main.async {
                            CommonFunctions.justPrint(load: load, message: "Before assignment", thing: coordinator)
                            coordinator = coord
                            CommonFunctions.debugPrint(load: load, message: "✅ Coordinator set successfully")
                            CommonFunctions.justPrint(load: load, message: "After assignment", thing: coordinator)
                        }
                    }
                )
                .background(AppColors.background)
//                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // MARK: - Top Header
                    VStack(alignment: .leading, spacing: AppConstants.mediumGap) {
                        
                        InfoCardView(icon: "atom", title: compound.compoundName, message: compound.molecularFormula, accentColor: AppColors.accent)
                        
//                        Spacer()
                        
                        // Rotation indicator
//                        if isRotating {
//                            HStack(spacing: 6) {
//                                Image(systemName: "arrowtriangle.right.fill")
//                                    .font(.caption)
//                                    .rotationEffect(.degrees(isRotating ? 360 : 0))
//                                    .animation(
//                                        Animation.linear(duration: 2).repeatForever(autoreverses: false),
//                                        value: isRotating
//                                    )
//                                Text("Rotating")
//                                    .font(.caption)
//                                    .fontWeight(.medium)
//                            }
//                            .foregroundColor(AppColors.accent)
//                            .padding(.horizontal, AppConstants.defaultPadding)
//                            .padding(.vertical, AppConstants.smallPadding)
//                            .background(AppColors.Card)
//                            .cornerRadius(AppConstants.largeCornerRadius)
//                        }
                        
//                        Model3DHelpButton()
                    }
                    .padding(.horizontal, AppConstants.largePadding)
                    .padding(.vertical, AppConstants.defaultPadding)
                    
                    Spacer()
                    
                    // MARK: - Bottom Control Panel
                    VStack(spacing: AppConstants.largeGap) {
                        // Control Buttons - Premium Style
                        VStack(spacing: AppConstants.mediumGap) {
                            // Primary Controls
                            HStack(spacing: AppConstants.mediumGap) {
                                PrimaryButton(
                                    icon: shouldAutoRotate ? "pause.circle.fill" : "play.circle.fill",
                                    title: shouldAutoRotate ? "Pause" : "Auto-Rotate",
                                    color: .blue,
                                    action: { withAnimation { shouldAutoRotate.toggle() } }
                                )
                                
//                                PrimaryButton(
//                                    icon: showLabels ? "abc.fill" : "abc",
//                                    title: showLabels ? "Hide Labels" : "Show Labels",
//                                    color: showLabels ? .green : .gray,
//                                    action: { withAnimation { showLabels.toggle() } }
//                                )
                            }
                            
                            // Exploration Buttons - View Controls
                            VStack(spacing: AppConstants.smallGap) {
                                Text("Explore Views")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppColors.textSecondary)
                                    .padding(.top, AppConstants.smallPadding)
                                
                                // View Buttons Grid
                                VStack(spacing: AppConstants.smallGap) {
                                    // Row 1: Top, Zoom In, Zoom Out
                                    HStack(spacing: AppConstants.smallGap) {
                                        ExplorationButton(
                                            icon: "plus.magnifyingglass",
                                            label: "Zoom+",
                                            action: {
                                                CommonFunctions.debugPrint(load: load, message: "Zoom+ button tapped - Coordinator: \(coordinator != nil ? "EXISTS" : "NIL")")
                                                coordinator?.zoomIn()
                                                CommonFunctions.debugPrint(load: load, message: "zoomIn() called")
                                            }
                                        )
                                        
                                        ExplorationButton(
                                            icon: "minus.magnifyingglass",
                                            label: "Zoom-",
                                            action: {
                                                CommonFunctions.debugPrint(load: load, message: "Zoom- button tapped - Coordinator: \(coordinator != nil ? "EXISTS" : "NIL")")
                                                coordinator?.zoomOut()
                                                CommonFunctions.debugPrint(load: load, message: "zoomOut() called")
                                            }
                                        )
                                        ExplorationButton(
                                            icon: "square.dashed",
                                            label: "Fit",
                                            action: {
                                                CommonFunctions.debugPrint(load: load, message: "Fit button tapped - Coordinator: \(coordinator != nil ? "EXISTS" : "NIL")")
                                                coordinator?.fitToView()
                                                CommonFunctions.debugPrint(load: load, message: "fitToView() called")
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(AppConstants.defaultPadding)
                            .background(AppColors.accentLight.opacity(0.5))
                            .cornerRadius(AppConstants.defaultCornerRadius)
                        }
                    }
                    .padding(AppConstants.defaultPadding)
                }
                .padding(AppConstants.smallPadding)
            } else if let error = errorMessage {
                ErrorView(message: error)
            } else {
                LoadingView()
            }
        }
        
        .onAppear {
            generateModel()
        }
    }
    
    private func resetView() {
        withAnimation {
            zoomLevel = 1.0
            rotationAngle = 0.0
        }
    }
    
    private func generateModel() {
        let perfManager = Model3DPerformanceManager.shared
        let entryId = perfManager.startMonitoring(for: "3D_Generation")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let generated = Model3DGenerator.generate3DModel(
                from: compound.structure,
                name: compound.compoundName
            )
            
            let summary = perfManager.endMonitoring(entryId: entryId, action: "3D_Generation")
            
            CommonFunctions.debugPrint(load: load, message: "3D Model Generated")
            CommonFunctions.debugPrint(load: load, message: "  Duration: \(String(format: "%.2f", summary.duration))s")
            CommonFunctions.debugPrint(load: load, message: "  Memory Delta: \(String(format: "%.2f", summary.memoryDelta))MB")
            
            DispatchQueue.main.async {
                withAnimation {
                    self.model3D = generated
                    self.isLoading = false
                }
                perfManager.optimizeMemoryIfNeeded()
            }
        }
    }
}

// MARK: - Loading View
private struct LoadingView: View {
    @State private var rotation = 0.0
    
    var body: some View {
        VStack(spacing: AppConstants.defaultGap) {
            Image(systemName: "atom")
                .font(.system(size: 48))
                .foregroundColor(AppColors.accent)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(
                        Animation.linear(duration: 2).repeatForever(autoreverses: false)
                    ) {
                        rotation = 360
                    }
                }
            
            Text("Generating 3D Structure...")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Text("This may take a moment")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

// MARK: - Error View
private struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: AppConstants.largeGap) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Unable to Generate 3D")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Text(message)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .padding()
    }
}

// MARK: - Info Badge Component
private struct InfoBadge: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppColors.accent)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

// MARK: - Primary Button Component
private struct PrimaryButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(AppColors.accent)
            .frame(maxWidth: .infinity)
            .padding(AppConstants.smallPadding)
            .background(AppColors.accentLight)
            .cornerRadius(AppConstants.defaultCornerRadius)
        }
        .activeScale(0.95)
    }
}

// MARK: - Active Scale Modifier
extension View {
    func activeScale(_ scale: CGFloat) -> some View {
        self.scaleEffect(1.0)
    }
}

// MARK: - Exploration Button Component
private struct ExplorationButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(AppColors.accent)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppColors.Card)
            .cornerRadius(AppConstants.defaultCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.defaultCornerRadius)
                    .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
            )
        }
        .activeScale(0.95)
    }
}

// MARK: - Preview
//#if DEBUG
//struct Model3DView_Previews: PreviewProvider {
//    static var previews: some View {
//        let sampleCompound = IdentifiedCompound(
//            structure: ChemicalStructure(
//                carbonChainLength: 3,
//                bonds: [
//                    Bond(from: 0, to: 1, type: .single),
//                    Bond(from: 1, to: 2, type: .single)
//                ],
//                functionalGroups: []
//            ),
//            compoundName: "Propane",
//            iupacName: "Propane",
//            molecularFormula: "C₃H₈",
//            category: "Alkane",
//            confidence: 0.95,
//            isValidated: true
//        )
//        
//        Model3DView(compound: sampleCompound)
//    }
//}
//#endif
