//
//  CLIService.swift
//  MoleApp
//
//  Service for executing CLI commands and capturing output
//

import Foundation

// MARK: - CLI Service

actor CLIService {
    static let shared = CLIService()
    
    private init() {}
    
    // MARK: - Command Execution
    
    struct CommandResult {
        let output: String
        let errorOutput: String
        let exitCode: Int32
        let duration: TimeInterval
        
        var success: Bool { exitCode == 0 }
    }
    
    /// Execute a shell command and return the result
    func execute(
        command: String,
        arguments: [String] = [],
        workingDirectory: String? = nil,
        timeout: TimeInterval = 30
    ) async throws -> CommandResult {
        let startTime = Date()
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", ([command] + arguments).joined(separator: " ")]
        
        if let workingDir = workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDir)
        }
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Set up timeout
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            if process.isRunning {
                process.terminate()
            }
        }
        
        defer {
            timeoutTask.cancel()
        }
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            let output = String(data: outputData, encoding: .utf8) ?? ""
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            
            let duration = Date().timeIntervalSince(startTime)
            
            return CommandResult(
                output: output.trimmingCharacters(in: .whitespacesAndNewlines),
                errorOutput: errorOutput.trimmingCharacters(in: .whitespacesAndNewlines),
                exitCode: process.terminationStatus,
                duration: duration
            )
        } catch {
            throw CLIError.executionFailed(error.localizedDescription)
        }
    }
    
    /// Execute a command with elevated privileges using osascript
    func executeWithPrivileges(
        command: String,
        reason: String
    ) async throws -> CommandResult {
        let script = """
        do shell script "\(command.replacingOccurrences(of: "\"", with: "\\\""))" with administrator privileges
        """
        
        return try await execute(
            command: "osascript",
            arguments: ["-e", "'\(script)'"]
        )
    }
    
    // MARK: - Mole CLI Integration
    
    /// Find the mole CLI executable path
    func findMolePath() async -> String? {
        // Check common installation paths
        let paths = [
            "/usr/local/bin/mole",
            "/opt/homebrew/bin/mole",
            NSHomeDirectory() + "/.local/bin/mole",
            "/usr/local/bin/mo"
        ]
        
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // Try to find via which command
        if let result = try? await execute(command: "which mole"),
           result.success,
           !result.output.isEmpty {
            return result.output
        }
        
        return nil
    }
    
    /// Execute a mole command
    func executeMole(
        command: String,
        arguments: [String] = [],
        dryRun: Bool = false
    ) async throws -> CommandResult {
        guard let molePath = await findMolePath() else {
            throw CLIError.moleNotFound
        }
        
        var args = arguments
        if dryRun {
            args.append("--dry-run")
        }
        
        let fullCommand = "\(molePath) \(command) \(args.joined(separator: " "))"
        return try await execute(command: fullCommand, timeout: 300)
    }
}

// MARK: - CLI Errors

enum CLIError: LocalizedError {
    case executionFailed(String)
    case timeout
    case moleNotFound
    case permissionDenied
    case invalidOutput
    
    var errorDescription: String? {
        switch self {
        case .executionFailed(let message):
            return "Command execution failed: \(message)"
        case .timeout:
            return "Command timed out"
        case .moleNotFound:
            return "Mole CLI not found. Please install mole first."
        case .permissionDenied:
            return "Permission denied. Admin access may be required."
        case .invalidOutput:
            return "Invalid command output"
        }
    }
}

// MARK: - Shell Commands

extension CLIService {
    
    /// Get CPU usage percentage
    func getCPUUsage() async throws -> Double {
        let result = try await execute(
            command: "ps -A -o %cpu | awk '{s+=$1} END {print s/NR}'"
        )
        return Double(result.output) ?? 0
    }
    
