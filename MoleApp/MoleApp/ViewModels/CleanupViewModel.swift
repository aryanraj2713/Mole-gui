//
//  CleanupViewModel.swift
//  MoleApp
//
//  ViewModel for the Cleanup view
//

import Foundation
import Combine

@MainActor
final class CleanupViewModel: ObservableObject {
    @Published var state: CleanupState = .idle
    @Published var categories: [CleanupCategory] = []
    @Published var lastResult: CleanupResult?
    @Published var showConfirmation = false
    @Published var showDryRunPreview = false
    @Published var dryRunResult: CleanupResult?
    
    private let cleanupService = CleanupService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        cleanupService.$state
            .receive(on: DispatchQueue.main)
            .assign(to: &$state)
        
        cleanupService.$categories
            .receive(on: DispatchQueue.main)
            .assign(to: &$categories)
        
        cleanupService.$lastResult
            .receive(on: DispatchQueue.main)
            .assign(to: &$lastResult)
    }
    
    // MARK: - Actions
    
    func scan() {
        Task {
            await cleanupService.scan()
        }
    }
    
    func performCleanup() {
        showConfirmation = true
    }
    
    func confirmCleanup() {
        showConfirmation = false
        Task {
            await cleanupService.performCleanup(dryRun: false)
        }
    }
    
    func performDryRun() {
        Task {
            await cleanupService.performCleanup(dryRun: true)
            dryRunResult = cleanupService.lastResult
            showDryRunPreview = true
        }
    }
    
    func toggleCategory(_ categoryId: String) {
        cleanupService.toggleCategory(categoryId)
    }
    
    func toggleItem(categoryId: String, itemId: String) {
        cleanupService.toggleItem(categoryId: categoryId, itemId: itemId)
    }
    
    func selectAll() {
        cleanupService.selectAll()
    }
    
    func deselectAll() {
        cleanupService.deselectAll()
    }
    
    func reset() {
        cleanupService.reset()
    }
    
    // MARK: - Computed Properties
    
    var totalSelectedSize: String {
        cleanupService.totalSelectedSizeFormatted
    }
    
    var selectedItemCount: Int {
        cleanupService.selectedItemCount
    }
    
    var canClean: Bool {
        switch state {
        case .ready:
            return selectedItemCount > 0
        default:
            return false
        }
    }
    
    var isProcessing: Bool {
        state.isProcessing
    }
    
    var progressValue: Double {
        switch state {
        case .cleaning(let progress, _):
            return progress
        default:
            return 0
        }
    }
    
    var currentItemName: String {
        switch state {
        case .cleaning(_, let item):
            return item
        default:
            return ""
        }
    }
    
    var statusMessage: String {
        switch state {
        case .idle:
            return "Click 'Scan' to analyze your system"
        case .scanning:
            return "Scanning system..."
        case .ready(let size):
            let formatted = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
            return "Found \(formatted) that can be cleaned"
        case .confirming:
            return "Confirm cleanup..."
        case .cleaning(_, let item):
            return "Cleaning: \(item)"
        case .completed(let freed, let count):
            let formatted = ByteCountFormatter.string(fromByteCount: Int64(freed), countStyle: .file)
            return "Cleaned \(count) items, freed \(formatted)"
        case .failed(let error):
            return "Error: \(error)"
        }
    }
}

// MARK: - Category Extensions

extension CleanupCategory {
    var statusText: String {
        if items.isEmpty {
            return "Nothing to clean"
        }
        let selected = items.filter(\.isSelected).count
        return "\(selected)/\(items.count) selected"
    }
}
