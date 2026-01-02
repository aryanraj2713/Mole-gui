//
//  LogsView.swift
//  MoleApp
//
//  Activity logs view
//

import SwiftUI

struct LogsView: View {
    @StateObject private var viewModel = LogsViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
                .padding(DesignSystem.Spacing.xl)
            
            Divider()
            
            // Logs List
            logsListSection
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Logs")
                        .font(DesignSystem.Typography.largeTitle)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("\(viewModel.filteredLogs.count) entries")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Button(action: { viewModel.copyAllToClipboard() }) {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.glass)
                    .help("Copy all logs")
                    
                    Button(action: { viewModel.exportLogs() }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(.glass)
                    .help("Export logs")
                    
                    Button(action: { viewModel.clearLogs() }) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.glass)
                    .help("Clear logs")
                }
            }
            
            // Search and Filter Bar
            HStack(spacing: DesignSystem.Spacing.md) {
                // Search Field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    
                    TextField("Search logs...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: { viewModel.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(DesignSystem.Spacing.sm)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(DesignSystem.CornerRadius.medium)
                
                // Filter Picker
                Picker("Filter", selection: $viewModel.selectedFilter) {
                    ForEach(LogFilter.allCases) { filter in
                        HStack {
                            Image(systemName: filter.icon)
                            Text(filter.rawValue)
                        }
                        .tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
                
                Spacer()
                
                // Auto-scroll toggle
                Toggle(isOn: $viewModel.isAutoScrollEnabled) {
                    Label("Auto-scroll", systemImage: "arrow.down.to.line")
                        .font(DesignSystem.Typography.caption)
                }
                .toggleStyle(.switch)
                .controlSize(.small)
            }
        }
    }
    
    // MARK: - Logs List Section
    
    private var logsListSection: some View {
        ScrollViewReader { proxy in
            List(viewModel.filteredLogs) { entry in
                LogEntryRow(entry: entry, onCopy: {
                    viewModel.copyToClipboard(entry)
                })
                .id(entry.id)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(
                    top: DesignSystem.Spacing.xs,
                    leading: DesignSystem.Spacing.lg,
                    bottom: DesignSystem.Spacing.xs,
                    trailing: DesignSystem.Spacing.lg
                ))
            }
            .listStyle(.plain)
            .onChange(of: viewModel.filteredLogs.count) { _, _ in
                if viewModel.isAutoScrollEnabled, let first = viewModel.filteredLogs.first {
                    withAnimation {
                        proxy.scrollTo(first.id, anchor: .top)
                    }
                }
            }
        }
    }
}

// MARK: - Log Entry Row

struct LogEntryRow: View {
    let entry: LogEntry
    let onCopy: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            // Type indicator
            Image(systemName: entry.type.icon)
                .font(.system(size: 14))
                .foregroundColor(colorForType(entry.type))
                .frame(width: 20)
            
            // Timestamp
            Text(entry.formattedTimestamp)
                .font(DesignSystem.Typography.monospace)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .frame(width: 70, alignment: .leading)
            
            // Source
            Text(entry.source)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .frame(width: 80, alignment: .leading)
            
            // Message
            Text(entry.message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(2)
            
            Spacer()
            
            // Copy button (visible on hover)
            if isHovered {
                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .fill(isHovered ? Color.gray.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            Button("Copy") {
                onCopy()
            }
        }
    }
    
    private func colorForType(_ type: LogType) -> Color {
        switch type {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .debug: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    LogsView()
        .environmentObject(AppState())
        .frame(width: 800, height: 600)
}
