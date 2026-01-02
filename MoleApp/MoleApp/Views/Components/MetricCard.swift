//
//  MetricCard.swift
//  MoleApp
//
//  Metric card component for displaying system metrics
//

import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let progress: Double?
    let details: [MetricDetail]?
    
    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        color: Color = .accentColor,
        progress: Double? = nil,
        details: [MetricDetail]? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.progress = progress
        self.details = details
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                
                Text(title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
            }
            
            // Value with optional progress ring
            HStack(alignment: .bottom, spacing: DesignSystem.Spacing.lg) {
                if let progress = progress {
                    ProgressRing(progress: progress, size: 48, lineWidth: 5, color: color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(DesignSystem.Typography.metricValue)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
            }
            
            // Progress bar (alternative to ring)
            if progress != nil && details == nil {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color)
                            .frame(width: geometry.size.width * CGFloat(progress! / 100))
                    }
                }
                .frame(height: 6)
            }
            
            // Details
            if let details = details {
                Divider()
                    .padding(.vertical, DesignSystem.Spacing.xs)
                
                ForEach(details) { detail in
                    HStack {
                        Text(detail.label)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Spacer()
                        
                        Text(detail.value)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
    }
}

// MARK: - Metric Detail

struct MetricDetail: Identifiable {
    let id = UUID()
    let label: String
    let value: String
}

// MARK: - Convenience Initializers

extension MetricCard {
    static func cpu(metrics: CPUMetrics) -> MetricCard {
        MetricCard(
            title: "CPU",
            value: metrics.usageFormatted,
            subtitle: "Load: \(metrics.loadAverage)",
            icon: "cpu",
            color: .blue,
            progress: metrics.usage,
            details: [
                MetricDetail(label: "Cores", value: "\(metrics.coreCount)"),
                MetricDetail(label: "Logical CPUs", value: "\(metrics.logicalCPU)")
            ]
        )
    }
    
    static func memory(metrics: MemoryMetrics) -> MetricCard {
        MetricCard(
            title: "Memory",
            value: String(format: "%.1f%%", metrics.usedPercent),
            subtitle: "\(metrics.usedFormatted) / \(metrics.totalFormatted)",
            icon: "memorychip",
            color: .purple,
            progress: metrics.usedPercent,
            details: [
                MetricDetail(label: "Available", value: metrics.availableFormatted),
                MetricDetail(label: "Pressure", value: metrics.pressure.displayName)
            ]
        )
    }
    
    static func disk(volume: VolumeInfo) -> MetricCard {
        MetricCard(
            title: volume.name,
            value: String(format: "%.1f%%", volume.usedPercent),
            subtitle: "\(volume.usedFormatted) / \(volume.totalFormatted)",
            icon: "internaldrive",
            color: .green,
            progress: volume.usedPercent,
            details: [
                MetricDetail(label: "Free", value: volume.freeFormatted),
                MetricDetail(label: "Type", value: volume.fileSystem)
            ]
        )
    }
    
    static func network(interface: NetworkInterface) -> MetricCard {
        MetricCard(
            title: "Network",
            value: String(format: "%.1f MB/s", interface.rxRate + interface.txRate),
            subtitle: interface.ipAddress,
            icon: "network",
            color: .cyan,
            details: [
                MetricDetail(label: "Download", value: String(format: "%.1f MB/s", interface.rxRate)),
                MetricDetail(label: "Upload", value: String(format: "%.1f MB/s", interface.txRate))
            ]
        )
    }
    
    static func battery(metrics: BatteryMetrics) -> MetricCard {
        MetricCard(
            title: "Battery",
            value: metrics.percentFormatted,
            subtitle: metrics.status.rawValue,
            icon: metrics.isCharging ? "battery.100.bolt" : "battery.100",
            color: metrics.percent > 20 ? .green : .red,
            progress: metrics.percent,
            details: [
                MetricDetail(label: "Health", value: metrics.health),
                MetricDetail(label: "Cycle Count", value: "\(metrics.cycleCount)")
            ]
        )
    }
    
    static func thermal(metrics: ThermalMetrics) -> MetricCard {
        MetricCard(
            title: "Thermal",
            value: metrics.cpuTempFormatted,
            subtitle: metrics.fanSpeedFormatted,
            icon: "thermometer",
            color: metrics.cpuTemp > 70 ? .orange : .teal,
            details: metrics.fanCount > 0 ? [
                MetricDetail(label: "Fan Speed", value: metrics.fanSpeedFormatted)
            ] : nil
        )
    }
}

// MARK: - Preview

#Preview {
    HStack {
        MetricCard.cpu(metrics: SystemMonitorService.mockMetrics.cpu)
        MetricCard.memory(metrics: SystemMonitorService.mockMetrics.memory)
    }
    .padding()
    .frame(width: 600)
}
