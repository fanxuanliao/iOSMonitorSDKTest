//
//  PerformanceMonitor.swift
//  PerformanceMonitor
//
//  Created by Fan Xuan Liao on 2024/3/2.
//

import Foundation
import QuartzCore

@objc public class PerformanceMonitor : NSObject {
    
    @objc public static let shared = PerformanceMonitor()
    var isTracking = false
    var startCPUUsage: host_cpu_load_info?
    var endCPUUsage: host_cpu_load_info?
    var startRAMUsage: UInt64 = 0
    var endRAMUsage: UInt64 = 0
    var displayLink: CADisplayLink?
    private var lastFPSUpdateTime: TimeInterval = 0
    private var frameCount: Int = 0

    @objc public func startTracking() {
        
        guard !isTracking else { return }
        isTracking = true
        startCPUUsage = getCPULoadInfo()
        startRAMUsage = getCurrentRAMUsage()
        frameCount = 0
        lastFPSUpdateTime = 0
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc public func stopTracking() {
      
        guard isTracking else { return }
        isTracking = false
        endCPUUsage = getCPULoadInfo()
        endRAMUsage = getCurrentRAMUsage()
        displayLink?.invalidate()
        displayLink = nil
    }

    func getCPULoadInfo() -> host_cpu_load_info? {
        var size = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let hostInfo = host_cpu_load_info_t.allocate(capacity: 1)
        defer { hostInfo.deallocate() }
        
        let kerr = withUnsafeMutablePointer(to: &hostInfo.pointee) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return hostInfo.move()
        } else {
            print("Error - \(#file): \(#function) - kern_result_t = \(kerr)")
            return nil
        }
    }

    public func calculateAverageCPUUsage(startUsage: host_cpu_load_info?, endUsage: host_cpu_load_info?) -> Double {
        guard let startInfo = startUsage, let endInfo = endUsage else {
            return 0.0
        }
        
        let userDiff = Double(endInfo.cpu_ticks.0 - startInfo.cpu_ticks.0)
        let systemDiff = Double(endInfo.cpu_ticks.1 - startInfo.cpu_ticks.1)
        let idleDiff = Double(endInfo.cpu_ticks.2 - startInfo.cpu_ticks.2)
        let niceDiff = Double(endInfo.cpu_ticks.3 - startInfo.cpu_ticks.3)
        
        let totalTicks = userDiff + systemDiff + idleDiff + niceDiff
        let totalUsed = userDiff + systemDiff + niceDiff // Exclude idle time
        
        if totalTicks == 0 { return 0.0 }
        
        let averageCpuUsage = (totalUsed / totalTicks) * 100.0
        return averageCpuUsage
    }
    
    @objc public func getAverageCPUUsage() -> Double {
        return calculateAverageCPUUsage(startUsage: startCPUUsage, endUsage: endCPUUsage)
    }

     func getCurrentRAMUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / mach_msg_type_number_t(MemoryLayout<natural_t>.size)

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0.withMemoryRebound(to: integer_t.self, capacity: 1) { $0 }, &count)
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size // current ram usage
        } else {
            print("Error with task_info(): \(kerr)")
            return 0
        }
    }
    
    @objc public func getRAMIncreasedUsage()-> Double {
        return Double(endRAMUsage > startRAMUsage ? endRAMUsage - startRAMUsage : 0)
    }

    @objc func handleDisplayLink(_ displayLink: CADisplayLink){

        guard isTracking else { return }
        if lastFPSUpdateTime == 0 {
            lastFPSUpdateTime = displayLink.timestamp
        }
        
        frameCount += 1
    }
    
    @objc public func getAverageFPS() -> Double {
        
        if lastFPSUpdateTime > 0 {
            let elapsedTime = CACurrentMediaTime() - lastFPSUpdateTime
            return Double(frameCount) / elapsedTime
        }
        return 0
    }
}
