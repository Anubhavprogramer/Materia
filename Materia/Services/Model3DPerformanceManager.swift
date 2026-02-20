//
//  Model3DPerformanceManager.swift
//  Materia
//
//  Performance monitoring and optimization for 3D viewer
//

import Foundation
import SceneKit

class Model3DPerformanceManager {
    
    static let shared = Model3DPerformanceManager()
    
    // MARK: - Properties
    private var memoryMetrics: MemoryMetrics = MemoryMetrics()
    private var performanceLog: [PerformanceEntry] = []
    private let metricsLock = NSLock()
    
    // MARK: - Configuration
    struct Config {
        static let maxCacheSize = 50  // Maximum models to cache
        static let maxMemoryMB: Float = 100  // Maximum memory for cache
        static let enableMetrics = true  // Enable performance tracking
        static let targetFrameRate = 60  // Target FPS
    }
    
    // MARK: - Models
    private struct MemoryMetrics {
        var usedMemoryMB: Float = 0
        var peakMemoryMB: Float = 0
        var cachedModelsCount: Int = 0
        var lastUpdateTime: Date = Date()
    }
    
    private struct PerformanceEntry {
        let timestamp: Date
        let action: String
        let duration: TimeInterval
        let memoryBefore: Float
        let memoryAfter: Float
    }
    
    // MARK: - Public Methods
    
    /// Start monitoring 3D generation
    func startMonitoring(for action: String) -> String {
        let entryId = UUID().uuidString
        let memoryBefore = getMemoryUsage()
        
        metricsLock.lock()
        performanceLog.append(
            PerformanceEntry(
                timestamp: Date(),
                action: "\(action)_start",
                duration: 0,
                memoryBefore: memoryBefore,
                memoryAfter: memoryBefore
            )
        )
        metricsLock.unlock()
        
        return entryId
    }
    
    /// End monitoring 3D generation
    func endMonitoring(entryId: String, action: String) -> PerformanceSummary {
        let memoryAfter = getMemoryUsage()
        let startTime = Date()
        
        metricsLock.lock()
        defer { metricsLock.unlock() }
        
        let memoryBefore = performanceLog.last?.memoryBefore ?? 0
        let duration = -startTime.timeIntervalSinceNow
        
        performanceLog.append(
            PerformanceEntry(
                timestamp: Date(),
                action: "\(action)_end",
                duration: duration,
                memoryBefore: memoryBefore,
                memoryAfter: memoryAfter
            )
        )
        
        return PerformanceSummary(
            action: action,
            duration: duration,
            memoryBefore: memoryBefore,
            memoryAfter: memoryAfter,
            memoryDelta: memoryAfter - memoryBefore
        )
    }
    
    /// Get current memory usage in MB
    func getMemoryUsage() -> Float {
        var info = task_vm_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size)/4
        
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(TASK_VM_INFO),
                         $0,
                         &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else { return 0 }
        
        let usedMemory = Float(info.phys_footprint) / 1024 / 1024
        return usedMemory
    }
    
    /// Check if cache is within limits
    func shouldContinueCaching() -> Bool {
        metricsLock.lock()
        defer { metricsLock.unlock() }
        
        let memoryOK = memoryMetrics.usedMemoryMB < Config.maxMemoryMB
        let countOK = memoryMetrics.cachedModelsCount < Config.maxCacheSize
        
        return memoryOK && countOK
    }
    
    /// Clear cache if memory exceeds threshold
    func optimizeMemoryIfNeeded() {
        let currentMemory = getMemoryUsage()
        
        if currentMemory > Config.maxMemoryMB {
            Model3DGenerator.clearCache()
        }
    }
    
    /// Get performance report
    func getPerformanceReport() -> PerformanceReport {
        metricsLock.lock()
        defer { metricsLock.unlock() }
        
        let currentMemory = getMemoryUsage()
        let cacheSize = Model3DGenerator.getCacheSize()
        let totalDuration = performanceLog.reduce(0) { $0 + $1.duration }
        
        return PerformanceReport(
            currentMemoryMB: currentMemory,
            peakMemoryMB: memoryMetrics.peakMemoryMB,
            cachedModels: cacheSize,
            totalOperations: performanceLog.count,
            totalDurationSeconds: totalDuration,
            averageOperationTime: performanceLog.isEmpty ? 0 : totalDuration / Double(performanceLog.count)
        )
    }
    
    /// Clear all metrics
    func resetMetrics() {
        metricsLock.lock()
        defer { metricsLock.unlock() }
        
        performanceLog.removeAll()
        memoryMetrics = MemoryMetrics()
    }
    
    // MARK: - Models
    
    struct PerformanceSummary {
        let action: String
        let duration: TimeInterval
        let memoryBefore: Float
        let memoryAfter: Float
        let memoryDelta: Float
    }
    
    struct PerformanceReport {
        let currentMemoryMB: Float
        let peakMemoryMB: Float
        let cachedModels: Int
        let totalOperations: Int
        let totalDurationSeconds: TimeInterval
        let averageOperationTime: TimeInterval
    }
}

// MARK: - Task VM Info (for memory measurement)
import Darwin

struct task_vm_info {
    var resident_size: UInt64 = 0
    var virtual_size: UInt64 = 0
    var phys_footprint: UInt64 = 0
}
