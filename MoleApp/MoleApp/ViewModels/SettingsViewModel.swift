//
//  SettingsViewModel.swift
//  MoleApp
//
//  ViewModel for the Settings view
//

import Foundation
import Combine
import ServiceManagement

@MainActor
final class SettingsViewModel: ObservableObject {
    // General Settings
    @Published var launchAtLogin = false
    @Published var showInMenuBar = true
    @Published var showDockIcon = true
    
    // Cleanup Settings
    @Published var confirmBeforeCleanup = true
    @Published var skipTrashByDefault = true
    @Published var showCleanupNotifications = true
    
    // Monitor Settings
    @Published var refreshInterval: RefreshRate = .normal
    @Published var showInMenuBarWidget = false
    
    // Whitelist
    @Published var whitelist: [WhitelistItem] = []
    @Published var newWhitelistPath = ""
    
    // CLI Status
    @Published var moleInstalled = false
    @Published var moleVersion = ""
    @Published var molePath = ""
    
    // About
    let appVersion = "1.0.0"
    let buildNumber = "1"
    
    private let cleanupService = CleanupService.shared
    private let cliService = CLIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSettings()
        setupBindings()
        checkMoleInstallation()
    }
    
    private func setupBindings() {
        cleanupService.$whitelist
            .receive(on: DispatchQueue.main)
            .assign(to: &$whitelist)
        
        // Save settings when changed
        $launchAtLogin
            .dropFirst()
            .sink { [weak self] value in
                self?.setLaunchAtLogin(value)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Settings Persistence
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        showInMenuBar = defaults.bool(forKey: "showInMenuBar")
        showDockIcon = defaults.bool(forKey: "showDockIcon")
        confirmBeforeCleanup = defaults.bool(forKey: "confirmBeforeCleanup")
        skipTrashByDefault = defaults.bool(forKey: "skipTrashByDefault")
        showCleanupNotifications = defaults.bool(forKey: "showCleanupNotifications")
        showInMenuBarWidget = defaults.bool(forKey: "showInMenuBarWidget")
        
        if let interval = defaults.string(forKey: "refreshInterval"),
           let rate = RefreshRate(rawValue: interval) {
            refreshInterval = rate
        }
        
        // Set defaults for first run
        if !defaults.bool(forKey: "settingsInitialized") {
            confirmBeforeCleanup = true
            skipTrashByDefault = true
            showCleanupNotifications = true
            showDockIcon = true
            defaults.set(true, forKey: "settingsInitialized")
            saveSettings()
        }
    }
    
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(launchAtLogin, forKey: "launchAtLogin")
        defaults.set(showInMenuBar, forKey: "showInMenuBar")
        defaults.set(showDockIcon, forKey: "showDockIcon")
        defaults.set(confirmBeforeCleanup, forKey: "confirmBeforeCleanup")
        defaults.set(skipTrashByDefault, forKey: "skipTrashByDefault")
        defaults.set(showCleanupNotifications, forKey: "showCleanupNotifications")
        defaults.set(showInMenuBarWidget, forKey: "showInMenuBarWidget")
        defaults.set(refreshInterval.rawValue, forKey: "refreshInterval")
    }
    
    // MARK: - Launch at Login
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to set launch at login: \(error)")
            }
        }
        saveSettings()
    }
    
    // MARK: - Whitelist Management
    
    func addToWhitelist() {
        guard !newWhitelistPath.isEmpty else { return }
        
        let path = newWhitelistPath.replacingOccurrences(of: "~", with: NSHomeDirectory())
        let name = (path as NSString).lastPathComponent
        
        cleanupService.addToWhitelist(path, name: name)
        newWhitelistPath = ""
    }
    
    func removeFromWhitelist(_ item: WhitelistItem) {
        cleanupService.removeFromWhitelist(item.id)
    }
    
    func browseForWhitelistPath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.newWhitelistPath = url.path
        }
    }
    
    // MARK: - CLI Status
    
    func checkMoleInstallation() {
        Task {
            if let path = await cliService.findMolePath() {
                moleInstalled = true
                molePath = path
                
                // Get version
                if let result = try? await cliService.execute(command: "\(path) --version") {
                    moleVersion = result.output.components(separatedBy: " ").last ?? "Unknown"
                }
            } else {
                moleInstalled = false
                molePath = ""
                moleVersion = ""
            }
        }
    }
    
    func openMoleInstallPage() {
        if let url = URL(string: "https://github.com/tw93/mole") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Reset
    
    func resetToDefaults() {
        launchAtLogin = false
        showInMenuBar = true
        showDockIcon = true
        confirmBeforeCleanup = true
        skipTrashByDefault = true
        showCleanupNotifications = true
        refreshInterval = .normal
        showInMenuBarWidget = false
        saveSettings()
    }
}
