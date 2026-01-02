//
//  DesignSystem.swift
//  MoleApp
//
//  Design system following Apple's Liquid Glass principles
//

import SwiftUI

// MARK: - Design System

enum DesignSystem {
    
    // MARK: - Colors
    
    enum Colors {
        // Backgrounds
        static let windowBackground = Color(NSColor.windowBackgroundColor)
        static let contentBackground = Color(NSColor.controlBackgroundColor)
        static let cardBackground = Color(NSColor.controlBackgroundColor).opacity(0.8)
        static let glassBackground = Color.white.opacity(0.1)
        
        // Text
        static let primaryText = Color(NSColor.labelColor)
        static let secondaryText = Color(NSColor.secondaryLabelColor)
        static let tertiaryText = Color(NSColor.tertiaryLabelColor)
        
        // Accent Colors
        static let accent = Color.accentColor
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Health Score Colors
        static func healthColor(for score: Int) -> Color {
            if score >= 80 { return .green }
            if score >= 60 { return .yellow }
            if score >= 40 { return .orange }
            return .red
        }
        
        static func healthGradient(for score: Int) -> LinearGradient {
            let colors: [Color]
            if score >= 80 {
                colors = [Color(hex: "#34D399"), Color(hex: "#10B981")]
            } else if score >= 60 {
                colors = [Color(hex: "#FBBF24"), Color(hex: "#F59E0B")]
            } else if score >= 40 {
                colors = [Color(hex: "#FB923C"), Color(hex: "#F97316")]
            } else {
                colors = [Color(hex: "#F87171"), Color(hex: "#EF4444")]
            }
            return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    // MARK: - Typography
    
    enum Typography {
        static let largeTitle = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title2 = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 16, weight: .medium, design: .rounded)
        static let headline = Font.system(size: 14, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 13, weight: .regular, design: .default)
        static let callout = Font.system(size: 12, weight: .regular, design: .default)
        static let caption = Font.system(size: 11, weight: .regular, design: .default)
        static let caption2 = Font.system(size: 10, weight: .regular, design: .default)
        
        static let monospace = Font.system(size: 12, weight: .regular, design: .monospaced)
        static let monospaceLarge = Font.system(size: 14, weight: .medium, design: .monospaced)
        
        // Metrics Display
        static let metricValue = Font.system(size: 32, weight: .bold, design: .rounded)
        static let metricLabel = Font.system(size: 11, weight: .medium, design: .default)
    }
    
    // MARK: - Spacing
    
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    enum CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 10
        static let large: CGFloat = 14
        static let extraLarge: CGFloat = 20
    }
    
    // MARK: - Shadows
    
    enum Shadows {
        static let small = ShadowStyle(
            color: .black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
        
        static let medium = ShadowStyle(
            color: .black.opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )
        
        static let large = ShadowStyle(
            color: .black.opacity(0.2),
            radius: 16,
            x: 0,
            y: 8
        )
    }
    
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.35)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
    }
    
    // MARK: - Icons
    
    enum Icons {
        // Navigation
        static let dashboard = "gauge.with.dots.needle.bottom.50percent"
        static let monitor = "chart.line.uptrend.xyaxis"
        static let cleanup = "trash"
        static let logs = "doc.text"
        static let settings = "gear"
        
        // Metrics
        static let cpu = "cpu"
        static let memory = "memorychip"
        static let disk = "internaldrive"
        static let network = "network"
        static let battery = "battery.100"
        static let thermal = "thermometer"
        static let process = "square.stack.3d.up"
        
        // Actions
        static let scan = "magnifyingglass"
        static let clean = "trash.slash"
        static let refresh = "arrow.clockwise"
        static let start = "play.fill"
        static let stop = "stop.fill"
        static let expand = "chevron.down"
        static let collapse = "chevron.up"
        
        // Status
        static let success = "checkmark.circle.fill"
        static let warning = "exclamationmark.triangle.fill"
        static let error = "xmark.circle.fill"
        static let info = "info.circle.fill"
    }
}

// MARK: - View Extensions

extension View {
    func glassBackground(cornerRadius: CGFloat = DesignSystem.CornerRadius.medium) -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    func cardStyle(padding: CGFloat = DesignSystem.Spacing.lg) -> some View {
        self
            .padding(padding)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
    }
    
    func shadowStyle(_ style: DesignSystem.ShadowStyle) -> some View {
        self.shadow(
            color: style.color,
            radius: style.radius,
            x: style.x,
            y: style.y
        )
    }
}

// MARK: - Color Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(isEnabled ? Color.accentColor : Color.gray)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundColor(DesignSystem.Colors.primaryText)
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(DesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundColor(DesignSystem.Colors.primaryText)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .glassBackground()
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == GlassButtonStyle {
    static var glass: GlassButtonStyle { GlassButtonStyle() }
}
