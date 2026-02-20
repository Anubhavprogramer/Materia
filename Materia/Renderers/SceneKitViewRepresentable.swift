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
        let sceneView = SCNView()
        sceneView.scene = SCNScene()
        sceneView.backgroundColor = UIColor(AppColors.background)
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true
        sceneView.debugOptions = []
        
        // Performance optimization: enable rendering optimizations
        sceneView.preferredFramesPerSecond = 60
        
        // Configure lighting
        configureLighting(for: sceneView.scene!)
        
        // Add camera
        let camera = SCNCamera()
        camera.zNear = 0.1
        camera.zFar = 1000
        
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 35)  // 35 for better zoom range
        cameraNode.name = "cameraNode"
        sceneView.scene?.rootNode.addChildNode(cameraNode)
        
        // Build 3D representation with lazy loading
        DispatchQueue.global(qos: .userInitiated).async {
            // Generate geometry in background
            let atoms = model3D.atoms
            let bonds = model3D.bonds
            
            DispatchQueue.main.async {
                // Update UI on main thread
                self.buildAtoms(in: sceneView.scene!, from: atoms)
                self.buildBonds(in: sceneView.scene!, from: bonds, model3D: model3D)
            }
        }
        
        // Set camera position for good view
        sceneView.defaultCameraController.target = SCNVector3(0, 0, 0)
        
        // Store initial camera position for reset
        context.coordinator.initialCameraPosition = cameraNode.position
        context.coordinator.sceneView = sceneView
        
        // Notify that coordinator is ready
        CommonFunctions.debugPrint(load: "SceneKit", message: "makeUIView - Calling onCoordinatorReady callback")
        onCoordinatorReady?(context.coordinator)
        CommonFunctions.debugPrint(load: "SceneKit", message: "makeUIView - onCoordinatorReady callback completed")
        
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
    private func buildAtoms(in scene: SCNScene, from atoms: [Atom3D]) {
        for atom in atoms {
            let geometry = SCNSphere(radius: CGFloat(atom.radius * 0.6))
            
            let color = atom.element.color
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
            
            scene.rootNode.addChildNode(node)
        }
    }
    
    private func buildBonds(in scene: SCNScene, from bonds: [Bond3D], model3D: Model3D) {
        for bond in bonds {
            guard bond.fromAtom < model3D.atoms.count && bond.toAtom < model3D.atoms.count else {
                continue
            }
            
            let fromAtom = model3D.atoms[bond.fromAtom]
            let toAtom = model3D.atoms[bond.toAtom]
            
            let cylinderCount = bond.bondType.cylinderCount
            let cylinderRadius = bond.bondType.cylinderRadius
            
            // For double/triple bonds, offset cylinders
            let offsets: [Float] = {
                switch cylinderCount {
                case 1:
                    return [0]
                case 2:
                    return [-0.15, 0.15]
                case 3:
                    return [-0.2, 0, 0.2]
                default:
                    return [0]
                }
            }()
            
            for offset in offsets {
                addBondCylinder(
                    in: scene,
                    from: fromAtom.position,
                    to: toAtom.position,
                    radius: cylinderRadius,
                    offset: offset
                )
            }
        }
    }
    
    private func addBondCylinder(
        in scene: SCNScene,
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
        node.position = SCNVector3(
            (from.x + to.x) / 2,
            (from.y + to.y) / 2,
            (from.z + to.z) / 2
        )
        
        // Rotate cylinder to align with bond
        let yAxis = SCNVector3(0, 1, 0)
        let bondVector = SCNVector3(dx, dy, dz)
        
        let crossProduct = crossProduct(yAxis, bondVector)
        let dotProduct = dotProduct(yAxis, bondVector)
        let angle = atan2(length(crossProduct), dotProduct)
        
        node.rotation = SCNVector4(crossProduct.x, crossProduct.y, crossProduct.z, angle)
        
        scene.rootNode.addChildNode(node)
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
        var initialCameraPosition: SCNVector3 = SCNVector3(0, 0, 35)
        var displayLink: CADisplayLink?
        var rotationAngle: Float = 0
        
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
            guard let sceneView = sceneView else { return }
            
            switch gesture.state {
            case .began:
                isRotating = true
                onStart?()
                shouldAutoRotate = false
                
            case .changed:
                let translation = gesture.translation(in: sceneView)
                let sensitivity: Float = 0.01
                
                if let scene = sceneView.scene {
                    // Rotate around X axis (vertical pan - up/down)
                    var xRotation = scene.rootNode.eulerAngles.x
                    xRotation -= Float(translation.y) * sensitivity
                    
                    // Rotate around Y axis (horizontal pan - left/right)
                    var yRotation = scene.rootNode.eulerAngles.y
                    yRotation -= Float(translation.x) * sensitivity
                    
                    scene.rootNode.eulerAngles = SCNVector3(xRotation, yRotation, 0)
                    rotationAngle = yRotation
                }
                gesture.setTranslation(CGPoint.zero, in: sceneView)
                
            case .ended, .cancelled:
                isRotating = false
                onEnd?()
                
            default:
                break
            }
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard
                let sceneView = sceneView,
                let cameraNode = sceneView.scene?.rootNode.childNode(
                    withName: "cameraNode",
                    recursively: false
                )
            else { return }

            switch gesture.state {

            case .began:
                shouldAutoRotate = false

            case .changed:
                let delta = Float(gesture.scale - 1.0) * 20
                
                if let camera = cameraNode.camera {
                    let newFOV = max(30, min(100, camera.fieldOfView - CGFloat(delta)))
                    camera.fieldOfView = newFOV
                }
                
                gesture.scale = 1.0

            default:
                break
            }
        }
        
        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let sceneView = sceneView else { return }
            
            switch gesture.state {
            case .began:
                isRotating = true
                onStart?()
                shouldAutoRotate = false
                
            case .changed:
                if let scene = sceneView.scene {
                    var rotation = scene.rootNode.eulerAngles
                    rotation.z += Float(gesture.rotation)
                    scene.rootNode.eulerAngles = rotation
                }
                gesture.rotation = 0
                
            case .ended, .cancelled:
                isRotating = false
                onEnd?()
                
            default:
                break
            }
        }
        
        @objc func updateRotation() {
            guard shouldAutoRotate, let sceneView = sceneView else { return }
            
            if let scene = sceneView.scene {
                rotationAngle += 1.0
                var rotation = scene.rootNode.eulerAngles
                rotation.y = rotationAngle * Float.pi / 180.0
                scene.rootNode.eulerAngles = rotation
            }
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
            guard let sceneView = sceneView else { 
                CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToFront() - sceneView is NIL")
                return 
            }
            
            CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToFront() - Starting animation")
            DispatchQueue.main.async {
                if let scene = sceneView.scene {
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.5
                    scene.rootNode.eulerAngles = SCNVector3(0, 0, 0)
                    CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToFront() - Animation applied")
                    SCNTransaction.commit()
                }
                self.rotationAngle = 0
                CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToFront() - Completed")
            }
        }
        
        func rotateToLeft() {
            guard let sceneView = sceneView else { 
                CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToLeft() - sceneView is NIL")
                return 
            }
            
            CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToLeft() - Starting animation")
            DispatchQueue.main.async {
                if let scene = sceneView.scene {
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.5
                    scene.rootNode.eulerAngles = SCNVector3(0, Float.pi / 2, 0)
                    CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToLeft() - Animation applied")
                    SCNTransaction.commit()
                }
                self.rotationAngle = Float.pi / 2
                CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToLeft() - Completed")
            }
        }
        
        func rotateToRight() {
            guard let sceneView = sceneView else { 
                CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToRight() - sceneView is NIL")
                return 
            }
            
            CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToRight() - Starting animation")
            DispatchQueue.main.async {
                if let scene = sceneView.scene {
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.5
                    scene.rootNode.eulerAngles = SCNVector3(0, -Float.pi / 2, 0)
                    CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToRight() - Animation applied")
                    SCNTransaction.commit()
                }
                self.rotationAngle = -Float.pi / 2
                CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToRight() - Completed")
            }
        }
        
        func rotateToTop() {
            guard let sceneView = sceneView else { 
                CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToTop() - sceneView is NIL")
                return 
            }
            
            CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToTop() - Starting animation")
            DispatchQueue.main.async {
                if let scene = sceneView.scene {
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.5
                    scene.rootNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
                    CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToTop() - Animation applied")
                    SCNTransaction.commit()
                }
                CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToTop() - Completed")
            }
        }
        
        func rotateToBottom() {
            guard let sceneView = sceneView else { 
                CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToBottom() - sceneView is NIL")
                return 
            }
            
            CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToBottom() - Starting animation")
            DispatchQueue.main.async {
                if let scene = sceneView.scene {
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.5
                    scene.rootNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
                    CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToBottom() - Animation applied")
                    SCNTransaction.commit()
                }
                CommonFunctions.debugPrint(load: "SceneKit", message: "rotateToBottom() - Completed")
            }
        }
        
        func zoomIn() {
            guard let sceneView = sceneView else { 
                CommonFunctions.debugPrint(load: "SceneKit", message: "zoomIn() - sceneView is NIL")
                return 
            }
            
            CommonFunctions.debugPrint(load: "SceneKit", message: "zoomIn() - Starting animation")
            DispatchQueue.main.async {
                if let cameraNode = sceneView.scene?.rootNode.childNode(
                    withName: "cameraNode",
                    recursively: false
                ) {
                    let newDistance = max(2, cameraNode.position.z - 5)  // Closer zoom in allowed (min 2 instead of 3)
                    CommonFunctions.debugPrint(load: "SceneKit", message: "zoomIn() - Camera distance: \(cameraNode.position.z) → \(newDistance)")
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.3
                    cameraNode.position.z = newDistance
                    SCNTransaction.commit()
                    CommonFunctions.debugPrint(load: "SceneKit", message: "zoomIn() - Completed")
                }
            }
        }
        
        func zoomOut() {
            guard let sceneView = sceneView else { 
                CommonFunctions.debugPrint(load: "SceneKit", message: "zoomOut() - sceneView is NIL")
                return 
            }
            
            CommonFunctions.debugPrint(load: "SceneKit", message: "zoomOut() - Starting animation")
            DispatchQueue.main.async {
                if let cameraNode = sceneView.scene?.rootNode.childNode(
                    withName: "cameraNode",
                    recursively: false
                ) {
                    let newDistance = min(100, cameraNode.position.z + 5)  // Farther zoom out allowed (max 100 instead of 80)
                    CommonFunctions.debugPrint(load: "SceneKit", message: "zoomOut() - Camera distance: \(cameraNode.position.z) → \(newDistance)")
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.3
                    cameraNode.position.z = newDistance
                    SCNTransaction.commit()
                    CommonFunctions.debugPrint(load: "SceneKit", message: "zoomOut() - Completed")
                }
            }
        }
        
        func fitToView() {
            guard let sceneView = sceneView else { 
                CommonFunctions.debugPrint(load: "SceneKit", message: "fitToView() - sceneView is NIL")
                return 
            }
            
            CommonFunctions.debugPrint(load: "SceneKit", message: "fitToView() - Starting animation")
            DispatchQueue.main.async {
                if let cameraNode = sceneView.scene?.rootNode.childNode(
                    withName: "cameraNode",
                    recursively: false
                ) {
                    CommonFunctions.debugPrint(load: "SceneKit", message: "fitToView() - Resetting camera to initial position: \(self.initialCameraPosition.z)")
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.5
                    cameraNode.position.z = self.initialCameraPosition.z
                    SCNTransaction.commit()
                    CommonFunctions.debugPrint(load: "SceneKit", message: "fitToView() - Completed")
                }
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
