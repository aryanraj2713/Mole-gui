//
//  SystemModels.swift
//  MoleApp
//
//  Data models for system monitoring and metrics
//

import Foundation

// MARK: - System Metrics

struct SystemMetrics: Equatable {
    let timestamp: Date
    let cpu: CPUMetrics
    let memory: MemoryMetrics
    let disk: DiskMetrics
    let network: NetworkMetrics
    let battery: BatteryMetrics?
    let thermal: ThermalMetrics
    let topProcesses: [ProcessInfo]
    let healthScore: Int
    let healthMessage: String
    let hardware: HardwareInfo
    
    static let empty = SystemMetrics(
        timestamp: Date(),
        cpu: .empty,
        memory: .empty,
        disk: .empty,
        network: .empty,
        battery: nil,
        thermal: .empty,
        topProcesses: [],
        healthScore: 0,
        healthMessage: "Loading...",
        hardware: .empty
    )
}

// MARK: - CPU Metrics

struct CPUMetrics: Equatable {
    let usage: Double
    let perCore: [Double]
    let load1: Double
    let load5: Double
    let load15: Double
    let coreCount: Int
    let logicalCPU: Int
    let performanceCores: Int
    let efficiencyCores: Int
    
    var usageFormatted: String {
        String(format: "%.1f%%", usage)
    }
    
    var loadAverage: String {
        String(format: "%.2f / %.2f / %.2f", load1, load5, load15)
    }
    
    static let empty = CPUMetrics(
        usage: 0,
        perCore: [],
        load1: 0,
        load5: 0,
        load15: 0,
        coreCount: 0,
        logicalCPU: 0,
        performanceCores: 0,
        efficiencyCores: 0
    )
}

// MARK: - Memory Metrics

struct MemoryMetrics: Equatable {
    let used: UInt64
    let total: UInt64
    let usedPercent: Double
    let swapUsed: UInt64
    let swapTotal: UInt64
    let cached: UInt64
    let pressure: MemoryPressure
    
    var usedFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(used), countStyle: .memory)
    }
    
    var totalFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .memory)
    }
    
    var availableFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(total - used), countStyle: .memory)
    }
    
    static let empty = MemoryMetrics(
        used: 0,
        total: 0,
        usedPercent: 0,
        swapUsed: 0,
        swapTotal: 0,
        cached: 0,
        pressure: .normal
    )
}

enum MemoryPressure: String, Equatable {
    case normal
    case warn
    case critical
    
    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .warn: return "Warning"
        case .critical: return "Critical"
        }
    }
}

// MARK: - Disk Metrics

struct DiskMetrics: Equatable {
    let volumes: [VolumeInfo]
    let readRate: Double  // MB/s
    let writeRate: Double // MB/s
    
    var primaryVolume: VolumeInfo? {
        volumes.first { $0.mountPoint == "/" }
    }
    
    static let empty = DiskMetrics(volumes: [], readRate: 0, writeRate: 0)
}

struct VolumeInfo: Equatable, Identifiable {
    let id = UUID()
    let name: String
    let mountPoint: String
    let device: String
    let used: UInt64
    let total: UInt64
    let usedPercent: Double
    let fileSystem: String
    let isExternal: Bool
    
    var usedFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(used), countStyle: .file)
    }
    
    var totalFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .file)
    }
    
    var freeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(total - used), countStyle: .file)
    }
    
    static func == (lhs: VolumeInfo, rhs: VolumeInfo) -> Bool {
        lhs.mountPoint == rhs.mountPoint && lhs.used == rhs.used
    }
}

// MARK: - Network Metrics

struct NetworkMetrics: Equatable {
    let interfaces: [NetworkInterface]
    let proxy: ProxyInfo?
    
    var primaryInterface: NetworkInterface? {
        interfaces.first { $0.isActive }
    }
    
    static let empty = NetworkMetrics(interfaces: [], proxy: nil)
}

struct NetworkInterface: Equatable, Identifiable {
    let id = UUID()
    let name: String
    let rxRate: Double  // MB/s
    let txRate: Double  // MB/s
    let ipAddress: String
    let isActive: Bool
    
    static func == (lhs: NetworkInterface, rhs: NetworkInterface) -> Bool {
        lhs.name == rhs.name && lhs.rxRate == rhs.rxRate && lhs.txRate == rhs.txRate
    }
}

