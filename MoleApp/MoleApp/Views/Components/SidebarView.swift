//
//  SidebarView.swift
//  MoleApp
//
//  Sidebar navigation component
//

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        List(selection: $appState.selectedTab) {
            Section {
                ForEach(SidebarTab.allCases) { tab in
                    SidebarItem(tab: tab, isSelected: appState.selectedTab == tab)
                        .tag(tab)
                }
            } header: {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "ant.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.accentColor)
                    
                    Text("Mole")
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
                .padding(.vertical, DesignSystem.Spacing.sm)
            }
            
            if let metrics = appState.systemMetrics {
                Section {
                    QuickStatsView(metrics: metrics)
                } header: {
                    Text("Quick Stats")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200, idealWidth: 220, maxWidth: 260)
    }
}

// MARK: - Sidebar Item

struct SidebarItem: View {
    let tab: SidebarTab
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: tab.icon)
                .font(.system(size: 16))
                .foregroundColor(isSelected ? .accentColor : DesignSystem.Colors.secondaryText)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(tab.rawValue)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(tab.description)
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            
            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .contentShape(Rectangle())
    }
}

// MARK: - Quick Stats View

struct QuickStatsView: View {
    let metrics: SystemMetrics
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            MiniStatRow(
                icon: "cpu",
                label: "CPU",
                value: metrics.cpu.usageFormatted,
                color: colorForPercentage(metrics.cpu.usage)
            )
            
            MiniStatRow(
                icon: "memorychip",
                label: "Memory",
                value: String(format: "%.0f%%", metrics.memory.usedPercent),
                color: colorForPercentage(metrics.memory.usedPercent)
            )
            
            if let primary = metrics.disk.primaryVolume {
                MiniStatRow(
                    icon: "internaldrive",
                    label: "Disk",
                    value: String(format: "%.0f%%", primary.usedPercent),
                    color: colorForPercentage(primary.usedPercent)
                )
            }
            
            HStack {
                Circle()
                    .fill(DesignSystem.Colors.healthGradient(for: metrics.healthScore))
                    .frame(width: 8, height: 8)
                
                Text("Health: \(metrics.healthScore)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Spacer()
            }
            .padding(.top, DesignSystem.Spacing.xs)
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
    
    private func colorForPercentage(_ value: Double) -> Color {
        if value < 50 { return .green }
        if value < 75 { return .yellow }
        if value < 90 { return .orange }
        return .red
    }
}

// MARK: - Mini Stat Row

struct MiniStatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .frame(width: 14)
            
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(color)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

#Preview {
    SidebarView()
        .environmentObject(AppState())
        .frame(width: 240, height: 500)
}
