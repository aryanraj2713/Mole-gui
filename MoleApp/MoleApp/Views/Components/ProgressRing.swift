//
//  ProgressRing.swift
//  MoleApp
//
//  Circular progress indicator component
//

import SwiftUI

struct ProgressRing: View {
    let progress: Double
    var size: CGFloat = 60
    var lineWidth: CGFloat = 6
    var color: Color = .accentColor
    var showLabel: Bool = true
    var animated: Bool = true
    
    @State private var animatedProgress: Double = 0
    
    private var normalizedProgress: Double {
        min(max(progress, 0), 100) / 100
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animated ? animatedProgress : normalizedProgress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(animated ? DesignSystem.Animation.smooth : nil, value: animatedProgress)
            
            // Label
            if showLabel {
                Text(String(format: "%.0f", progress))
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if animated {
                withAnimation(DesignSystem.Animation.smooth) {
                    animatedProgress = normalizedProgress
                }
            }
        }
        .onChange(of: progress) { _, newValue in
            if animated {
                withAnimation(DesignSystem.Animation.smooth) {
                    animatedProgress = min(max(newValue, 0), 100) / 100
                }
            }
        }
    }
}

// MARK: - Health Score Ring

struct HealthScoreRing: View {
    let score: Int
    var size: CGFloat = 100
    var lineWidth: CGFloat = 10
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
            
            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: Double(score) / 100)
                .stroke(
                    DesignSystem.Colors.healthGradient(for: score),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(DesignSystem.Animation.smooth, value: score)
            
            // Score label
            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.healthColor(for: score))
                
                Text("Health")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Multi Ring Progress

struct MultiRingProgress: View {
    let rings: [RingData]
    var size: CGFloat = 80
    var spacing: CGFloat = 4
    
    struct RingData: Identifiable {
        let id = UUID()
        let progress: Double
        let color: Color
        let label: String
    }
    
    var body: some View {
        ZStack {
            ForEach(Array(rings.enumerated()), id: \.element.id) { index, ring in
                let ringSize = size - CGFloat(index) * (spacing * 2 + 6)
                let lineWidth = max(4, 6 - CGFloat(index))
                
                ProgressRing(
                    progress: ring.progress,
                    size: ringSize,
                    lineWidth: lineWidth,
                    color: ring.color,
                    showLabel: false
                )
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Previews

#Preview("Progress Ring") {
    HStack(spacing: 20) {
        ProgressRing(progress: 25, color: .green)
        ProgressRing(progress: 50, color: .yellow)
        ProgressRing(progress: 75, color: .orange)
        ProgressRing(progress: 95, color: .red)
    }
    .padding()
}

#Preview("Health Score Ring") {
    HStack(spacing: 20) {
        HealthScoreRing(score: 92)
        HealthScoreRing(score: 75)
        HealthScoreRing(score: 55)
        HealthScoreRing(score: 30)
    }
    .padding()
}

#Preview("Multi Ring") {
    MultiRingProgress(rings: [
        .init(progress: 75, color: .blue, label: "CPU"),
        .init(progress: 60, color: .purple, label: "Memory"),
        .init(progress: 45, color: .green, label: "Disk")
    ])
    .padding()
}
