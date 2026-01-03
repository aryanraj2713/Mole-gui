//
//  LogsViewModel.swift
//  MoleApp
//
//  ViewModel for the Logs view
//

import Foundation
import Combine
import AppKit

@MainActor
final class LogsViewModel: ObservableObject {
    @Published var logs: [LogEntry] = []
    @Published var filteredLogs: [LogEntry] = []
    @Published var searchText = ""
    @Published var selectedFilter: LogFilter = .all
    @Published var isAutoScrollEnabled = true
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        addSampleLogs()
    }
    
    private func setupBindings() {
        // Combine search text and filter changes
        Publishers.CombineLatest($searchText, $selectedFilter)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] searchText, filter in
                self?.applyFilters(searchText: searchText, filter: filter)
            }
            .store(in: &cancellables)
    }
    
    private func applyFilters(searchText: String, filter: LogFilter) {
        var result = logs
        
        // Apply type filter
        if filter != .all {
            result = result.filter { $0.type == filter.logType }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter {
                $0.message.localizedCaseInsensitiveContains(searchText) ||
                $0.source.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        filteredLogs = result
    }
    
    func addLog(_ entry: LogEntry) {
        logs.insert(entry, at: 0)
        if logs.count > 10000 {
            logs.removeLast()
        }
        applyFilters(searchText: searchText, filter: selectedFilter)
    }
    
    func clearLogs() {
        logs.removeAll()
        filteredLogs.removeAll()
    }
    
    func exportLogs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "mole_logs_\(formattedDate()).txt"
        
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            
            let content = self?.logs.map { entry in
                "[\(entry.formattedTimestamp)] [\(entry.type.rawValue)] [\(entry.source)] \(entry.message)"
            }.joined(separator: "\n") ?? ""
            
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    func copyToClipboard(_ entry: LogEntry) {
        let content = "[\(entry.formattedTimestamp)] [\(entry.type.rawValue)] \(entry.message)"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
    }
    
    func copyAllToClipboard() {
        let content = filteredLogs.map { entry in
            "[\(entry.formattedTimestamp)] [\(entry.type.rawValue)] [\(entry.source)] \(entry.message)"
        }.joined(separator: "\n")
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: Date())
    }
    
    private func addSampleLogs() {
        // Add sample logs for demonstration
        let sampleLogs: [(String, LogType, String)] = [
            ("Application started", .info, "System"),
            ("System monitoring initialized", .success, "Monitor"),
            ("Connected to system services", .info, "CLI"),
            ("Loaded user preferences", .info, "Settings"),
            ("Ready for cleanup operations", .success, "Cleanup")
        ]
        
        for (message, type, source) in sampleLogs.reversed() {
            logs.append(LogEntry(message: message, type: type, source: source))
        }
        
        applyFilters(searchText: searchText, filter: selectedFilter)
    }
}

// MARK: - Log Filter

enum LogFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case info = "Info"
    case success = "Success"
    case warning = "Warning"
    case error = "Error"
    case debug = "Debug"
    
    var id: String { rawValue }
    
    var logType: LogType? {
        switch self {
        case .all: return nil
        case .info: return .info
        case .success: return .success
        case .warning: return .warning
        case .error: return .error
        case .debug: return .debug
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .info: return "info.circle"
        case .success: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .debug: return "ant"
        }
    }
}

// MARK: - Log Entry Extensions

extension LogType {
    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .debug: return "ant.fill"
        }
    }
    
    var colorName: String {
        switch self {
        case .info: return "blue"
        case .success: return "green"
        case .warning: return "yellow"
        case .error: return "red"
        case .debug: return "gray"
        }
    }
}
