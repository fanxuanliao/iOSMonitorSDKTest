//
//  UnityNativeBridge.m
//  PerformanceMonitor
//
//  Created by Fan Xuan Liao on 2024/3/2.
//

#include <PerformanceMonitor/PerformanceMonitor-Swift.h>

extern "C"{
    
    void _startTracking() {
        [[PerformanceMonitor shared] startTracking];
    }

    void _stopTracking() {
        [[PerformanceMonitor shared] stopTracking];
    }

    double _getCPUUsage(){
        return [[PerformanceMonitor shared] getAverageCPUUsage];
    }

    double _getRAMUsage(){
        return [[PerformanceMonitor shared] getRAMIncreasedUsage];
    }

    double _getFPSAverage(){
        return [[PerformanceMonitor shared] getAverageFPS];
    }
}
