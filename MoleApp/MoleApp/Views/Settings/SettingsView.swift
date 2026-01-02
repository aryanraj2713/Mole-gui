//
//  SettingsView.swift
//  MoleApp
//
//  Application settings view
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var selectedTab = SettingsTab.general
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(SettingsTab.general)
            
            CleanupSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Cleanup", systemImage: "trash")
                }
                .tag(SettingsTab.cleanup)
            
            WhitelistSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Whitelist", systemImage: "shield")
                }
                .tag(SettingsTab.whitelist)
            
            AboutSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(SettingsTab.about)
        }
        .frame(width: 500, height: 400)
    }
}

enum SettingsTab {
    case general
    case cleanup
    case whitelist
    case about
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: $viewModel.launchAtLogin)
                Toggle("Show in menu bar", isOn: $viewModel.showInMenuBar)
                Toggle("Show dock icon", isOn: $viewModel.showDockIcon)
            }
            
            Section("Monitoring") {
                Picker("Refresh interval", selection: $viewModel.refreshInterval) {
                    ForEach(RefreshRate.allCases) { rate in
                        Text(rate.rawValue).tag(rate)
                    }
                }
                
                Toggle("Show menu bar widget", isOn: $viewModel.showInMenuBarWidget)
            }
            
            Section {
                Button("Reset to Defaults") {
                    viewModel.resetToDefaults()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Cleanup Settings

struct CleanupSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section("Behavior") {
                Toggle("Confirm before cleanup", isOn: $viewModel.confirmBeforeCleanup)
                Toggle("Skip Trash by default", isOn: $viewModel.skipTrashByDefault)
                Toggle("Show notifications after cleanup", isOn: $viewModel.showCleanupNotifications)
            }
            
            Section("CLI Integration") {
                HStack {
                    Text("Mole CLI")
                    Spacer()
                    if viewModel.moleInstalled {
                        Label("Installed", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Label("Not Found", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                
                if viewModel.moleInstalled {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(viewModel.moleVersion)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    HStack {
                        Text("Path")
                        Spacer()
                        Text(viewModel.molePath)
                            .font(DesignSystem.Typography.monospace)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                } else {
                    Button("Install Mole CLI") {
                        viewModel.openMoleInstallPage()
                    }
                }
                
                Button("Check Installation") {
                    viewModel.checkMoleInstallation()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Whitelist Settings

struct WhitelistSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Whitelist")
                    .font(DesignSystem.Typography.headline)
                
                Text("Protected paths will not be cleaned")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Add new path
            HStack {
                TextField("Enter path to protect...", text: $viewModel.newWhitelistPath)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: { viewModel.browseForWhitelistPath() }) {
                    Image(systemName: "folder")
                }
                
                Button("Add") {
                    viewModel.addToWhitelist()
                }
                .disabled(viewModel.newWhitelistPath.isEmpty)
            }
            
            // Whitelist items
            List {
                if viewModel.whitelist.isEmpty {
                    Text("No protected paths")
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(viewModel.whitelist) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(DesignSystem.Typography.body)
                                
                                Text(item.path)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.removeFromWhitelist(item)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(DesignSystem.CornerRadius.medium)
        }
        .padding()
    }
}

// MARK: - About Settings

struct AboutSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // App Icon and Name
            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "ant.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
                
                Text("Mole")
                    .font(DesignSystem.Typography.largeTitle)
                
                Text("Version \(viewModel.appVersion) (\(viewModel.buildNumber))")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            // Description
            Text("Deep clean and optimize your Mac")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Divider()
            
            // Links
            VStack(spacing: DesignSystem.Spacing.sm) {
                Link(destination: URL(string: "https://github.com/tw93/mole")!) {
                    HStack {
                        Image(systemName: "link")
                        Text("GitHub Repository")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10))
                    }
                }
                
                Link(destination: URL(string: "https://github.com/tw93/mole/issues")!) {
                    HStack {
                        Image(systemName: "exclamationmark.bubble")
                        Text("Report an Issue")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10))
                    }
                }
            }
            .foregroundColor(.accentColor)
            
            Spacer()
            
            // Copyright
            Text("© 2024 Mole. MIT License.")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .frame(width: 500, height: 400)
}
