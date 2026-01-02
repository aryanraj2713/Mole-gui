//
//  ContentView.swift
//  MoleApp
//
//  Main application container with sidebar navigation
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
        } detail: {
            DetailView()
        }
        .navigationSplitViewStyle(.balanced)
        .background(DesignSystem.Colors.windowBackground)
    }
}

// MARK: - Detail View

struct DetailView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            switch appState.selectedTab {
            case .dashboard:
                DashboardView()
            case .monitor:
                MonitorView()
            case .cleanup:
                CleanupView()
            case .logs:
                LogsView()
            case .settings:
                SettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.contentBackground)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AppState())
        .frame(width: 1000, height: 700)
}
