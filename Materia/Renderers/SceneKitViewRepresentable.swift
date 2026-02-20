//
//  SceneKitViewRepresentable.swift
//  Materia
//
//  SwiftUI wrapper for SceneKit view
//

import SwiftUI
import SceneKit

struct SceneKitViewRepresentable: UIViewRepresentable {
    let model3D: Model3D
    @Binding var isRotating: Bool
    @Binding var shouldAutoRotate: Bool
    @Binding var showLabels: Bool
    var onRotationStart: (() -> Void)?
    var onRotationEnd: (() -> Void)?
    var onReset: (() -> Void)?
    var onCoordinatorReady: ((Coordinator) -> Void)?
    
    func makeUIView(context: Context) -> SCNView {
        CommonFunctions.debugPrint(load: "SceneKit", message: "=== PROFESSIONAL 3D VIEWER SETUP ===")
        
        let sceneView = SCNView()
        sceneView.scene = SCNScene()
        sceneView.backgroundColor = UIColor(AppColors.background)
        sceneView.autoenablesDefaultLighting = false  // We handle lighting manually
        sceneView.allowsCameraControl = false  // We handle gestures manually
        sceneView.debugOptions = []
        sceneView.preferredFramesPerSecond = 60
        
        guard let scene = sceneView.scene else { return sceneView }
        
        // STEP 1: Create pivot node (molecule container)
        CommonFunctions.debugPrint(load: "SceneKit", message: "Step 1: Creating pivot node...")
        let pivotNode = SCNNode()
        pivotNode.name = "pivotNode"
        scene.rootNode.addChildNode(pivotNode)
        context.coordinator.pivotNode = pivotNode
        CommonFunctions.debugPrint(load: "SceneKit", message: "✔ Pivot node created and stored")
        
        // STEP 2: Setup professional 3-point lighting
        CommonFunctions.debugPrint(load: "SceneKit", message: "Step 2: Setting up professional lighting...")
        configureProfessionalLighting(for: scene)
        
        // STEP 3: Create and position camera
        CommonFunctions.debugPrint(load: "SceneKit", message: "Step 3: Creating camera node...")
        let camera = SCNCamera()
        camera.zNear = 0.1
        camera.zFar = 1000
        camera.fieldOfView = 60
        
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 50)  // Will be updated after fit calculation
        cameraNode.name = "cameraNode"
        scene.rootNode.addChildNode(cameraNode)
        sceneView.pointOfView = cameraNode
        CommonFunctions.debugPrint(load: "SceneKit", message: "✔ Camera created at Z=50")
        
        // STEP 4: Build molecule geometry on pivot node
        CommonFunctions.debugPrint(load: "SceneKit", message: "Step 4: Building molecule geometry...")
        DispatchQueue.global(qos: .userInitiated).async {
            let atoms = self.model3D.atoms
            let bonds = self.model3D.bonds
            CommonFunctions.debugPrint(load: "SceneKit", message: "Background: Building \(atoms.count) atoms and \(bonds.count) bonds")
            
            DispatchQueue.main.async {
                self.buildAtoms(in: pivotNode, from: atoms)
                self.buildBonds(in: pivotNode, from: bonds, model3D: self.model3D)
                CommonFunctions.debugPrint(load: "SceneKit", message: "✔ All geometry added to pivot node")
                
                // STEP 5: Calculate and apply auto-fit
                CommonFunctions.debugPrint(load: "SceneKit", message: "Step 5: Calculating auto-fit...")
                self.performAutoFit(
                    pivotNode: pivotNode,
                    cameraNode: cameraNode,
                    coordinator: context.coordinator
                )
                CommonFunctions.debugPrint(load: "SceneKit", message: "✔ Auto-fit complete")
                
                // STEP 6: Log final scene state
                CommonFunctions.debugPrint(load: "SceneKit", message: "Step 6: Scene ready")
                CommonFunctions.debugPrint(load: "SceneKit", message: "  Pivot position: (\(pivotNode.position.x), \(pivotNode.position.y), \(pivotNode.position.z))")
                CommonFunctions.debugPrint(load: "SceneKit", message: "  Pivot children: \(pivotNode.childNodes.count)")
                CommonFunctions.debugPrint(load: "SceneKit", message: "  Camera position: (\(cameraNode.position.x), \(cameraNode.position.y), \(cameraNode.position.z))")
                CommonFunctions.debugPrint(load: "SceneKit", message: "=== 3D VIEWER READY ===")
            }
        }
        
