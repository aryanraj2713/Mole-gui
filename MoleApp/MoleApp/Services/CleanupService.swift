//
//  CleanupService.swift
//  MoleApp
//
//  Service for cleanup operations
//

import Foundation

// MARK: - Cleanup Service

@MainActor
final class CleanupService: ObservableObject {
    static let shared = CleanupService()
    
    @Published private(set) var state: CleanupState = .idle
    @Published private(set) var categories: [CleanupCategory] = []
    @Published private(set) var lastResult: CleanupResult?
    @Published private(set) var history: [CleanupHistoryEntry] = []
    @Published var whitelist: [WhitelistItem] = []
    
    private let cliService = CLIService.shared
    private let fileManager = FileManager.default
    
    private init() {
        loadWhitelist()
        loadHistory()
    }
    
    // MARK: - Scanning
    
    func scan() async {
        state = .scanning
        
        do {
            var scannedCategories = CleanupCategory.defaultCategories
            
            // Scan each category
            for i in scannedCategories.indices {
                let items = try await scanCategory(scannedCategories[i])
                scannedCategories[i] = CleanupCategory(
                    id: scannedCategories[i].id,
                    name: scannedCategories[i].name,
                    description: scannedCategories[i].description,
                    icon: scannedCategories[i].icon,
                    items: items,
                    isSelected: scannedCategories[i].isSelected && !items.isEmpty,
                    isExpanded: scannedCategories[i].isExpanded
                )
            }
            
            categories = scannedCategories
            
            let totalSize = scannedCategories
                .filter(\.isSelected)
                .reduce(0) { $0 + $1.totalSize }
            
            state = .ready(totalSize: totalSize)
        } catch {
            state = .failed(error: error.localizedDescription)
        }
    }
    
    private func scanCategory(_ category: CleanupCategory) async throws -> [CleanupItem] {
        switch category.id {
        case "user_cache":
            return try await scanUserCaches()
        case "browser_cache":
            return try await scanBrowserCaches()
        case "developer_tools":
            return try await scanDeveloperCaches()
        case "system_logs":
            return try await scanLogs()
        case "temp_files":
            return try await scanTempFiles()
        case "trash":
            return try await scanTrash()
        default:
            return []
        }
    }
    
    // MARK: - Category Scanners
    
    private func scanUserCaches() async throws -> [CleanupItem] {
        let cachePath = NSHomeDirectory() + "/Library/Caches"
        return try await scanDirectory(cachePath, type: .cache)
    }
    
    private func scanBrowserCaches() async throws -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        let browserPaths: [(name: String, paths: [String])] = [
            ("Safari", [
                "~/Library/Caches/com.apple.Safari",
                "~/Library/Safari/LocalStorage"
            ]),
            ("Chrome", [
                "~/Library/Caches/Google/Chrome",
                "~/Library/Application Support/Google/Chrome/Default/Cache"
            ]),
            ("Firefox", [
                "~/Library/Caches/Firefox"
            ]),
            ("Edge", [
                "~/Library/Caches/Microsoft Edge"
            ]),
            ("Arc", [
                "~/Library/Caches/company.thebrowser.Browser"
            ])
        ]
        
        for browser in browserPaths {
            for pathTemplate in browser.paths {
                let path = pathTemplate.replacingOccurrences(of: "~", with: NSHomeDirectory())
                if fileManager.fileExists(atPath: path) {
                    let size = try await getDirectorySize(path)
                    if size > 1_000_000 { // > 1MB
                        items.append(CleanupItem(
                            id: UUID().uuidString,
                            name: browser.name,
                            path: path,
                            size: size,
                            type: .browser,
                            lastAccessed: getLastAccessed(path),
                            isSelected: true,
                            isProtected: isWhitelisted(path)
                        ))
                    }
                }
            }
        }
        
