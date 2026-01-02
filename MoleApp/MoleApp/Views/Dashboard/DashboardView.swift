//
//  DashboardView.swift
//  MoleApp
//
//  Dashboard view showing system health overview
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Header
                headerSection
                
                // Health Score Section
                healthScoreSection
                
                // Quick Stats Grid
                quickStatsSection
                
                // Quick Actions
                quickActionsSection
                
                // Recent Activity
                recentActivitySection
            }
            .padding(DesignSystem.Spacing.xl)
        }
        .onAppear {
            viewModel.startMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Dashboard")
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(viewModel.metrics.hardware.model)
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await viewModel.refresh()
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16))
            }
            .buttonStyle(.glass)
            .disabled(viewModel.isLoading)
        }
    }
    
    // MARK: - Health Score Section
    
    private var healthScoreSection: some View {
        HStack(spacing: DesignSystem.Spacing.xl) {
            // Health Score Ring
            GlassCard {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    HealthScoreRing(score: viewModel.metrics.healthScore, size: 120, lineWidth: 12)
                    
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Text(viewModel.metrics.healthMessage)
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text("System Health Score")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            // System Info
            GlassCard {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("System Information")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Divider()
                    
                    SystemInfoRow(label: "Model", value: viewModel.metrics.hardware.model)
                    SystemInfoRow(label: "CPU", value: viewModel.metrics.hardware.cpuModel)
                    SystemInfoRow(label: "Memory", value: viewModel.metrics.hardware.totalRAM)
                    SystemInfoRow(label: "Storage", value: viewModel.metrics.hardware.diskSize)
                    SystemInfoRow(label: "OS", value: viewModel.metrics.hardware.osVersion)
                }
            }
        }
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("System Overview")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: DesignSystem.Spacing.md) {
                MiniMetricCard(
                    title: "CPU",
                    value: viewModel.metrics.cpu.usageFormatted,
                    icon: "cpu",
                    progress: viewModel.metrics.cpu.usage,
                    color: .blue
                )
                
                MiniMetricCard(
                    title: "Memory",
                    value: String(format: "%.0f%%", viewModel.metrics.memory.usedPercent),
                    icon: "memorychip",
                    progress: viewModel.metrics.memory.usedPercent,
                    color: .purple
                )
                
                if let disk = viewModel.metrics.disk.primaryVolume {
                    MiniMetricCard(
                        title: "Disk",
                        value: String(format: "%.0f%%", disk.usedPercent),
                        icon: "internaldrive",
                        progress: disk.usedPercent,
                        color: .green
                    )
                }
                
                if let battery = viewModel.metrics.battery {
                    MiniMetricCard(
                        title: "Battery",
                        value: battery.percentFormatted,
                        icon: battery.isCharging ? "battery.100.bolt" : "battery.100",
                        progress: battery.percent,
                        color: battery.percent > 20 ? .green : .red
                    )
                } else {
                    MiniMetricCard(
                        title: "Thermal",
                        value: viewModel.metrics.thermal.cpuTempFormatted,
                        icon: "thermometer",
                        progress: min(viewModel.metrics.thermal.cpuTemp, 100),
                        color: .teal
                    )
                }
            }
        }
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Quick Actions")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: DesignSystem.Spacing.md) {
                ForEach(viewModel.quickActions) { action in
                    ActionCard(
                        title: action.name,
                        description: action.description,
                        icon: action.icon,
                        action: {
                            handleQuickAction(action.action)
                        },
                        color: colorForAction(action.action)
                    )
                }
            }
        }
    }
    
    // MARK: - Recent Activity Section
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("Recent Cleanups")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                Button("View All") {
                    appState.selectedTab = .logs
                }
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.accentColor)
            }
            
            if viewModel.recentCleanups.isEmpty {
                GlassCard {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                        Text("No recent cleanups")
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        Spacer()
                    }
                }
            } else {
                ForEach(viewModel.recentCleanups) { entry in
                    GlassCard(padding: DesignSystem.Spacing.md) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Cleanup completed")
                                    .font(DesignSystem.Typography.headline)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                
                                Text("\(entry.freedSpaceFormatted) freed • \(entry.itemsCleaned) items")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                            
                            Spacer()
                            
                            Text(entry.date.relativeFormatted)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func handleQuickAction(_ action: QuickAction.ActionType) {
        switch action {
        case .cleanup:
            appState.selectedTab = .cleanup
        case .monitor:
            appState.selectedTab = .monitor
        case .optimize:
            appState.selectedTab = .cleanup
        case .analyze:
            appState.selectedTab = .monitor
        }
    }
    
    private func colorForAction(_ action: QuickAction.ActionType) -> Color {
        switch action {
        case .cleanup: return .red
        case .monitor: return .blue
        case .optimize: return .orange
        case .analyze: return .purple
        }
    }
}

// MARK: - Supporting Views

struct SystemInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .fontWeight(.medium)
                .lineLimit(1)
        }
    }
}

struct MiniMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let progress: Double
    let color: Color
    
    var body: some View {
        GlassCard(padding: DesignSystem.Spacing.md) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Spacer()
                }
                
                HStack {
                    Text(value)
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    ProgressRing(progress: progress, size: 32, lineWidth: 4, color: color, showLabel: false)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environmentObject(AppState())
        .frame(width: 800, height: 700)
}
