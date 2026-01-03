//
//  CleanupModels.swift
//  MoleApp
//
//  Data models for cleanup operations
//

import Foundation

// MARK: - Cleanup Category

struct CleanupCategory: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let items: [CleanupItem]
    var isSelected: Bool
    var isExpanded: Bool
    
    var totalSize: UInt64 {
        items.filter(\.isSelected).reduce(0) { $0 + $1.size }
    }
    
    var totalSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file)
    }
    
    var selectedCount: Int {
        items.filter(\.isSelected).count
    }
    
    static func == (lhs: CleanupCategory, rhs: CleanupCategory) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Cleanup Item

struct CleanupItem: Identifiable, Equatable {
    let id: String
    let name: String
    let path: String
    let size: UInt64
    let type: CleanupItemType
    let lastAccessed: Date?
    var isSelected: Bool
    let isProtected: Bool
    
    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
    
    var lastAccessedFormatted: String? {
        guard let date = lastAccessed else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    static func == (lhs: CleanupItem, rhs: CleanupItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum CleanupItemType: String {
    case cache = "Cache"
    case log = "Log"
    case temp = "Temporary"
    case trash = "Trash"
    case browser = "Browser"
    case developer = "Developer"
    case appData = "App Data"
    case system = "System"
}

// MARK: - Cleanup State

enum CleanupState: Equatable {
    case idle
    case scanning
    case ready(totalSize: UInt64)
    case confirming
    case cleaning(progress: Double, currentItem: String)
    case completed(freedSpace: UInt64, itemsCleaned: Int)
    case failed(error: String)
    
    var isProcessing: Bool {
        switch self {
        case .scanning, .cleaning:
            return true
        default:
            return false
        }
    }
}

// MARK: - Cleanup Result

struct CleanupResult {
    let success: Bool
    let freedSpace: UInt64
    let itemsCleaned: Int
    let errors: [CleanupError]
    let duration: TimeInterval
    
    var freedSpaceFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(freedSpace), countStyle: .file)
    }
}

struct CleanupError: Identifiable {
    let id = UUID()
    let path: String
    let message: String
    let isRecoverable: Bool
}

// MARK: - Cleanup Configuration

struct CleanupConfiguration {
    var includeSystemCaches: Bool = false
    var includeUserCaches: Bool = true
    var includeBrowserData: Bool = true
    var includeDeveloperTools: Bool = true
    var includeTrash: Bool = true
    var includeLogs: Bool = true
    var includeTempFiles: Bool = true
    var requiresAdminAccess: Bool = false
    var dryRun: Bool = false
}

// MARK: - Default Categories

extension CleanupCategory {
    static let defaultCategories: [CleanupCategory] = [
        CleanupCategory(
            id: "user_cache",
            name: "User App Cache",
            description: "Application caches stored in your Library folder",
            icon: "folder.badge.gearshape",
            items: [],
            isSelected: true,
            isExpanded: false
        ),
        CleanupCategory(
            id: "browser_cache",
            name: "Browser Cache",
            description: "Safari, Chrome, Firefox, and other browser caches",
            icon: "globe",
            items: [],
            isSelected: true,
            isExpanded: false
        ),
        CleanupCategory(
            id: "developer_tools",
            name: "Developer Tools",
            description: "Xcode, npm, pip, and other development caches",
            icon: "hammer",
            items: [],
            isSelected: true,
            isExpanded: false
        ),
        CleanupCategory(
            id: "system_logs",
            name: "System Logs",
            description: "Log files and diagnostic reports",
            icon: "doc.text",
            items: [],
            isSelected: true,
            isExpanded: false
        ),
        CleanupCategory(
            id: "temp_files",
            name: "Temporary Files",
            description: "System and application temporary files",
            icon: "clock.arrow.circlepath",
            items: [],
            isSelected: true,
            isExpanded: false
        ),
        CleanupCategory(
            id: "trash",
            name: "Trash",
            description: "Items in your Trash that can be permanently deleted",
            icon: "trash",
            items: [],
            isSelected: false,
            isExpanded: false
        )
    ]
}

// MARK: - Whitelist Item

struct WhitelistItem: Identifiable, Codable {
    let id: UUID
    let path: String
    let name: String
    let addedDate: Date
    
    init(path: String, name: String) {
        self.id = UUID()
        self.path = path
        self.name = name
        self.addedDate = Date()
    }
}

// MARK: - Cleanup History Entry

struct CleanupHistoryEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let freedSpace: UInt64
    let itemsCleaned: Int
    let categories: [String]
    let duration: TimeInterval
    
    init(freedSpace: UInt64, itemsCleaned: Int, categories: [String], duration: TimeInterval) {
        self.id = UUID()
        self.date = Date()
        self.freedSpace = freedSpace
        self.itemsCleaned = itemsCleaned
        self.categories = categories
        self.duration = duration
    }
    
    var freedSpaceFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(freedSpace), countStyle: .file)
    }
    
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
