//
//  GlassCard.swift
//  MoleApp
//
//  Glass morphism card components following Apple's Liquid Glass design
//

import SwiftUI

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = DesignSystem.Spacing.lg
    var cornerRadius: CGFloat = DesignSystem.CornerRadius.large
    
    init(
        padding: CGFloat = DesignSystem.Spacing.lg,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.large,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    var subtitle: String? = nil
    var color: Color = .accentColor
    
    var body: some View {
        GlassCard {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text(value)
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Action Card

struct ActionCard: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void
    var color: Color = .accentColor
    var isLoading: Bool = false
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            GlassCard {
                HStack(spacing: DesignSystem.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: icon)
                                .font(.system(size: 18))
                                .foregroundColor(color)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text(description)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.02 : 1)
        .animation(DesignSystem.Animation.quick, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Status Card

struct StatusCard: View {
    let title: String
    let status: Status
    let message: String?
    
    enum Status {
        case success
        case warning
        case error
        case info
        case loading
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            case .loading: return "circle.dotted"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            case .info: return .blue
            case .loading: return .gray
            }
        }
    }
    
    var body: some View {
        GlassCard {
            HStack(spacing: DesignSystem.Spacing.md) {
                if status == .loading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 20)
                } else {
                    Image(systemName: status.icon)
                        .font(.system(size: 20))
                        .foregroundColor(status.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    if let message = message {
                        Text(message)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Stat Card Grid

struct StatCardGrid: View {
    let stats: [StatItem]
    var columns: Int = 2
    
    struct StatItem: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let icon: String
        let color: Color
        var trend: Trend? = nil
        
        enum Trend {
            case up, down, stable
            
            var icon: String {
                switch self {
                case .up: return "arrow.up.right"
                case .down: return "arrow.down.right"
                case .stable: return "arrow.right"
                }
            }
            
            var color: Color {
                switch self {
                case .up: return .green
                case .down: return .red
                case .stable: return .gray
                }
            }
        }
    }
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.md), count: columns)
    }
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: DesignSystem.Spacing.md) {
            ForEach(stats) { stat in
                GlassCard(padding: DesignSystem.Spacing.md) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Image(systemName: stat.icon)
                                .font(.system(size: 14))
                                .foregroundColor(stat.color)
                            
                            Text(stat.title)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Spacer()
                            
                            if let trend = stat.trend {
                                Image(systemName: trend.icon)
                                    .font(.system(size: 10))
                                    .foregroundColor(trend.color)
                            }
                        }
                        
                        Text(stat.value)
                            .font(DesignSystem.Typography.title3)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Info Card") {
    VStack {
        InfoCard(
            title: "CPU Temperature",
            value: "52°C",
            icon: "thermometer",
            subtitle: "Normal",
            color: .teal
        )
        
        InfoCard(
            title: "Memory Used",
            value: "12.5 GB",
            icon: "memorychip",
            subtitle: "75% of 16 GB",
            color: .purple
        )
    }
    .padding()
    .frame(width: 300)
}

#Preview("Action Card") {
    VStack {
        ActionCard(
            title: "Quick Clean",
            description: "Remove caches and temp files",
            icon: "trash.slash",
            action: {},
            color: .red
        )
        
        ActionCard(
            title: "Analyze Disk",
            description: "Visualize disk usage",
            icon: "chart.pie",
            action: {},
            color: .blue
        )
    }
    .padding()
    .frame(width: 300)
}

#Preview("Status Card") {
    VStack {
        StatusCard(title: "System Status", status: .success, message: "All systems operational")
        StatusCard(title: "Memory Warning", status: .warning, message: "High memory usage detected")
        StatusCard(title: "Disk Error", status: .error, message: "Disk almost full")
        StatusCard(title: "Scanning", status: .loading, message: "Analyzing system...")
    }
    .padding()
    .frame(width: 300)
}