    /// Get memory info using vm_stat
    func getMemoryInfo() async throws -> (used: UInt64, total: UInt64, pressure: String) {
        // Get total memory
        let totalResult = try await execute(command: "sysctl -n hw.memsize")
        let total = UInt64(totalResult.output) ?? 0
        
        // Get vm_stat for used calculation
        let vmResult = try await execute(command: "vm_stat")
        let lines = vmResult.output.components(separatedBy: "\n")
        
        // Parse page size
        var pageSize: UInt64 = 4096
        if let firstLine = lines.first,
           let range = firstLine.range(of: "page size of "),
           let endRange = firstLine.range(of: " bytes") {
            let sizeStr = String(firstLine[range.upperBound..<endRange.lowerBound])
            pageSize = UInt64(sizeStr) ?? 4096
        }
        
        // Parse pages
        var activePages: UInt64 = 0
        var wiredPages: UInt64 = 0
        var compressedPages: UInt64 = 0
        
        for line in lines {
            if line.contains("Pages active") {
                activePages = parseVMStatValue(line)
            } else if line.contains("Pages wired") {
                wiredPages = parseVMStatValue(line)
            } else if line.contains("Pages occupied by compressor") {
                compressedPages = parseVMStatValue(line)
            }
        }
        
        let used = (activePages + wiredPages + compressedPages) * pageSize
        
        // Get memory pressure
        let pressureResult = try await execute(command: "memory_pressure 2>/dev/null || echo 'normal'")
        var pressure = "normal"
        if pressureResult.output.lowercased().contains("critical") {
            pressure = "critical"
        } else if pressureResult.output.lowercased().contains("warn") {
            pressure = "warn"
        }
        
        return (used, total, pressure)
    }
    
    private func parseVMStatValue(_ line: String) -> UInt64 {
        let components = line.components(separatedBy: ":")
        guard components.count > 1 else { return 0 }
        let valueStr = components[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ".", with: "")
        return UInt64(valueStr) ?? 0
    }
    
    /// Get disk usage info
    func getDiskInfo() async throws -> [(mount: String, used: UInt64, total: UInt64)] {
        let result = try await execute(
            command: "df -k | grep -E '^/dev' | awk '{print $9,$3,$4}'"
        )
        
        var disks: [(mount: String, used: UInt64, total: UInt64)] = []
        
        for line in result.output.components(separatedBy: "\n") {
            let parts = line.components(separatedBy: " ")
            guard parts.count >= 3 else { continue }
            
            let mount = parts[0]
            let used = (UInt64(parts[1]) ?? 0) * 1024
            let available = (UInt64(parts[2]) ?? 0) * 1024
            let total = used + available
            
            // Skip system volumes
            if mount.hasPrefix("/System/Volumes/") { continue }
            
            disks.append((mount, used, total))
        }
        
        return disks
    }
    
    /// Get top processes by CPU usage
    func getTopProcesses(limit: Int = 5) async throws -> [ProcessInfo] {
        let result = try await execute(
            command: "ps -Aceo comm,%cpu,%mem | sort -k2 -nr | head -\(limit + 1) | tail -\(limit)"
        )
        
        var processes: [ProcessInfo] = []
        
        for line in result.output.components(separatedBy: "\n") {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 3 else { continue }
            
            let name = String(parts[0])
            let cpu = Double(parts[1]) ?? 0
            let mem = Double(parts[2]) ?? 0
            
            processes.append(ProcessInfo(name: name, cpuUsage: cpu, memoryUsage: mem))
        }
        
        return processes
    }
    
