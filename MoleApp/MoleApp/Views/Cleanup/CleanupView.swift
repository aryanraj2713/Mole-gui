//
//  CleanupView.swift
//  MoleApp
//
//  Cleanup view for managing system cleanup operations
//

import SwiftUI

struct CleanupView: View {
    @StateObject private var viewModel = CleanupViewModel()
    @State private var showingConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Header
                headerSection
                
                // Status Card
                statusSection
                
                // Categories List
                categoriesSection
                
                // Action Buttons
                actionButtonsSection
            }
            .padding(DesignSystem.Spacing.xl)
        }
        .alert("Confirm Cleanup", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clean", role: .destructive) {
                viewModel.confirmCleanup()
            }
        } message: {
            Text("Are you sure you want to clean \(viewModel.selectedItemCount) items? This will free up \(viewModel.totalSelectedSize).")
        }
        .sheet(isPresented: $viewModel.showDryRunPreview) {
            DryRunPreviewSheet(result: viewModel.dryRunResult)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Cleanup")
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Free up disk space by removing unnecessary files")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            if case .ready = viewModel.state {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Button("Select All") {
                        viewModel.selectAll()
                    }
                    .buttonStyle(.glass)
                    
                    Button("Deselect All") {
                        viewModel.deselectAll()
                    }
                    .buttonStyle(.glass)
                }
            }
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        GlassCard {
            HStack(spacing: DesignSystem.Spacing.lg) {
                statusIcon
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(statusTitle)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text(viewModel.statusMessage)
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                if case .ready(let size) = viewModel.state {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                            .font(DesignSystem.Typography.title2)
                            .foregroundColor(.accentColor)
                        
                        Text("can be freed")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                
                if case .cleaning(let progress, _) = viewModel.state {
                    ProgressRing(progress: progress * 100, size: 50, lineWidth: 5, color: .accentColor)
                }
            }
        }
    }
    
    private var statusIcon: some View {
        Group {
            switch viewModel.state {
            case .idle:
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            case .scanning:
                ProgressView()
                    .scaleEffect(0.8)
            case .ready:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .confirming:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
            case .cleaning:
                ProgressView()
                    .scaleEffect(0.8)
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .font(.system(size: 24))
        .frame(width: 40)
    }
    
    private var statusTitle: String {
        switch viewModel.state {
        case .idle: return "Ready to Scan"
        case .scanning: return "Scanning..."
        case .ready: return "Scan Complete"
        case .confirming: return "Confirm Cleanup"
        case .cleaning: return "Cleaning..."
        case .completed: return "Cleanup Complete"
        case .failed: return "Error"
        }
    }
    
    // MARK: - Categories Section
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Categories")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            if viewModel.categories.isEmpty {
                GlassCard {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                        
                        Text("Click 'Scan' to analyze your system")
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.xxl)
                }
            } else {
                ForEach(viewModel.categories) { category in
                    CategoryCard(
                        category: category,
                        onToggle: { viewModel.toggleCategory(category.id) },
                        onToggleItem: { itemId in
                            viewModel.toggleItem(categoryId: category.id, itemId: itemId)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            if case .idle = viewModel.state {
                Button(action: { viewModel.scan() }) {
                    Label("Scan", systemImage: "magnifyingglass")
                }
                .buttonStyle(.primary)
            } else if case .ready = viewModel.state {
                Button(action: { viewModel.scan() }) {
                    Label("Rescan", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.secondary)
                
                Button(action: { viewModel.performDryRun() }) {
                    Label("Preview", systemImage: "eye")
                }
                .buttonStyle(.secondary)
                
                Button(action: { showingConfirmation = true }) {
                    Label("Clean \(viewModel.totalSelectedSize)", systemImage: "trash")
                }
                .buttonStyle(.primary)
                .disabled(!viewModel.canClean)
            } else if case .completed = viewModel.state {
                Button(action: { viewModel.reset() }) {
                    Label("Scan Again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.primary)
            } else if case .failed = viewModel.state {
                Button(action: { viewModel.reset() }) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.primary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Category Card

struct CategoryCard: View {
    let category: CleanupCategory
    let onToggle: () -> Void
    let onToggleItem: (String) -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        GlassCard(padding: 0) {
            VStack(spacing: 0) {
                // Header
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Button(action: onToggle) {
                            Image(systemName: category.isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(category.isSelected ? .accentColor : DesignSystem.Colors.tertiaryText)
                                .font(.system(size: 20))
                        }
                        .buttonStyle(.plain)
                        
                        Image(systemName: category.icon)
                            .font(.system(size: 16))
                            .foregroundColor(.accentColor)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.name)
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text(category.description)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if !category.items.isEmpty {
                            Text(category.totalSizeFormatted)
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(category.isSelected ? .accentColor : DesignSystem.Colors.secondaryText)
                        }
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                    .padding(DesignSystem.Spacing.md)
                }
                .buttonStyle(.plain)
                
                // Expanded items
                if isExpanded && !category.items.isEmpty {
                    Divider()
                    
                    VStack(spacing: 0) {
                        ForEach(category.items) { item in
                            CleanupItemRow(
                                item: item,
                                onToggle: { onToggleItem(item.id) }
                            )
                            
                            if item.id != category.items.last?.id {
                                Divider()
                                    .padding(.leading, 52)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Cleanup Item Row

struct CleanupItemRow: View {
    let item: CleanupItem
    let onToggle: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Button(action: onToggle) {
                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isProtected ? .gray : (item.isSelected ? .accentColor : DesignSystem.Colors.tertiaryText))
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .disabled(item.isProtected)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(item.name)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    if item.isProtected {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
                
                Text(item.path)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            if let lastAccessed = item.lastAccessedFormatted {
                Text(lastAccessed)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            
            Text(item.sizeFormatted)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .fontWeight(.medium)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(isHovered ? Color.gray.opacity(0.1) : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Dry Run Preview Sheet

struct DryRunPreviewSheet: View {
    let result: CleanupResult?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Text("Cleanup Preview")
                .font(DesignSystem.Typography.title)
            
            if let result = result {
                VStack(spacing: DesignSystem.Spacing.md) {
                    InfoCard(
                        title: "Space to be freed",
                        value: result.freedSpaceFormatted,
                        icon: "externaldrive.badge.minus",
                        color: .green
                    )
                    
                    InfoCard(
                        title: "Items to clean",
                        value: "\(result.itemsCleaned)",
                        icon: "doc.on.doc",
                        color: .blue
                    )
                }
                
                Text("This is a preview. No files have been deleted.")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.primary)
        }
        .padding(DesignSystem.Spacing.xxl)
        .frame(width: 400)
    }
}

// MARK: - Preview

#Preview {
    CleanupView()
        .environmentObject(AppState())
        .frame(width: 800, height: 700)
}
