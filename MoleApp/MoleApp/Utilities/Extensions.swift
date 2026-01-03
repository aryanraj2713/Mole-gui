//
//  Extensions.swift
//  MoleApp
//
//  Utility extensions for the app
//

import SwiftUI

// MARK: - Number Formatting

extension Double {
    var percentFormatted: String {
        String(format: "%.1f%%", self)
    }
    
    var oneDecimal: String {
        String(format: "%.1f", self)
    }
    
    var twoDecimals: String {
        String(format: "%.2f", self)
    }
    
    var mbPerSecond: String {
        String(format: "%.1f MB/s", self)
    }
}

extension UInt64 {
    var bytesFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: .file)
    }
    
    var memoryFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: .memory)
    }
}

extension Int {
    var rpmFormatted: String {
        "\(self) RPM"
    }
    
    var temperatureFormatted: String {
        "\(self)°C"
    }
}

// MARK: - Date Formatting

extension Date {
    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: self)
    }
    
    var dateTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - String Extensions

extension String {
    var expandingTilde: String {
        replacingOccurrences(of: "~", with: NSHomeDirectory())
    }
    
    func truncated(to length: Int, trailing: String = "...") -> String {
        if count > length {
            return String(prefix(length)) + trailing
        }
        return self
    }
}

// MARK: - Array Extensions

extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
    
    var latest: Double {
        last ?? 0
    }
    
    var max: Double {
        self.max() ?? 0
    }
    
    var min: Double {
        self.min() ?? 0
    }
}

// MARK: - View Modifiers

struct ConditionalModifier<Content: View>: ViewModifier {
    let condition: Bool
    let transform: (Content) -> Content
    
    func body(content: Content) -> some View {
        if condition {
            transform(content)
        } else {
            content
        }
    }
}

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    func onAppearOnce(perform action: @escaping () -> Void) -> some View {
        modifier(OnAppearOnceModifier(action: action))
    }
}

struct OnAppearOnceModifier: ViewModifier {
    @State private var hasAppeared = false
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content.onAppear {
            if !hasAppeared {
                hasAppeared = true
                action()
            }
        }
    }
}

// MARK: - Binding Extensions

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

// MARK: - NSOpenPanel Helper

extension NSOpenPanel {
    static func selectDirectory(title: String = "Select Directory") async -> URL? {
        await withCheckedContinuation { continuation in
            let panel = NSOpenPanel()
            panel.title = title
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            
            panel.begin { response in
                if response == .OK {
                    continuation.resume(returning: panel.url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    static func selectFile(title: String = "Select File", types: [String] = []) async -> URL? {
        await withCheckedContinuation { continuation in
            let panel = NSOpenPanel()
            panel.title = title
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = false
            
            panel.begin { response in
                if response == .OK {
                    continuation.resume(returning: panel.url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

// MARK: - Progress Helpers

struct ProgressInfo {
    let value: Double
    let total: Double
    
    var percentage: Double {
        guard total > 0 else { return 0 }
        return (value / total) * 100
    }
    
    var percentageFormatted: String {
        String(format: "%.1f%%", percentage)
    }
}

// MARK: - Pasteboard Extension

extension NSPasteboard {
    func copyString(_ string: String) {
        clearContents()
        setString(string, forType: .string)
    }
}

// MARK: - Environment Keys

private struct SafeAreaInsetsKey: EnvironmentKey {
    static let defaultValue: EdgeInsets = EdgeInsets()
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        get { self[SafeAreaInsetsKey.self] }
        set { self[SafeAreaInsetsKey.self] = newValue }
    }
}

// MARK: - Animation Helpers

extension Animation {
    static var smoothSpring: Animation {
        .spring(response: 0.4, dampingFraction: 0.8)
    }
    
    static var quickSpring: Animation {
        .spring(response: 0.3, dampingFraction: 0.7)
    }
}

// MARK: - Identifiable Conformance

extension String: Identifiable {
    public var id: String { self }
}

// MARK: - Preview Helpers

#if DEBUG
extension PreviewDevice {
    static let macBookPro = PreviewDevice(rawValue: "Mac")
}

struct PreviewContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(width: 800, height: 600)
            .environmentObject(AppState())
    }
}
#endif
