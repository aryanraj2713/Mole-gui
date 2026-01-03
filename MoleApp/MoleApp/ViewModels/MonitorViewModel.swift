//
//  MonitorViewModel.swift
//  MoleApp
//
//  ViewModel for the Monitor view
//

import Foundation
import Combine

@MainActor
final class MonitorViewModel: ObservableObject {
    @Published var metrics: SystemMetrics = .empty
    @Published var history = MetricHistory()
    @Published var isMonitoring = false
    @Published var selectedMetricType: MetricType = .cpu
    @Published var refreshRate: RefreshRate = .normal
    
    private let monitorService = SystemMonitorService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        monitorService.$currentMetrics
            .receive(on: DispatchQueue.main)
            .assign(to: &$metrics)
        
        monitorService.$history
            .receive(on: DispatchQueue.main)
            .assign(to: &$history)
        
        monitorService.$isMonitoring
            .receive(on: DispatchQueue.main)
            .assign(to: &$isMonitoring)
    }
    
    func startMonitoring() {
        Task {
            await monitorService.startMonitoring()
        }
    }
    
    func stopMonitoring() {
        monitorService.stopMonitoring()
    }
    
    func toggleMonitoring() {
        if isMonitoring {
            stopMonitoring()
        } else {
            startMonitoring()
        }
    }
    
    // MARK: - Chart Data
    
    var currentChartData: [Double] {
        switch selectedMetricType {
        case .cpu:
            return history.cpuHistory
        case .memory:
            return history.memoryHistory
        case .diskRead:
            return history.diskReadHistory
        case .diskWrite:
            return history.diskWriteHistory
        case .networkRx:
            return history.networkRxHistory
        case .networkTx:
            return history.networkTxHistory
        }
    }
    
    var chartTitle: String {
        selectedMetricType.displayName
    }
    
    var chartUnit: String {
        selectedMetricType.unit
    }
    
    var chartColor: String {
        selectedMetricType.color
    }
}

// MARK: - Metric Type

enum MetricType: String, CaseIterable, Identifiable {
    case cpu = "CPU"
    case memory = "Memory"
    case diskRead = "Disk Read"
    case diskWrite = "Disk Write"
    case networkRx = "Network ↓"
    case networkTx = "Network ↑"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var unit: String {
        switch self {
        case .cpu, .memory:
            return "%"
        case .diskRead, .diskWrite, .networkRx, .networkTx:
            return "MB/s"
        }
    }
    
    var color: String {
        switch self {
        case .cpu: return "#3B82F6"
        case .memory: return "#8B5CF6"
        case .diskRead: return "#10B981"
        case .diskWrite: return "#F59E0B"
        case .networkRx: return "#06B6D4"
        case .networkTx: return "#EC4899"
        }
    }
    
    var icon: String {
        switch self {
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        case .diskRead, .diskWrite: return "internaldrive"
        case .networkRx, .networkTx: return "network"
        }
    }
}

// MARK: - Refresh Rate

enum RefreshRate: String, CaseIterable, Identifiable {
    case slow = "Slow (5s)"
    case normal = "Normal (2s)"
    case fast = "Fast (1s)"
    
    var id: String { rawValue }
    
    var interval: TimeInterval {
        switch self {
        case .slow: return 5.0
        case .normal: return 2.0
        case .fast: return 1.0
        }
    }
}