    /// Get hardware info
    func getHardwareInfo() async throws -> HardwareInfo {
        async let modelResult = execute(command: "sysctl -n hw.model")
        async let cpuResult = execute(command: "sysctl -n machdep.cpu.brand_string 2>/dev/null || sysctl -n hw.model")
        async let memResult = execute(command: "sysctl -n hw.memsize")
        async let osResult = execute(command: "sw_vers -productVersion")
        
        let (model, cpu, mem, os) = try await (modelResult, cpuResult, memResult, osResult)
        
        let totalRAM = UInt64(mem.output) ?? 0
        let ramFormatted = ByteCountFormatter.string(fromByteCount: Int64(totalRAM), countStyle: .memory)
        
        // Get disk size
        let diskInfo = try await getDiskInfo()
        let primaryDisk = diskInfo.first { $0.mount == "/" }
        let diskSize = primaryDisk.map { ByteCountFormatter.string(fromByteCount: Int64($0.total), countStyle: .file) } ?? "Unknown"
        
        return HardwareInfo(
            model: model.output.isEmpty ? "Mac" : model.output,
            cpuModel: cpu.output.isEmpty ? "Unknown" : cpu.output,
            totalRAM: ramFormatted,
            diskSize: diskSize,
            osVersion: "macOS \(os.output)"
        )
    }
    
    /// Get load averages
    func getLoadAverages() async throws -> (load1: Double, load5: Double, load15: Double) {
        let result = try await execute(command: "sysctl -n vm.loadavg")
        let parts = result.output
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")
            .split(separator: " ")
            .compactMap { Double($0) }
        
        guard parts.count >= 3 else {
            return (0, 0, 0)
        }
        
        return (parts[0], parts[1], parts[2])
    }
    
    /// Get battery info (if available)
    func getBatteryInfo() async throws -> BatteryMetrics? {
        let result = try await execute(
            command: "pmset -g batt | grep -E 'InternalBattery|AC Power'"
        )
        
        guard !result.output.isEmpty else { return nil }
        
        // Parse battery percentage
        var percent: Double = 0
        var isCharging = false
        var status: BatteryStatus = .unknown
        
        if let percentMatch = result.output.range(of: #"(\d+)%"#, options: .regularExpression) {
            let percentStr = String(result.output[percentMatch]).replacingOccurrences(of: "%", with: "")
            percent = Double(percentStr) ?? 0
        }
        
        if result.output.contains("charging") || result.output.contains("AC Power") {
            isCharging = true
            status = percent >= 100 ? .full : .charging
        } else {
            status = .discharging
        }
        
        // Get cycle count
        let cycleResult = try await execute(
            command: "ioreg -r -c AppleSmartBattery | grep -i cyclecount | awk '{print $NF}'"
        )
        let cycleCount = Int(cycleResult.output) ?? 0
        
        // Get max capacity
        let capacityResult = try await execute(
            command: "ioreg -r -c AppleSmartBattery | grep -i maxcapacity | awk '{print $NF}'"
        )
        let designCapacityResult = try await execute(
            command: "ioreg -r -c AppleSmartBattery | grep -i designcapacity | awk '{print $NF}'"
        )
        
        let maxCapacity = Int(capacityResult.output) ?? 100
        let designCapacity = Int(designCapacityResult.output) ?? 100
        let healthPercent = designCapacity > 0 ? (maxCapacity * 100) / designCapacity : 100
        
        return BatteryMetrics(
            percent: percent,
            status: status,
            timeRemaining: nil,
            health: healthPercent >= 80 ? "Normal" : "Service Recommended",
            cycleCount: cycleCount,
            capacity: healthPercent,
            isCharging: isCharging
        )
    }
    
    /// Get thermal info
    func getThermalInfo() async throws -> ThermalMetrics {
        // Try to get CPU temperature
        var cpuTemp: Double = 0
        
        // Try powermetrics (requires sudo, may not work)
        // Fallback to a reasonable estimate based on CPU usage
        let cpuUsage = try await getCPUUsage()
        cpuTemp = 40 + (cpuUsage * 0.5) // Rough estimate
        
        // Get fan speed if available
        let fanResult = try await execute(
            command: "ioreg -r -c AppleSMC | grep -i fanactualspeed | head -1 | awk '{print $NF}'"
        )
        let fanSpeed = Int(fanResult.output) ?? 0
        
        return ThermalMetrics(
            cpuTemp: cpuTemp,
            gpuTemp: 0,
            fanSpeed: fanSpeed,
            fanCount: fanSpeed > 0 ? 1 : 0,
            systemPower: 0
        )
    }
}