struct ProxyInfo: Equatable {
    let enabled: Bool
    let type: String
    let host: String
}

// MARK: - Battery Metrics

struct BatteryMetrics: Equatable {
    let percent: Double
    let status: BatteryStatus
    let timeRemaining: String?
    let health: String
    let cycleCount: Int
    let capacity: Int
    let isCharging: Bool
    
    var percentFormatted: String {
        String(format: "%.0f%%", percent)
    }
}

enum BatteryStatus: String, Equatable {
    case charging = "Charging"
    case discharging = "Discharging"
    case full = "Charged"
    case unknown = "Unknown"
}

// MARK: - Thermal Metrics

struct ThermalMetrics: Equatable {
    let cpuTemp: Double
    let gpuTemp: Double
    let fanSpeed: Int
    let fanCount: Int
    let systemPower: Double
    
    var cpuTempFormatted: String {
        cpuTemp > 0 ? String(format: "%.0f°C", cpuTemp) : "N/A"
    }
    
    var fanSpeedFormatted: String {
        fanSpeed > 0 ? "\(fanSpeed) RPM" : "N/A"
    }
    
    static let empty = ThermalMetrics(
        cpuTemp: 0,
        gpuTemp: 0,
        fanSpeed: 0,
        fanCount: 0,
        systemPower: 0
    )
}

// MARK: - Process Info

struct ProcessInfo: Equatable, Identifiable {
    let id = UUID()
    let name: String
    let cpuUsage: Double
    let memoryUsage: Double
    
    var cpuFormatted: String {
        String(format: "%.1f%%", cpuUsage)
    }
    
    var memoryFormatted: String {
        String(format: "%.1f%%", memoryUsage)
    }
    
    static func == (lhs: ProcessInfo, rhs: ProcessInfo) -> Bool {
        lhs.name == rhs.name && lhs.cpuUsage == rhs.cpuUsage
    }
}

// MARK: - Hardware Info

struct HardwareInfo: Equatable {
    let model: String
    let cpuModel: String
    let totalRAM: String
    let diskSize: String
    let osVersion: String
    
    static let empty = HardwareInfo(
        model: "Unknown",
        cpuModel: "Unknown",
        totalRAM: "Unknown",
        diskSize: "Unknown",
        osVersion: "Unknown"
    )
}

// MARK: - Metric History

struct MetricHistory {
    var cpuHistory: [Double] = []
    var memoryHistory: [Double] = []
    var diskReadHistory: [Double] = []
    var diskWriteHistory: [Double] = []
    var networkRxHistory: [Double] = []
    var networkTxHistory: [Double] = []
    
    let maxPoints = 60
    
    mutating func add(metrics: SystemMetrics) {
        cpuHistory.append(metrics.cpu.usage)
        memoryHistory.append(metrics.memory.usedPercent)
        diskReadHistory.append(metrics.disk.readRate)
        diskWriteHistory.append(metrics.disk.writeRate)
        
        if let network = metrics.network.primaryInterface {
            networkRxHistory.append(network.rxRate)
            networkTxHistory.append(network.txRate)
        }
        
        // Trim to maxPoints
        if cpuHistory.count > maxPoints { cpuHistory.removeFirst() }
        if memoryHistory.count > maxPoints { memoryHistory.removeFirst() }
        if diskReadHistory.count > maxPoints { diskReadHistory.removeFirst() }
        if diskWriteHistory.count > maxPoints { diskWriteHistory.removeFirst() }
        if networkRxHistory.count > maxPoints { networkRxHistory.removeFirst() }
        if networkTxHistory.count > maxPoints { networkTxHistory.removeFirst() }
    }
}

// MARK: - Log Entry

struct LogEntry: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let type: LogType
    let source: String
    
    init(message: String, type: LogType, source: String = "System") {
        self.timestamp = Date()
        self.message = message
        self.type = type
        self.source = source
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
    
    static func == (lhs: LogEntry, rhs: LogEntry) -> Bool {
        lhs.id == rhs.id
    }
}

enum LogType: String {
    case info = "INFO"
    case success = "SUCCESS"
    case warning = "WARNING"
    case error = "ERROR"
    case debug = "DEBUG"
}
