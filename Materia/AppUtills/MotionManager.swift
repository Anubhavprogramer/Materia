//
//  MotionManager.swift
//  Materia
//
//  Device motion tracking for interactive 3D effects
//

import Foundation
import CoreMotion

class MotionManager: NSObject, ObservableObject {
    private let motionManager = CMMotionManager()
    
    @Published var pitch: Double = 0.0  // Rotation around X-axis (tilt forward/backward)
    @Published var roll: Double = 0.0   // Rotation around Z-axis (tilt left/right)
    @Published var yaw: Double = 0.0    // Rotation around Y-axis (rotation)
    
    @Published var isMotionAvailable = false
    
    override init() {
        super.init()
        setupMotionManager()
    }
    
    private func setupMotionManager() {
        guard motionManager.isDeviceMotionAvailable else {
            isMotionAvailable = false
            return
        }
        
        isMotionAvailable = true
        motionManager.deviceMotionUpdateInterval = 0.016  // ~60 FPS
        
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            
            let attitude = motion.attitude
            
            // Convert radians to degrees for easier manipulation
            self.pitch = attitude.pitch * 180 / .pi
            self.roll = attitude.roll * 180 / .pi
            self.yaw = attitude.yaw * 180 / .pi
        }
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
    
    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            
            let attitude = motion.attitude
            self.pitch = attitude.pitch * 180 / .pi
            self.roll = attitude.roll * 180 / .pi
            self.yaw = attitude.yaw * 180 / .pi
        }
    }
}