        return items
    }
    
    private func scanDeveloperCaches() async throws -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        let devPaths: [(name: String, path: String)] = [
            ("Xcode Derived Data", "~/Library/Developer/Xcode/DerivedData"),
            ("Xcode Archives", "~/Library/Developer/Xcode/Archives"),
            ("Xcode Device Support", "~/Library/Developer/Xcode/iOS DeviceSupport"),
            ("CocoaPods", "~/Library/Caches/CocoaPods"),
            ("npm Cache", "~/.npm/_cacache"),
            ("Yarn Cache", "~/Library/Caches/Yarn"),
            ("pip Cache", "~/Library/Caches/pip"),
            ("Homebrew Cache", "~/Library/Caches/Homebrew"),
            ("Gradle Cache", "~/.gradle/caches"),
            ("Maven Cache", "~/.m2/repository"),
            ("Cargo Cache", "~/.cargo/registry")
        ]
        
        for dev in devPaths {
            let path = dev.path.replacingOccurrences(of: "~", with: NSHomeDirectory())
            if fileManager.fileExists(atPath: path) {
                let size = try await getDirectorySize(path)
                if size > 10_000_000 { // > 10MB
                    items.append(CleanupItem(
                        id: UUID().uuidString,
                        name: dev.name,
                        path: path,
                        size: size,
                        type: .developer,
                        lastAccessed: getLastAccessed(path),
                        isSelected: true,
                        isProtected: isWhitelisted(path)
                    ))
                }
            }
        }
        
        return items
    }
    
    private func scanLogs() async throws -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        let logPaths: [(name: String, path: String)] = [
            ("System Logs", "~/Library/Logs"),
            ("Diagnostic Reports", "~/Library/Logs/DiagnosticReports"),
            ("Crash Reports", "~/Library/Logs/CrashReporter")
        ]
        
        for log in logPaths {
            let path = log.path.replacingOccurrences(of: "~", with: NSHomeDirectory())
            if fileManager.fileExists(atPath: path) {
                let size = try await getDirectorySize(path)
                if size > 1_000_000 { // > 1MB
                    items.append(CleanupItem(
                        id: UUID().uuidString,
                        name: log.name,
                        path: path,
                        size: size,
                        type: .log,
                        lastAccessed: getLastAccessed(path),
                        isSelected: true,
                        isProtected: isWhitelisted(path)
                    ))
                }
            }
        }
        
        return items
    }
    
    private func scanTempFiles() async throws -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        let tempPaths: [(name: String, path: String)] = [
            ("User Temp", NSTemporaryDirectory()),
            ("System Temp", "/private/var/tmp"),
            ("Downloaded Items", "~/Library/Application Support/CrashReporter/DiagnosticReports")
        ]
        
        for temp in tempPaths {
            let path = temp.path.replacingOccurrences(of: "~", with: NSHomeDirectory())
            if fileManager.fileExists(atPath: path) {
                let size = try await getDirectorySize(path)
                if size > 1_000_000 { // > 1MB
                    items.append(CleanupItem(
                        id: UUID().uuidString,
                        name: temp.name,
                        path: path,
                        size: size,
                        type: .temp,
                        lastAccessed: getLastAccessed(path),
                        isSelected: true,
                        isProtected: isWhitelisted(path)
                    ))
                }
            }
        }
        
        return items
    }
    
    private func scanTrash() async throws -> [CleanupItem] {
        let trashPath = NSHomeDirectory() + "/.Trash"
        
        guard fileManager.fileExists(atPath: trashPath) else { return [] }
        
        let size = try await getDirectorySize(trashPath)
        
        if size > 0 {
            return [CleanupItem(
                id: "trash",
                name: "Trash",
                path: trashPath,
                size: size,
                type: .trash,
                lastAccessed: nil,
                isSelected: false, // Don't auto-select trash
                isProtected: false
            )]
        }
        
        return []
    }
    
    private func scanDirectory(_ path: String, type: CleanupItemType) async throws -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        guard fileManager.fileExists(atPath: path) else { return [] }
        
        let contents = try fileManager.contentsOfDirectory(atPath: path)
        
        for item in contents.prefix(50) { // Limit to prevent slow scans
            let itemPath = (path as NSString).appendingPathComponent(item)
            let size = try await getDirectorySize(itemPath)
            
            if size > 5_000_000 { // > 5MB
                items.append(CleanupItem(
                    id: UUID().uuidString,
                    name: item,
                    path: itemPath,
                    size: size,
                    type: type,
                    lastAccessed: getLastAccessed(itemPath),
                    isSelected: !isWhitelisted(itemPath),
                    isProtected: isWhitelisted(itemPath)
                ))
            }
        }
        
        return items.sorted { $0.size > $1.size }
    }
    
    // MARK: - Cleanup Execution
    
    func performCleanup(dryRun: Bool = false) async {
        state = .confirming
        
        let startTime = Date()
        var totalFreed: UInt64 = 0
        var itemsCleaned = 0
        var errors: [CleanupError] = []
        var cleanedCategories: [String] = []
        
        let selectedCategories = categories.filter(\.isSelected)
        let totalItems = selectedCategories.reduce(0) { $0 + $1.items.filter(\.isSelected).count }
        var processedItems = 0
        
        for category in selectedCategories {
            let selectedItems = category.items.filter { $0.isSelected && !$0.isProtected }
            
            for item in selectedItems {
                state = .cleaning(
                    progress: Double(processedItems) / Double(max(1, totalItems)),
                    currentItem: item.name
                )
                
                if dryRun {
                    totalFreed += item.size
                    itemsCleaned += 1
                } else {
                    do {
                        // Use mole CLI if available, otherwise direct deletion
                        if item.type == .trash {
                            try await emptyTrash()
                        } else {
                            try await deleteItem(at: item.path)
                        }
                        totalFreed += item.size
                        itemsCleaned += 1
                    } catch {
                        errors.append(CleanupError(
                            path: item.path,
                            message: error.localizedDescription,
                            isRecoverable: true
                        ))
                    }
                }
                
                processedItems += 1
                
                // Small delay for UI smoothness
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
            
            if !selectedItems.isEmpty {
                cleanedCategories.append(category.name)
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        let result = CleanupResult(
            success: errors.isEmpty,
            freedSpace: totalFreed,
            itemsCleaned: itemsCleaned,
            errors: errors,
            duration: duration
        )
        
        lastResult = result
        
        // Save to history
        if !dryRun && itemsCleaned > 0 {
            let entry = CleanupHistoryEntry(
                freedSpace: totalFreed,
                itemsCleaned: itemsCleaned,
                categories: cleanedCategories,
                duration: duration
            )
            history.insert(entry, at: 0)
            saveHistory()
        }
        
        state = .completed(freedSpace: totalFreed, itemsCleaned: itemsCleaned)
    }
    
    private func deleteItem(at path: String) async throws {
        // First try using mole CLI for safer deletion
        if let _ = await cliService.findMolePath() {
            // Use mole's safe deletion mechanism
            let result = try await cliService.execute(
                command: "rm -rf '\(path)'"
            )
            if !result.success {
                throw CleanupError(path: path, message: result.errorOutput, isRecoverable: true)
            }
        } else {
            // Direct deletion
            try fileManager.removeItem(atPath: path)
        }
    }
    
    private func emptyTrash() async throws {
        let result = try await cliService.execute(
            command: "rm -rf ~/.Trash/*"
        )
        if !result.success {
            throw CLIError.executionFailed(result.errorOutput)
        }
    }
    
    // MARK: - Selection Management
    
    func toggleCategory(_ categoryId: String) {
        guard let index = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        categories[index].isSelected.toggle()
        
        // Update items selection
        for i in categories[index].items.indices {
            if !categories[index].items[i].isProtected {
                categories[index].items[i].isSelected = categories[index].isSelected
            }
        }
        
        updateState()
    }
    
    func toggleItem(categoryId: String, itemId: String) {
        guard let categoryIndex = categories.firstIndex(where: { $0.id == categoryId }),
              let itemIndex = categories[categoryIndex].items.firstIndex(where: { $0.id == itemId }) else { return }
        
        if !categories[categoryIndex].items[itemIndex].isProtected {
            categories[categoryIndex].items[itemIndex].isSelected.toggle()
        }
        
        updateState()
    }
    
    func selectAll() {
        for i in categories.indices {
            categories[i].isSelected = true
            for j in categories[i].items.indices {
                if !categories[i].items[j].isProtected {
                    categories[i].items[j].isSelected = true
                }
            }
        }
        updateState()
    }
    
    func deselectAll() {
        for i in categories.indices {
            categories[i].isSelected = false
            for j in categories[i].items.indices {
                categories[i].items[j].isSelected = false
            }
        }
        updateState()
    }
    
    private func updateState() {
        let totalSize = categories
            .flatMap(\.items)
            .filter(\.isSelected)
            .reduce(0) { $0 + $1.size }
        
        state = .ready(totalSize: totalSize)
    }
    
    // MARK: - Whitelist Management
    
    func addToWhitelist(_ path: String, name: String) {
        let item = WhitelistItem(path: path, name: name)
        whitelist.append(item)
        saveWhitelist()
    }
    
    func removeFromWhitelist(_ id: UUID) {
        whitelist.removeAll { $0.id == id }
        saveWhitelist()
    }
    
    func isWhitelisted(_ path: String) -> Bool {
        whitelist.contains { path.hasPrefix($0.path) }
    }
    
    private func loadWhitelist() {
        let path = getWhitelistPath()
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let items = try? JSONDecoder().decode([WhitelistItem].self, from: data) else { return }
        whitelist = items
    }
    
    private func saveWhitelist() {
        let path = getWhitelistPath()
        guard let data = try? JSONEncoder().encode(whitelist) else { return }
        try? data.write(to: URL(fileURLWithPath: path))
    }
    
    private func getWhitelistPath() -> String {
        let configDir = NSHomeDirectory() + "/.config/mole"
        try? fileManager.createDirectory(atPath: configDir, withIntermediateDirectories: true)
        return configDir + "/whitelist.json"
    }
    
    // MARK: - History Management
    
    private func loadHistory() {
        let path = getHistoryPath()
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let entries = try? JSONDecoder().decode([CleanupHistoryEntry].self, from: data) else { return }
        history = entries
    }
    
    private func saveHistory() {
        let path = getHistoryPath()
        // Keep only last 50 entries
        let trimmedHistory = Array(history.prefix(50))
        guard let data = try? JSONEncoder().encode(trimmedHistory) else { return }
        try? data.write(to: URL(fileURLWithPath: path))
    }
    
    private func getHistoryPath() -> String {
        let configDir = NSHomeDirectory() + "/.config/mole"
        try? fileManager.createDirectory(atPath: configDir, withIntermediateDirectories: true)
        return configDir + "/cleanup_history.json"
    }
    
    // MARK: - Helpers
    
    private func getDirectorySize(_ path: String) async throws -> UInt64 {
        let result = try await cliService.execute(
            command: "du -sk '\(path)' 2>/dev/null | awk '{print $1}'"
        )
        let sizeKB = UInt64(result.output) ?? 0
        return sizeKB * 1024
    }
    
    private func getLastAccessed(_ path: String) -> Date? {
        guard let attrs = try? fileManager.attributesOfItem(atPath: path),
              let date = attrs[.modificationDate] as? Date else { return nil }
        return date
    }
    
    func reset() {
        state = .idle
        categories = []
        lastResult = nil
    }
}

// MARK: - Extensions

extension CleanupService {
    var totalSelectedSize: UInt64 {
        categories
            .flatMap(\.items)
            .filter(\.isSelected)
            .reduce(0) { $0 + $1.size }
    }
    
    var totalSelectedSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalSelectedSize), countStyle: .file)
    }
    
    var selectedItemCount: Int {
        categories
            .flatMap(\.items)
            .filter(\.isSelected)
            .count
    }
}
