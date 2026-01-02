//
//  DashboardViewModel.swift
//  MoleApp
//
//  ViewModel for the Dashboard view
//

import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var metrics: SystemMetrics = .empty
    @Published var isLoading = true
    @Published var quickActions: [QuickAction] = QuickAction.defaults
    @Published var recentCleanups: [CleanupHistoryEntry] = []
    
    private let monitorService = SystemMonitorService.shared
    private let cleanupService = CleanupService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        monitorService.$currentMetrics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metrics in
                self?.metrics = metrics
                self?.isLoading = false
            }
            .store(in: &cancellables)
        
        cleanupService.$history
            .receive(on: DispatchQueue.main)
            .map { Array($0.prefix(3)) }
            .assign(to: &$recentCleanups)
    }
    
    func startMonitoring() {
        Task {
            await monitorService.startMonitoring()
        }
    }
    
    func stopMonitoring() {
        monitorService.stopMonitoring()
    }
    
    func refresh() async {
        isLoading = true
        await monitorService.startMonitoring()
    }
    
    // MARK: - Health Score Helpers
    
    var healthScoreColor: String {
        let score = metrics.healthScore
        if score >= 80 { return "green" }
        if score >= 60 { return "yellow" }
        if score >= 40 { return "orange" }
        return "red"
    }
    
    var healthScoreGradient: [String] {
        let score = metrics.healthScore
        if score >= 80 { return ["#34D399", "#10B981"] }
        if score >= 60 { return ["#FBBF24", "#F59E0B"] }
        if score >= 40 { return ["#FB923C", "#F97316"] }
        return ["#F87171", "#EF4444"]
    }
}

// MARK: - Quick Actions

struct QuickAction: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let action: ActionType
    
    enum ActionType {
        case cleanup
        case monitor
        case optimize
        case analyze
    }
    
    static let defaults: [QuickAction] = [
        QuickAction(
            name: "Quick Clean",
            description: "Clean caches & temp files",
            icon: "trash.slash",
            action: .cleanup
        ),
        QuickAction(
            name: "Monitor",
            description: "View live system metrics",
            icon: "chart.line.uptrend.xyaxis",
            action: .monitor
        ),
        QuickAction(
            name: "Optimize",
            description: "Improve system performance",
            icon: "bolt.circle",
            action: .optimize
        ),
        QuickAction(
            name: "Analyze",
            description: "Explore disk usage",
            icon: "chart.pie",
            action: .analyze
        )
    ]
}
