//
//  MonitorView.swift
//  MoleApp
//
//  Real-time system monitoring view
//

import SwiftUI

struct MonitorView: View {
    @StateObject private var viewModel = MonitorViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Header
                headerSection
                
                // Metric Type Picker
                metricPickerSection
                
                // Live Chart
                liveChartSection
                
                // Detailed Metrics Grid
                metricsGridSection
                
                // Top Processes
                processesSection
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
                Text("Monitor")
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Real-time system metrics")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            HStack(spacing: DesignSystem.Spacing.md) {
                // Monitoring status indicator
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Circle()
                        .fill(viewModel.isMonitoring ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    
                    Text(viewModel.isMonitoring ? "Live" : "Paused")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                // Toggle monitoring button
                Button(action: {
                    viewModel.toggleMonitoring()
                }) {
                    Image(systemName: viewModel.isMonitoring ? "pause.fill" : "play.fill")
                        .font(.system(size: 14))
                }
                .buttonStyle(.glass)
            }
        }
    }
    
    // MARK: - Metric Type Picker
    
    private var metricPickerSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(MetricType.allCases) { type in
                    MetricTypeButton(
                        type: type,
                        isSelected: viewModel.selectedMetricType == type
                    ) {
                        viewModel.selectedMetricType = type
                    }
                }
            }
        }
    }
    
    // MARK: - Live Chart Section
    
    private var liveChartSection: some View {
        LiveChart(
            data: viewModel.currentChartData,
            title: viewModel.chartTitle,
            unit: viewModel.chartUnit,
            color: Color(hex: viewModel.chartColor),
            height: 250
        )
    }
    
    // MARK: - Metrics Grid Section
    
    private var metricsGridSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Detailed Metrics")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: DesignSystem.Spacing.md) {
                MetricCard.cpu(metrics: viewModel.metrics.cpu)
                MetricCard.memory(metrics: viewModel.metrics.memory)
                
                if let primary = viewModel.metrics.disk.primaryVolume {
                    MetricCard.disk(volume: primary)
                }
                
                if let network = viewModel.metrics.network.primaryInterface {
                    MetricCard.network(interface: network)
                }
                
                if let battery = viewModel.metrics.battery {
                    MetricCard.battery(metrics: battery)
                }
                
                MetricCard.thermal(metrics: viewModel.metrics.thermal)
            }
        }
    }
    
    // MARK: - Processes Section
    
    private var processesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Top Processes")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            GlassCard {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Process")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("CPU")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .frame(width: 80, alignment: .trailing)
                        
                        Text("Memory")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .frame(width: 80, alignment: .trailing)
                    }
                    .padding(.bottom, DesignSystem.Spacing.sm)
                    
                    Divider()
                    
                    // Processes list
                    ForEach(viewModel.metrics.topProcesses) { process in
                        ProcessRow(process: process)
                    }
                    
                    if viewModel.metrics.topProcesses.isEmpty {
                        Text("No processes to display")
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                            .padding(.vertical, DesignSystem.Spacing.lg)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct MetricTypeButton: View {
    let type: MetricType
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: type.icon)
                    .font(.system(size: 12))
                
                Text(type.displayName)
                    .font(DesignSystem.Typography.caption)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .foregroundColor(isSelected ? .white : DesignSystem.Colors.primaryText)
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.05 : 1)
        .animation(DesignSystem.Animation.quick, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct ProcessRow: View {
    let process: ProcessInfo
    
    var body: some View {
        HStack {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "app.fill")
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                
                Text(process.name)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(process.cpuFormatted)
                .font(DesignSystem.Typography.monospace)
                .foregroundColor(colorForCPU(process.cpuUsage))
                .frame(width: 80, alignment: .trailing)
            
            Text(process.memoryFormatted)
                .font(DesignSystem.Typography.monospace)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
    
    private func colorForCPU(_ usage: Double) -> Color {
        if usage > 50 { return .red }
        if usage > 25 { return .orange }
        if usage > 10 { return .yellow }
        return DesignSystem.Colors.primaryText
    }
}

// MARK: - Preview

#Preview {
    MonitorView()
        .environmentObject(AppState())
        .frame(width: 800, height: 700)
}
