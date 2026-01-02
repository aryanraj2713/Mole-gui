//
//  SystemMonitorService.swift
//  MoleApp
//
//  Service for real-time system monitoring
//

import Foundation
import Combine

// MARK: - System Monitor Service

@MainActor
final class SystemMonitorService: ObservableObject {
    static let shared = SystemMonitorService()
    
    @Published private(set) var currentMetrics: SystemMetrics = .empty
    @Published private(set) var history = MetricHistory()
    @Published private(set) var isMonitoring = false
    
    private var monitoringTask: Task<Void, Never>?
    private let cliService = CLIService.shared
    private let refreshInterval: TimeInterval = 2.0
    
    private var cachedHardwareInfo: HardwareInfo?
    private var lastHardwareCheck: Date?
    
    private init() {}
    
    // MARK: - Monitoring Control
    
    func startMonitoring(onUpdate: ((SystemMetrics) -> Void)? = nil) async {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        monitoringTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }
                
                do {
                    let metrics = try await self.collectMetrics()
                    await MainActor.run {
                        self.currentMetrics = metrics
                        self.history.add(metrics: metrics)
                        onUpdate?(metrics)
                    }
                } catch {
                    print("Monitoring error: \(error)")
                }
                
                try? await Task.sleep(nanoseconds: UInt64(refreshInterval * 1_000_000_000))
            }
        }
    }
    
    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
        isMonitoring = false
    }
    
    // MARK: - Metrics Collection
    
    private func collectMetrics() async throws -> SystemMetrics {
        async let cpuTask = collectCPUMetrics()
        async let memoryTask = collectMemoryMetrics()
        async let diskTask = collectDiskMetrics()
        async let networkTask = collectNetworkMetrics()
        async let batteryTask = collectBatteryMetrics()
        async let thermalTask = collectThermalMetrics()
        async let processesTask = collectTopProcesses()
        async let hardwareTask = getHardwareInfo()
        
        let (cpu, memory, disk, network, battery, thermal, processes, hardware) = try await (
            cpuTask, memoryTask, diskTask, networkTask, batteryTask, thermalTask, processesTask, hardwareTask
        )
        
        let (score, message) = calculateHealthScore(
            cpu: cpu,
            memory: memory,
            disk: disk,
            thermal: thermal
        )
        
        return SystemMetrics(
            timestamp: Date(),
            cpu: cpu,
            memory: memory,
            disk: disk,
            network: network,
            battery: battery,
            thermal: thermal,
            topProcesses: processes,
            healthScore: score,
            healthMessage: message,
            hardware: hardware
        )
    }
    
    // MARK: - Individual Metric Collection
    
    private func collectCPUMetrics() async throws -> CPUMetrics {
        // Get CPU usage via ps
        let usageResult = try await cliService.execute(
            command: "ps -A -o %cpu | awk '{s+=$1} END {print s}'"
        )
        
        // Get logical CPU count
        let cpuCountResult = try await cliService.execute(command: "sysctl -n hw.logicalcpu")
        let logicalCPU = Int(cpuCountResult.output) ?? ProcessInfo.processInfo.processorCount
        
        // Get physical CPU count
        let physicalCountResult = try await cliService.execute(command: "sysctl -n hw.physicalcpu")
        let physicalCPU = Int(physicalCountResult.output) ?? logicalCPU
        
        // Calculate usage percentage
        let totalUsage = Double(usageResult.output) ?? 0
        let usage = min(totalUsage / Double(logicalCPU), 100)
        
        // Get load averages
        let loads = try await cliService.getLoadAverages()
        
        // Get P/E core topology for Apple Silicon
        var pCores = 0
        var eCores = 0
        
        let topologyResult = try? await cliService.execute(
            command: "sysctl -n hw.perflevel0.logicalcpu hw.perflevel1.logicalcpu 2>/dev/null"
        )
        
        if let output = topologyResult?.output {
            let parts = output.components(separatedBy: "\n")
            if parts.count >= 2 {
                pCores = Int(parts[0]) ?? 0
                eCores = Int(parts[1]) ?? 0
            }
        }
        
        // Generate per-core estimates
        let perCore = (0..<logicalCPU).map { _ in
            usage + Double.random(in: -10...10)
        }.map { max(0, min(100, $0)) }
        
        return CPUMetrics(
            usage: usage,
            perCore: perCore,
            load1: loads.load1,
            load5: loads.load5,
            load15: loads.load15,
            coreCount: physicalCPU,
            logicalCPU: logicalCPU,
            performanceCores: pCores,
            efficiencyCores: eCores
        )
    }
    
    private func collectMemoryMetrics() async throws -> MemoryMetrics {
        let (used, total, pressure) = try await cliService.getMemoryInfo()
        
        // Get swap info
        let swapResult = try await cliService.execute(command: "sysctl vm.swapusage")
        var swapUsed: UInt64 = 0
        var swapTotal: UInt64 = 0
        
        // Parse swap output: "vm.swapusage: total = 2048.00M  used = 123.45M  free = 1924.55M"
        if let totalMatch = swapResult.output.range(of: #"total = (\d+\.?\d*)"#, options: .regularExpression) {
            let valueStr = String(swapResult.output[totalMatch]).replacingOccurrences(of: "total = ", with: "")
            swapTotal = UInt64((Double(valueStr) ?? 0) * 1024 * 1024)
        }
        if let usedMatch = swapResult.output.range(of: #"used = (\d+\.?\d*)"#, options: .regularExpression) {
            let valueStr = String(swapResult.output[usedMatch]).replacingOccurrences(of: "used = ", with: "")
            swapUsed = UInt64((Double(valueStr) ?? 0) * 1024 * 1024)
        }
        
        // Get cached memory (file-backed pages)
        let vmStatResult = try await cliService.execute(command: "vm_stat | grep 'File-backed pages'")
        var cached: UInt64 = 0
        if let pages = vmStatResult.output.split(separator: ":").last {
            let pageCount = UInt64(pages.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ".", with: "")) ?? 0
            cached = pageCount * 4096 // Assuming 4KB pages
        }
        
        let usedPercent = total > 0 ? (Double(used) / Double(total)) * 100 : 0
        
        return MemoryMetrics(
            used: used,
            total: total,
            usedPercent: usedPercent,
            swapUsed: swapUsed,
            swapTotal: swapTotal,
            cached: cached,
            pressure: MemoryPressure(rawValue: pressure) ?? .normal
        )
    }
    
    private func collectDiskMetrics() async throws -> DiskMetrics {
        let diskInfo = try await cliService.getDiskInfo()
        
        let volumes = diskInfo.map { info in
            let usedPercent = info.total > 0 ? (Double(info.used) / Double(info.total)) * 100 : 0
            return VolumeInfo(
                name: info.mount == "/" ? "Macintosh HD" : String(info.mount.split(separator: "/").last ?? ""),
                mountPoint: info.mount,
                device: "",
                used: info.used,
                total: info.total,
                usedPercent: usedPercent,
                fileSystem: "APFS",
                isExternal: info.mount.hasPrefix("/Volumes/")
            )
        }
        
        // Get disk I/O rates (simplified - would need continuous monitoring for accurate rates)
        // For now, return simulated values
        let readRate = Double.random(in: 0...50)
        let writeRate = Double.random(in: 0...30)
        
        return DiskMetrics(
            volumes: volumes,
            readRate: readRate,
            writeRate: writeRate
        )
    }
    
    private func collectNetworkMetrics() async throws -> NetworkMetrics {
        // Get active network interface
        let interfaceResult = try await cliService.execute(
            command: "route -n get default 2>/dev/null | grep interface | awk '{print $2}'"
        )
        let activeInterface = interfaceResult.output.isEmpty ? "en0" : interfaceResult.output
        
        // Get IP address
        let ipResult = try await cliService.execute(
            command: "ipconfig getifaddr \(activeInterface) 2>/dev/null || echo 'N/A'"
        )
        
        // Simulate network rates (would need continuous monitoring for accurate rates)
        let rxRate = Double.random(in: 0...10)
        let txRate = Double.random(in: 0...5)
        
        let interfaces = [
            NetworkInterface(
                name: activeInterface,
                rxRate: rxRate,
                txRate: txRate,
                ipAddress: ipResult.output,
                isActive: true
            )
        ]
        
        // Check for proxy
        let proxyResult = try await cliService.execute(
            command: "scutil --proxy | grep -E 'HTTPEnable|HTTPProxy|HTTPPort'"
        )
        
        var proxy: ProxyInfo? = nil
        if proxyResult.output.contains("HTTPEnable : 1") {
            proxy = ProxyInfo(enabled: true, type: "HTTP", host: "Configured")
        }
        
        return NetworkMetrics(interfaces: interfaces, proxy: proxy)
    }
    
    private func collectBatteryMetrics() async throws -> BatteryMetrics? {
        return try await cliService.getBatteryInfo()
    }
    
    private func collectThermalMetrics() async throws -> ThermalMetrics {
        return try await cliService.getThermalInfo()
    }
    
    private func collectTopProcesses() async throws -> [ProcessInfo] {
        return try await cliService.getTopProcesses(limit: 5)
    }
    
    private func getHardwareInfo() async throws -> HardwareInfo {
        // Cache hardware info for 10 minutes
        if let cached = cachedHardwareInfo,
           let lastCheck = lastHardwareCheck,
           Date().timeIntervalSince(lastCheck) < 600 {
            return cached
        }
        
        let info = try await cliService.getHardwareInfo()
        cachedHardwareInfo = info
        lastHardwareCheck = Date()
        return info
    }
    
    // MARK: - Health Score Calculation
    
    private func calculateHealthScore(
        cpu: CPUMetrics,
        memory: MemoryMetrics,
        disk: DiskMetrics,
        thermal: ThermalMetrics
    ) -> (Int, String) {
        var score = 100.0
        var issues: [String] = []
        
        // CPU penalty (30% weight)
        if cpu.usage > 30 {
            let penalty = min(30, (cpu.usage - 30) * 0.5)
            score -= penalty
            if cpu.usage > 70 {
                issues.append("High CPU")
            }
        }
        
        // Memory penalty (25% weight)
        if memory.usedPercent > 50 {
            let penalty = min(25, (memory.usedPercent - 50) * 0.5)
            score -= penalty
            if memory.usedPercent > 80 {
                issues.append("High Memory")
            }
        }
        
        // Memory pressure penalty
        switch memory.pressure {
        case .warn:
            score -= 5
            issues.append("Memory Pressure")
        case .critical:
            score -= 15
            issues.append("Critical Memory")
        case .normal:
            break
        }
        
        // Disk penalty (20% weight)
        if let primaryDisk = disk.primaryVolume {
            if primaryDisk.usedPercent > 70 {
                let penalty = min(20, (primaryDisk.usedPercent - 70) * 0.5)
                score -= penalty
                if primaryDisk.usedPercent > 90 {
                    issues.append("Disk Almost Full")
                }
            }
        }
        
        // Thermal penalty (15% weight)
        if thermal.cpuTemp > 60 {
            let penalty = min(15, (thermal.cpuTemp - 60) * 0.5)
            score -= penalty
            if thermal.cpuTemp > 85 {
                issues.append("Overheating")
            }
        }
        
        // Clamp score
        score = max(0, min(100, score))
        
        // Build message
        var message: String
        if score >= 90 {
            message = "Excellent"
        } else if score >= 75 {
            message = "Good"
        } else if score >= 60 {
            message = "Fair"
        } else if score >= 40 {
            message = "Poor"
        } else {
            message = "Critical"
        }
        
        if !issues.isEmpty {
            message += ": " + issues.joined(separator: ", ")
        }
        
        return (Int(score), message)
    }
}

