//
//  Model3DViewerScreen.swift
//  Materia
//
//  Full-screen 3D molecular structure viewer with controls
//

import SwiftUI

struct Model3DViewerScreen: View {
    let compound: IdentifiedCompound
    @Environment(\.dismiss) var dismiss
    
    let load = "Model3DViewerScreen"
    
    @State private var isAnimating = false
    @State private var model3D: Model3D?
    @State private var showLabels = false
    @State private var isLoading = true
    @State private var shouldAutoRotate = false
    
    var body: some View {
        ZStack {
            if let model = model3D {
                // 3D Content
                Model3DView(compound: compound)
                
            } else if isLoading {
                ZStack {
                    Color(.systemBackground).edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 20) {
                        Image(systemName: "atom")
                            .font(.system(size: 56))
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .onAppear {
                                withAnimation(
                                    Animation.linear(duration: 2).repeatForever(autoreverses: false)
                                ) {
                                    isAnimating = true
                                }
                            }
                        
                        VStack(spacing: 8) {
                            Text("Building 3D Model")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Rendering \(compound.compoundName)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView()
                            .tint(.blue)
                            .scaleEffect(1.2, anchor: .center)
                    }
                }
            }
        }
        .navigationTitle("3D Model View")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("help") {
                    Model3DHelpButton()
                }
            }
        }
        .onAppear {
            generateModel()
        }
        .onDisappear {
            model3D = nil
            Model3DPerformanceManager.shared.optimizeMemoryIfNeeded()
        }
    }
    
    private func generateModel() {
        let perfManager = Model3DPerformanceManager.shared
        let entryId = perfManager.startMonitoring(for: "3D_Viewer_Generation")
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            CommonFunctions.MessagePrint(load: load, message: "3D model generation started")
            
            let generated = Model3DGenerator.generate3DModel(
                from: compound.structure,
                name: compound.compoundName
            )
            
            let summary = perfManager.endMonitoring(entryId: entryId, action: "3D_Viewer_Generation")
            
            CommonFunctions.debugPrint(load: load, message: "3D Model for Viewer Generated")
            CommonFunctions.debugPrint(load: load, message: "  Duration: \(String(format: "%.2f", summary.duration))s")
            CommonFunctions.debugPrint(load: load, message: "  Memory Delta: \(String(format: "%.2f", summary.memoryDelta))MB")
            
            DispatchQueue.main.async {
                withAnimation {
                    self.model3D = generated
                    self.isLoading = false
                }
            }
            
            
            CommonFunctions.MessagePrint(load: load, message: "3D model generation ended")
        }
    }
}

//// MARK: - Backdrop Modifier
//extension View {
//    func backdrop() -> some View {
//        self.background(
//            LinearGradient(
//                gradient: Gradient(colors: [
//                    AppColors.gradientStart,
//                    AppColors.gradientEnd
//                ]),
//                startPoint: .topLeading,
//                endPoint: .bottomTrailing
//            )
//            .ignoresSafeArea()
//        )
//    }
//}

// MARK: - Sheet Presentation Extension
extension View {
    /// Present 3D viewer for a compound
    func model3DViewer(
        compound: IdentifiedCompound?,
        isPresented: Binding<Bool>
    ) -> some View {
        sheet(isPresented: isPresented, content: {
            if let compound = compound {
                Model3DViewerScreen(compound: compound)
            }
        })
    }
}


