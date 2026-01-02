//
//  MoleAppApp.swift
//  MoleApp
//
//  Native macOS resource manager application
//  Wraps the Mole CLI tool with a beautiful SwiftUI interface
//

import SwiftUI

@main
struct MoleAppApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    appState.checkForUpdates()
                }
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

// MARK: - App State

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: SidebarTab = .dashboard
    @Published var isLoading = false
    @Published var systemMetrics: SystemMetrics?
    @Published var logs: [LogEntry] = []
    
    private let systemMonitor = SystemMonitorService.shared
    private let cliService = CLIService.shared
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        Task {
            await systemMonitor.startMonitoring { [weak self] metrics in
                DispatchQueue.main.async {
                    self?.systemMetrics = metrics
                }
            }
        }
    }
    
    func stopMonitoring() {
        systemMonitor.stopMonitoring()
    }
    
    func addLog(_ entry: LogEntry) {
        logs.insert(entry, at: 0)
        if logs.count > 1000 {
            logs.removeLast()
        }
    }
    
    func checkForUpdates() {
        addLog(LogEntry(message: "Checking for updates...", type: .info))
    }
}

// MARK: - Sidebar Tab

enum SidebarTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case monitor = "Monitor"
    case cleanup = "Cleanup"
    case logs = "Logs"
    case settings = "Settings"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.bottom.50percent"
        case .monitor: return "chart.line.uptrend.xyaxis"
        case .cleanup: return "trash"
        case .logs: return "doc.text"
        case .settings: return "gear"
        }
    }
    
    var description: String {
        switch self {
        case .dashboard: return "System overview"
        case .monitor: return "Live metrics"
        case .cleanup: return "Free up space"
        case .logs: return "Activity log"
        case .settings: return "Preferences"
        }
    }
}