        // Store coordinator state
        context.coordinator.sceneView = sceneView
        context.coordinator.cameraNode = cameraNode
        
        // Notify coordinator is ready
        DispatchQueue.main.async {
            CommonFunctions.debugPrint(load: "SceneKit", message: "Calling onCoordinatorReady...")
            self.onCoordinatorReady?(context.coordinator)
        }
        
        // Add gesture recognizers
        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        sceneView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        sceneView.addGestureRecognizer(pinchGesture)
        
        let rotationGesture = UIRotationGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleRotation(_:))
        )
        sceneView.addGestureRecognizer(rotationGesture)
        
        // Add display link for auto-rotation
        context.coordinator.displayLink = CADisplayLink(
            target: context.coordinator,
            selector: #selector(Coordinator.updateRotation)
        )
        context.coordinator.displayLink?.add(to: .main, forMode: .common)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.shouldAutoRotate = shouldAutoRotate
        context.coordinator.showLabels = showLabels
        context.coordinator.isRotating = isRotating
        
        // Also call coordinator callback in updateUIView to ensure it's set
        CommonFunctions.debugPrint(load: "SceneKit", message: "updateUIView - Calling onCoordinatorReady callback")
        onCoordinatorReady?(context.coordinator)
        CommonFunctions.debugPrint(load: "SceneKit", message: "updateUIView - onCoordinatorReady callback completed")
        
        // Update labels visibility
        if showLabels {
            updateLabels(in: uiView.scene!, from: model3D)
        } else {
            clearLabels(in: uiView.scene!)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            isRotating: $isRotating,
            shouldAutoRotate: $shouldAutoRotate,
            showLabels: $showLabels,
            onStart: onRotationStart,
            onEnd: onRotationEnd,
            onReset: onReset
        )
    }
    
    // MARK: - Private Methods
    private func configureLighting(for scene: SCNScene) {
        // Key light
        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.intensity = 1000
        
        let keyLightNode = SCNNode()
        keyLightNode.light = keyLight
        keyLightNode.position = SCNVector3(10, 10, 10)
        scene.rootNode.addChildNode(keyLightNode)
        
        // Ambient light
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 300
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        scene.rootNode.addChildNode(ambientLightNode)
    }
    
    // MARK: - Professional 3-Point Lighting
    private func configureProfessionalLighting(for scene: SCNScene) {
        CommonFunctions.debugPrint(load: "SceneKit", message: "  Key light (1000 intensity)...")
        // Key light - Main shadow caster
        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.intensity = 1000
        keyLight.castsShadow = true
        
        let keyLightNode = SCNNode()
        keyLightNode.light = keyLight
        keyLightNode.position = SCNVector3(15, 20, 15)  // Forward, up, right
        keyLightNode.name = "keyLight"
        scene.rootNode.addChildNode(keyLightNode)
        
        CommonFunctions.debugPrint(load: "SceneKit", message: "  Fill light (500 intensity)...")
        // Fill light - Softens shadows from opposite side
        let fillLight = SCNLight()
        fillLight.type = .omni
        fillLight.intensity = 500
        
        let fillLightNode = SCNNode()
        fillLightNode.light = fillLight
        fillLightNode.position = SCNVector3(-15, 5, -15)  // Opposite side, lower
        fillLightNode.name = "fillLight"
        scene.rootNode.addChildNode(fillLightNode)
        
        CommonFunctions.debugPrint(load: "SceneKit", message: "  Ambient light (200 intensity)...")
        // Ambient light - Prevents pure black areas
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 200
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        ambientLightNode.name = "ambientLight"
        scene.rootNode.addChildNode(ambientLightNode)
        
        CommonFunctions.debugPrint(load: "SceneKit", message: "  3-point lighting configured")
    }
    
    // MARK: - Auto-Fit to View
    private func performAutoFit(
        pivotNode: SCNNode,
        cameraNode: SCNNode,
        coordinator: Coordinator
    ) {
        // Get pivot node's bounding box
        let (minBounds, maxBounds) = pivotNode.boundingBox
        CommonFunctions.debugPrint(load: "SceneKit", message: "  Bounding box min: (\(minBounds.x), \(minBounds.y), \(minBounds.z))")
        CommonFunctions.debugPrint(load: "SceneKit", message: "  Bounding box max: (\(maxBounds.x), \(maxBounds.y), \(maxBounds.z))")
        
        // Calculate center
        let centerX = (minBounds.x + maxBounds.x) / 2
        let centerY = (minBounds.y + maxBounds.y) / 2
        let centerZ = (minBounds.z + maxBounds.z) / 2
        
        // Calculate dimensions
        let width = maxBounds.x - minBounds.x
        let height = maxBounds.y - minBounds.y
        let depth = maxBounds.z - minBounds.z
        let maxDimension = max(width, max(height, depth))
        
        CommonFunctions.debugPrint(load: "SceneKit", message: "  Molecule center: (\(centerX), \(centerY), \(centerZ))")
        CommonFunctions.debugPrint(load: "SceneKit", message: "  Dimensions - W:\(width) H:\(height) D:\(depth) Max:\(maxDimension)")
        
        // Calculate optimal camera distance (multiply by 2.5 for safe margin)
        let optimalDistance = maxDimension * 2.5
        CommonFunctions.debugPrint(load: "SceneKit", message: "  Optimal camera distance: \(optimalDistance)")
        
        // Keep pivot node at origin and set its pivot point to the center of the molecule
        // This way, when we rotate, we rotate around the molecule's center
        pivotNode.position = SCNVector3(0, 0, 0)
        
        // Set pivot to the CENTER of the molecule (so rotation happens around center)
        // SCNMatrix4MakeTranslation creates a translation matrix to offset the pivot point
        let pivotMatrix = SCNMatrix4MakeTranslation(centerX, centerY, centerZ)
        pivotNode.pivot = pivotMatrix
        
        CommonFunctions.debugPrint(load: "SceneKit", message: "  Pivot node at origin with pivot matrix for center rotation")
        
        // Position camera at optimal distance
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        cameraNode.position = SCNVector3(0, 0, optimalDistance)
        SCNTransaction.commit()
        
        CommonFunctions.debugPrint(load: "SceneKit", message: "  Camera positioned at distance: \(optimalDistance)")
        
        // Store camera distances for zoom bounds
        coordinator.optimalDistance = optimalDistance
        coordinator.minZoomDistance = optimalDistance * 0.3
        coordinator.maxZoomDistance = optimalDistance * 5.0
        
        CommonFunctions.debugPrint(load: "SceneKit", message: "  Zoom bounds - Min: \(coordinator.minZoomDistance) Max: \(coordinator.maxZoomDistance)")
    }
    
    private func updateLabels(in scene: SCNScene, from model: Model3D) {
        // Remove existing labels
        clearLabels(in: scene)
        
        // Add labels to atoms
        for (index, atom) in model.atoms.enumerated() {
            let labelNode = createLabelNode(
                text: atom.element.rawValue,
                position: atom.position
            )
            scene.rootNode.addChildNode(labelNode)
        }
    }
    
    private func clearLabels(in scene: SCNScene) {
        scene.rootNode.childNodes.forEach { node in
            if node.name?.starts(with: "label_") ?? false {
                node.removeFromParentNode()
            }
        }
    }
    
    private func createLabelNode(text: String, position: SCNVector3) -> SCNNode {
        let textGeometry = SCNText(string: text, extrusionDepth: 1)
        textGeometry.font = UIFont.systemFont(ofSize: 10)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.black
        
        let labelNode = SCNNode(geometry: textGeometry)
        labelNode.position = SCNVector3(position.x, position.y + 1, position.z)
        labelNode.scale = SCNVector3(0.1, 0.1, 0.1)
        labelNode.name = "label_\(text)"
        
        return labelNode
    }
    
    // MARK: - Private Methods
    private func buildAtoms(in pivotNode: SCNNode, from atoms: [Atom3D]) {
        CommonFunctions.debugPrint(load: "SceneKit", message: "buildAtoms: Adding \(atoms.count) atoms to pivot node")
        for (index, atom) in atoms.enumerated() {
            // Increase hydrogen size for visibility (hydrogen radius * 0.6 instead of 0.3)
            let scaleFactor: Float = atom.element == .hydrogen ? 0.6 : 0.3
            let geometry = SCNSphere(radius: CGFloat(atom.radius * scaleFactor))
            
            // Use custom color if available (for functional groups), otherwise use element color
            let color = atom.customColor ?? atom.element.color
            geometry.firstMaterial?.diffuse.contents = UIColor(
                red: CGFloat(color.x),
                green: CGFloat(color.y),
                blue: CGFloat(color.z),
                alpha: 1.0
            )
            
            geometry.firstMaterial?.specular.contents = UIColor.white
            geometry.firstMaterial?.shininess = 100
            
            let node = SCNNode(geometry: geometry)
            node.position = atom.position
            node.name = atom.element.displayName
            
            pivotNode.addChildNode(node)
            
            if index < 3 || index == atoms.count - 1 {
                CommonFunctions.debugPrint(load: "SceneKit", message: "  Atom \(index): \(atom.element.displayName) at (\(atom.position.x), \(atom.position.y), \(atom.position.z)) scale:\(scaleFactor)")
            }
        }
        CommonFunctions.debugPrint(load: "SceneKit", message: "✔ Atoms complete: \(atoms.count) total")
    }
    
    private func buildBonds(in pivotNode: SCNNode, from bonds: [Bond3D], model3D: Model3D) {
        CommonFunctions.debugPrint(load: "SceneKit", message: "buildBonds: Adding \(bonds.count) bonds to pivot node")
        for (index, bond) in bonds.enumerated() {
            guard bond.fromAtom < model3D.atoms.count && bond.toAtom < model3D.atoms.count else {
                continue
            }
            
            let fromAtom = model3D.atoms[bond.fromAtom]
            let toAtom = model3D.atoms[bond.toAtom]
            
            let cylinderCount = bond.bondType.cylinderCount
            let cylinderRadius = bond.bondType.cylinderRadius
            
            if index < 3 || index == bonds.count - 1 {
                CommonFunctions.debugPrint(load: "SceneKit", message: "  Bond \(index): type=\(bond.bondType) cylinders=\(cylinderCount)")
            }
            
            // For double/triple bonds, offset cylinders for better visibility
            let offsets: [Float] = {
                switch cylinderCount {
                case 1:
                    return [0]
                case 2:
                    return [-0.25, 0.25]  // Increased offset from 0.15 to 0.25
                case 3:
                    return [-0.35, 0, 0.35]  // Increased offset from 0.2 to 0.35
                default:
                    return [0]
                }
            }()
            
            for offset in offsets {
                addBondCylinder(
                    in: pivotNode,
                    from: fromAtom.position,
                    to: toAtom.position,
                    radius: cylinderRadius,
                    offset: offset
                )
            }
        }
        CommonFunctions.debugPrint(load: "SceneKit", message: "✔ Bonds complete: \(bonds.count) total")
    }
    
    private func addBondCylinder(
        in pivotNode: SCNNode,
        from: SCNVector3,
        to: SCNVector3,
        radius: Float,
        offset: Float
    ) {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let dz = to.z - from.z
        let distance = sqrt(dx*dx + dy*dy + dz*dz)
        
        let cylinder = SCNCylinder(radius: CGFloat(radius), height: CGFloat(distance))
        cylinder.firstMaterial?.diffuse.contents = UIColor.gray
        
        let node = SCNNode(geometry: cylinder)
        
        // Calculate midpoint
        let midX = (from.x + to.x) / 2
        let midY = (from.y + to.y) / 2
        let midZ = (from.z + to.z) / 2
        
        // Bond vector (normalized)
        let bondVec = SCNVector3(dx, dy, dz)
        let bondLen = length(bondVec)
        let bondNorm = SCNVector3(bondVec.x / bondLen, bondVec.y / bondLen, bondVec.z / bondLen)
        
        // Create perpendicular offset for double/triple bonds
        var offsetVec = SCNVector3(0, 0, 0)
        if abs(offset) > 0.001 {
            // Find a vector perpendicular to the bond
            let perpendicular1 = abs(bondNorm.x) < 0.9 ? 
                SCNVector3(1, 0, 0) : SCNVector3(0, 1, 0)
            
            // Cross product to get perpendicular vector
            let perpendicular = crossProduct(bondNorm, perpendicular1)
            let perpLen = length(perpendicular)
            
            if perpLen > 0.001 {
                let perpNorm = SCNVector3(
                    perpendicular.x / perpLen,
                    perpendicular.y / perpLen,
                    perpendicular.z / perpLen
                )
                offsetVec = SCNVector3(
                    perpNorm.x * offset,
                    perpNorm.y * offset,
                    perpNorm.z * offset
                )
            }
        }
        
        // Apply offset to position
        node.position = SCNVector3(
            midX + offsetVec.x,
            midY + offsetVec.y,
            midZ + offsetVec.z
        )
        
        // Rotate cylinder to align with bond
        let yAxis = SCNVector3(0, 1, 0)
        let crossProd = crossProduct(yAxis, bondVec)
        let dotProd = dotProduct(yAxis, bondVec)
        let angle = atan2(length(crossProd), dotProd)
        
        node.rotation = SCNVector4(crossProd.x, crossProd.y, crossProd.z, angle)
        
        pivotNode.addChildNode(node)
    }
    
    private func crossProduct(_ a: SCNVector3, _ b: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            a.y * b.z - a.z * b.y,
            a.z * b.x - a.x * b.z,
            a.x * b.y - a.y * b.x
        )
    }
    
    private func dotProduct(_ a: SCNVector3, _ b: SCNVector3) -> Float {
        return a.x * b.x + a.y * b.y + a.z * b.z
    }
    
    private func length(_ v: SCNVector3) -> Float {
        return sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject {
        @Binding var isRotating: Bool
        @Binding var shouldAutoRotate: Bool
        @Binding var showLabels: Bool
        var onStart: (() -> Void)?
        var onEnd: (() -> Void)?
        var onReset: (() -> Void)?
        
        weak var sceneView: SCNView?
        weak var cameraNode: SCNNode?
        weak var pivotNode: SCNNode?
        
        // Professional 3D viewer properties
        var initialCameraPosition: SCNVector3 = SCNVector3(0, 0, 50)
        var optimalDistance: Float = 25.0
        var minZoomDistance: Float = 7.5
        var maxZoomDistance: Float = 125.0
        
        var displayLink: CADisplayLink?
        var rotationAngle: Float = 0
        var lastPanRotation: SCNVector3 = SCNVector3(0, 0, 0)  // Track pan rotation state
        
        init(
            isRotating: Binding<Bool>,
            shouldAutoRotate: Binding<Bool>,
            showLabels: Binding<Bool>,
            onStart: (() -> Void)?,
            onEnd: (() -> Void)?,
            onReset: (() -> Void)?
        ) {
            self._isRotating = isRotating
            self._shouldAutoRotate = shouldAutoRotate
            self._showLabels = showLabels
            self.onStart = onStart
            self.onEnd = onEnd
            self.onReset = onReset
        }
        
        deinit {
            displayLink?.invalidate()
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let sceneView = sceneView, let pivotNode = pivotNode else { return }
            
            switch gesture.state {
            case .began:
                lastPanRotation = pivotNode.eulerAngles  // Store initial rotation
                isRotating = true
                onStart?()
                shouldAutoRotate = false
                CommonFunctions.debugPrint(load: "SceneKit", message: "Pan: gesture started, initial rotation: \(lastPanRotation)")
                
            case .changed:
                let translation = gesture.translation(in: sceneView)
                
                // Calculate incremental rotation from initial state
                let verticalDelta = Float(translation.y) * 0.008
                let horizontalDelta = Float(translation.x) * 0.008
                
                // Apply rotations incrementally
                var newRotation = lastPanRotation
                newRotation.x -= verticalDelta    // Vertical pan tilts up/down
                newRotation.y += horizontalDelta  // Horizontal pan spins left/right
                
                pivotNode.eulerAngles = newRotation
                rotationAngle = newRotation.y
                
                CommonFunctions.debugPrint(load: "SceneKit", message: "Pan: rotation (\(newRotation.x), \(newRotation.y), \(newRotation.z)) translation: (\(translation.x), \(translation.y))")
                
            case .ended, .cancelled:
                isRotating = false
                onEnd?()
                CommonFunctions.debugPrint(load: "SceneKit", message: "Pan: gesture ended, final rotation: \(pivotNode.eulerAngles)")
                
            default:
                break
            }
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let sceneView = sceneView, let cameraNode = cameraNode else { return }

            switch gesture.state {

            case .began:
                shouldAutoRotate = false

            case .changed:
                let delta = Float(gesture.scale - 1.0) * 5  // Adjusted sensitivity
                let newZ = max(minZoomDistance, min(maxZoomDistance, cameraNode.position.z - delta))
                
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.1
                cameraNode.position.z = newZ
                SCNTransaction.commit()
                
                CommonFunctions.debugPrint(load: "SceneKit", message: "Pinch zoom: \(cameraNode.position.z)")
                gesture.scale = 1.0

            default:
                break
            }
        }
        
        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let sceneView = sceneView, let pivotNode = pivotNode else { return }
            
            switch gesture.state {
            case .began:
                isRotating = true
                onStart?()
                shouldAutoRotate = false
                
            case .changed:
                // Rotate PIVOT NODE around Z axis (roll/tilt)
                var rotation = pivotNode.eulerAngles
                rotation.z += Float(gesture.rotation)
                pivotNode.eulerAngles = rotation
                
                CommonFunctions.debugPrint(load: "SceneKit", message: "Rotation gesture: Z:\(rotation.z)")
                gesture.rotation = 0
                
            case .ended, .cancelled:
                isRotating = false
                onEnd?()
                
            default:
                break
            }
        }
        
        @objc func updateRotation() {
            guard shouldAutoRotate, let pivotNode = pivotNode else { return }
            
            CommonFunctions.debugPrint(load: "SceneKit", message: "updateRotation() - Auto-rotating molecule")
            rotationAngle += 1.0
            var rotation = pivotNode.eulerAngles
            rotation.y = rotationAngle * Float.pi / 180.0
            pivotNode.eulerAngles = rotation
        }
        
        func resetView() {
            guard let sceneView = sceneView else { return }
            
            CommonFunctions.debugPrint(load: "SceneKit", message: "resetView() - Starting animation")
            DispatchQueue.main.async {
                if let cameraNode = sceneView.scene?.rootNode.childNode(
                    withName: "cameraNode",
                    recursively: false
                ) {
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.5
                    cameraNode.position = self.initialCameraPosition
                    CommonFunctions.debugPrint(load: "SceneKit", message: "resetView() - Camera reset to initial position")
                    SCNTransaction.commit()
                }
                
                if let scene = sceneView.scene {
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.5
                    scene.rootNode.eulerAngles = SCNVector3(0, 0, 0)
                    CommonFunctions.debugPrint(load: "SceneKit", message: "resetView() - Rotation reset")
                    SCNTransaction.commit()
                }
                
                self.rotationAngle = 0
                self.shouldAutoRotate = false
                self.onReset?()
                CommonFunctions.debugPrint(load: "SceneKit", message: "resetView() - Completed")
            }
        }
        
        // MARK: - Exploration Methods
        
        func rotateToFront() {
            guard let pivotNode = pivotNode else { 
                CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToFront() - pivotNode is NIL")
                return 
            }
            
            CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToFront() - Starting animation to front view")
            DispatchQueue.main.async {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                pivotNode.eulerAngles = SCNVector3(0, 0, 0)
                CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToFront() - Molecule rotated to front")
                SCNTransaction.commit()
                self.rotationAngle = 0
                CommonFunctions.debugPrint(load: "SceneKit", message: "✔ rotateToFront completed")
            }
        }
        
        func rotateToLeft() {
            guard let pivotNode = pivotNode else { 
                CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToLeft() - pivotNode is NIL")
                return 
            }
            
            CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToLeft() - Starting animation to left view")
            DispatchQueue.main.async {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                pivotNode.eulerAngles = SCNVector3(0, Float.pi / 2, 0)
                CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToLeft() - Molecule rotated to left")
                SCNTransaction.commit()
                self.rotationAngle = Float.pi / 2
                CommonFunctions.debugPrint(load: "SceneKit", message: "✔ rotateToLeft completed")
            }
        }
        
        func rotateToRight() {
            guard let pivotNode = pivotNode else { 
                CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToRight() - pivotNode is NIL")
                return 
            }
            
            CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToRight() - Starting animation to right view")
            DispatchQueue.main.async {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                pivotNode.eulerAngles = SCNVector3(0, -Float.pi / 2, 0)
                CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToRight() - Molecule rotated to right")
                SCNTransaction.commit()
                self.rotationAngle = -Float.pi / 2
                CommonFunctions.debugPrint(load: "SceneKit", message: "✔ rotateToRight completed")
            }
        }
        
        func rotateToTop() {
            guard let pivotNode = pivotNode else { 
                CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToTop() - pivotNode is NIL")
                return 
            }
            
            CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToTop() - Starting animation to top view")
            DispatchQueue.main.async {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                pivotNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
                CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToTop() - Molecule rotated to top")
                SCNTransaction.commit()
                CommonFunctions.debugPrint(load: "SceneKit", message: "✔ rotateToTop completed")
            }
        }
        
        func rotateToBottom() {
            guard let pivotNode = pivotNode else { 
                CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToBottom() - pivotNode is NIL")
                return 
            }
            
            CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToBottom() - Starting animation to bottom view")
            DispatchQueue.main.async {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                pivotNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
                CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToBottom() - Molecule rotated to bottom")
                SCNTransaction.commit()
                CommonFunctions.debugPrint(load: "SceneKit", message: "✔ rotateToBottom completed")
            }
        }
        
        func zoomIn() {
            guard let cameraNode = cameraNode else { 
                CommonFunctions.debugPrint(load: "SceneKit", message: "zoomIn() - cameraNode is NIL")
                return 
            }
            
            CommonFunctions.debugPrint(load: "SceneKit", message: "zoomIn() - Starting zoom in")
            DispatchQueue.main.async {
                let newDistance = max(self.minZoomDistance, cameraNode.position.z - 2)
                CommonFunctions.debugPrint(load: "SceneKit", message: "zoomIn() - Camera Z: \(cameraNode.position.z) → \(newDistance) (bounds: \(self.minZoomDistance)-\(self.maxZoomDistance))")
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.3
                cameraNode.position.z = newDistance
                SCNTransaction.commit()
                CommonFunctions.debugPrint(load: "SceneKit", message: "✔ zoomIn completed")
            }
        }
        
        func zoomOut() {
            guard let cameraNode = cameraNode else { 
                CommonFunctions.debugPrint(load: "SceneKit", message: "zoomOut() - cameraNode is NIL")
                return 
            }
            
            CommonFunctions.debugPrint(load: "SceneKit", message: "zoomOut() - Starting zoom out")
            DispatchQueue.main.async {
                let newDistance = min(self.maxZoomDistance, cameraNode.position.z + 2)
                CommonFunctions.debugPrint(load: "SceneKit", message: "zoomOut() - Camera Z: \(cameraNode.position.z) → \(newDistance) (bounds: \(self.minZoomDistance)-\(self.maxZoomDistance))")
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.3
                cameraNode.position.z = newDistance
                SCNTransaction.commit()
                CommonFunctions.debugPrint(load: "SceneKit", message: "✔ zoomOut completed")
            }
        }
        
        func fitToView() {
            guard let cameraNode = cameraNode else { 
                CommonFunctions.debugPrint(load: "SceneKit", message: "fitToView() - cameraNode is NIL")
                return 
            }
            
            CommonFunctions.debugPrint(load: "SceneKit", message: "fitToView() - Resetting to optimal distance: \(optimalDistance)")
            DispatchQueue.main.async {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                cameraNode.position.z = self.optimalDistance
                SCNTransaction.commit()
                CommonFunctions.debugPrint(load: "SceneKit", message: "✔ fitToView completed")
            }
        }
    }
}


//// MARK: - Preview
//#if DEBUG
//struct SceneKitViewRepresentable_Previews: PreviewProvider {
//    static var previews: some View {
//        @State var isRotating = false
//        
//        let sampleModel = Model3DGenerator.generate3DModel(
//            from: ChemicalStructure(
//                carbonChainLength: 3,
//                bonds: [
//                    Bond(from: 0, to: 1, type: .single),
//                    Bond(from: 1, to: 2, type: .single)
//                ],
//                functionalGroups: []
//            ),
//            name: "Propane"
//        )
//        
//        return SceneKitViewRepresentable(
//            model3D: sampleModel,
//            isRotating: $isRotating,
//            shouldAutoRotate: .constant(false),
//            showLabels: .constant(false)
//        )
//    }
//}
//#endif
