//
//  LiveChart.swift
//  MoleApp
//
//  Live chart component for real-time data visualization
//

import SwiftUI
import Charts

struct LiveChart: View {
    let data: [Double]
    let title: String
    let unit: String
    let color: Color
    var height: CGFloat = 200
    var showGrid: Bool = true
    var animated: Bool = true
    
    private var chartData: [ChartDataPoint] {
        data.enumerated().map { ChartDataPoint(index: $0.offset, value: $0.element) }
    }
    
    private var maxValue: Double {
        max(data.max() ?? 0, 10)
    }
    
    private var currentValue: Double {
        data.last ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header
            HStack {
                Text(title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                Text("\(String(format: "%.1f", currentValue)) \(unit)")
                    .font(DesignSystem.Typography.monospaceLarge)
                    .foregroundColor(color)
            }
            
            // Chart
            if #available(macOS 14.0, *) {
                Chart(chartData) { point in
                    LineMark(
                        x: .value("Time", point.index),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(color.gradient)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Time", point.index),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                            .foregroundStyle(Color.gray.opacity(0.3))
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(String(format: "%.0f", doubleValue))
                                    .font(DesignSystem.Typography.caption2)
                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                            }
                        }
                    }
                }
                .chartYScale(domain: 0...maxValue * 1.1)
                .frame(height: height)
                .animation(animated ? DesignSystem.Animation.quick : nil, value: data)
            } else {
                // Fallback for older macOS
                LegacyLineChart(data: data, color: color)
                    .frame(height: height)
            }
            
            // Stats row
            HStack {
                StatLabel(label: "Current", value: String(format: "%.1f", currentValue))
                Spacer()
                StatLabel(label: "Avg", value: String(format: "%.1f", data.average))
                Spacer()
                StatLabel(label: "Max", value: String(format: "%.1f", data.max ?? 0))
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
    }
}

// MARK: - Chart Data Point

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let index: Int
    let value: Double
}

// MARK: - Stat Label

private struct StatLabel: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .fontWeight(.medium)
            
            Text(label)
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
    }
}

// MARK: - Legacy Line Chart (for older macOS)

struct LegacyLineChart: View {
    let data: [Double]
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            let maxValue = max(data.max() ?? 0, 10)
            let stepX = geometry.size.width / CGFloat(max(data.count - 1, 1))
            
            ZStack {
                // Grid lines
                ForEach(0..<5) { i in
                    let y = geometry.size.height * CGFloat(i) / 4
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                    .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                }
                
                // Area fill
                Path { path in
                    guard !data.isEmpty else { return }
                    
                    let firstY = geometry.size.height - (CGFloat(data[0]) / CGFloat(maxValue)) * geometry.size.height
                    path.move(to: CGPoint(x: 0, y: geometry.size.height))
                    path.addLine(to: CGPoint(x: 0, y: firstY))
                    
                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = geometry.size.height - (CGFloat(value) / CGFloat(maxValue)) * geometry.size.height
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    path.addLine(to: CGPoint(x: CGFloat(data.count - 1) * stepX, y: geometry.size.height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Line
                Path { path in
                    guard !data.isEmpty else { return }
                    
                    let firstY = geometry.size.height - (CGFloat(data[0]) / CGFloat(maxValue)) * geometry.size.height
                    path.move(to: CGPoint(x: 0, y: firstY))
                    
                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = geometry.size.height - (CGFloat(value) / CGFloat(maxValue)) * geometry.size.height
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

// MARK: - Mini Sparkline

struct Sparkline: View {
    let data: [Double]
    let color: Color
    var height: CGFloat = 30
    
    var body: some View {
        GeometryReader { geometry in
            let maxValue = max(data.max() ?? 0, 1)
            let stepX = geometry.size.width / CGFloat(max(data.count - 1, 1))
            
            Path { path in
                guard !data.isEmpty else { return }
                
                let firstY = geometry.size.height - (CGFloat(data[0]) / CGFloat(maxValue)) * geometry.size.height
                path.move(to: CGPoint(x: 0, y: firstY))
                
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = geometry.size.height - (CGFloat(value) / CGFloat(maxValue)) * geometry.size.height
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
        .frame(height: height)
    }
}

// MARK: - Preview

#Preview {
    let sampleData = (0..<60).map { _ in Double.random(in: 20...80) }
    
    VStack {
        LiveChart(
            data: sampleData,
            title: "CPU Usage",
            unit: "%",
            color: .blue
        )
        
        LiveChart(
            data: sampleData.map { $0 * 0.8 },
            title: "Memory Usage",
            unit: "%",
            color: .purple,
            height: 150
        )
    }
    .padding()
    .frame(width: 500)
}