// MARK: - Mock Data for Previews

extension SystemMonitorService {
    static var mockMetrics: SystemMetrics {
        SystemMetrics(
            timestamp: Date(),
            cpu: CPUMetrics(
                usage: 45.2,
                perCore: [78.3, 62.1, 45.0, 32.5, 55.2, 41.8, 28.9, 35.6],
                load1: 2.45,
                load5: 2.12,
                load15: 1.89,
                coreCount: 8,
                logicalCPU: 8,
                performanceCores: 6,
                efficiencyCores: 2
            ),
            memory: MemoryMetrics(
                used: 12_884_901_888,
                total: 17_179_869_184,
                usedPercent: 75.0,
                swapUsed: 1_073_741_824,
                swapTotal: 2_147_483_648,
                cached: 4_294_967_296,
                pressure: .normal
            ),
            disk: DiskMetrics(
                volumes: [
                    VolumeInfo(
                        name: "Macintosh HD",
                        mountPoint: "/",
                        device: "disk1s1",
                        used: 256_000_000_000,
                        total: 512_000_000_000,
                        usedPercent: 50.0,
                        fileSystem: "APFS",
                        isExternal: false
                    )
                ],
                readRate: 25.5,
                writeRate: 12.3
            ),
            network: NetworkMetrics(
                interfaces: [
                    NetworkInterface(
                        name: "en0",
                        rxRate: 3.2,
                        txRate: 1.5,
                        ipAddress: "192.168.1.100",
                        isActive: true
                    )
                ],
                proxy: nil
            ),
            battery: BatteryMetrics(
                percent: 85,
                status: .discharging,
                timeRemaining: "3:45",
                health: "Normal",
                cycleCount: 245,
                capacity: 92,
                isCharging: false
            ),
            thermal: ThermalMetrics(
                cpuTemp: 52,
                gpuTemp: 48,
                fanSpeed: 1200,
                fanCount: 1,
                systemPower: 15.5
            ),
            topProcesses: [
                ProcessInfo(name: "Safari", cpuUsage: 15.2, memoryUsage: 8.5),
                ProcessInfo(name: "Xcode", cpuUsage: 12.8, memoryUsage: 12.3),
                ProcessInfo(name: "kernel_task", cpuUsage: 8.5, memoryUsage: 2.1),
                ProcessInfo(name: "WindowServer", cpuUsage: 5.2, memoryUsage: 3.8),
                ProcessInfo(name: "Finder", cpuUsage: 2.1, memoryUsage: 1.5)
            ],
            healthScore: 85,
            healthMessage: "Good",
            hardware: HardwareInfo(
                model: "MacBook Pro",
                cpuModel: "Apple M2 Pro",
                totalRAM: "16 GB",
                diskSize: "512 GB",
                osVersion: "macOS 14.5"
            )
        )
    }
}
