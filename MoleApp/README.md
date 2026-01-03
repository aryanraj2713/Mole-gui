# MoleApp - Native macOS Resource Manager

<div align="center">
  <img src="https://cdn.tw93.fun/img/mole.jpeg" alt="Mole App" width="600" />
  
  **A native macOS application for system resource management and cleanup**
  
  Built with SwiftUI • Following Apple Human Interface Guidelines • Liquid Glass Design
</div>

---

## Overview

MoleApp is a native macOS application that provides a beautiful, first-party Apple-like experience for managing system resources. It wraps the powerful [Mole CLI tool](https://github.com/tw93/mole) with a modern SwiftUI interface.

### Features

- **🎯 Real-time System Monitoring** - Live CPU, memory, disk, and network metrics with smooth animations
- **🧹 Smart Cleanup** - Intelligent cache and temporary file cleanup with preview mode
- **📊 Health Score** - At-a-glance system health assessment
- **📝 Activity Logs** - Comprehensive logging with filtering and export
- **⚙️ Whitelist Protection** - Protect important files from cleanup
- **🌗 Dark Mode Support** - Seamless light and dark mode adaptation

---

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         MoleApp                                  │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    SwiftUI Views                         │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │   │
│  │  │Dashboard │ │ Monitor  │ │ Cleanup  │ │  Logs    │   │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    ViewModels (MVVM)                     │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │   │
│  │  │Dashboard │ │ Monitor  │ │ Cleanup  │ │  Logs    │   │   │
│  │  │ViewModel│ │ViewModel │ │ViewModel │ │ViewModel │   │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                      Services                            │   │
│  │  ┌──────────────┐ ┌───────────────┐ ┌───────────────┐   │   │
│  │  │  CLIService  │ │SystemMonitor  │ │CleanupService │   │   │
│  │  │              │ │   Service     │ │               │   │   │
│  │  └──────────────┘ └───────────────┘ └───────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    CLI Integration                       │   │
│  │              (Process, Pipe, Shell Commands)            │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
                     ┌─────────────────┐
                     │    Mole CLI     │
                     │  (if installed) │
                     └─────────────────┘
```

### Project Structure

```
MoleApp/
├── MoleApp.xcodeproj/          # Xcode project file
├── MoleApp/
│   ├── App/
│   │   ├── MoleAppApp.swift    # App entry point
│   │   ├── ContentView.swift   # Main content container
│   │   └── MoleApp.entitlements
│   ├── Models/
│   │   ├── SystemModels.swift  # System metrics data models
│   │   └── CleanupModels.swift # Cleanup operation models
│   ├── Services/
│   │   ├── CLIService.swift    # CLI command execution
│   │   ├── SystemMonitorService.swift  # Real-time monitoring
│   │   └── CleanupService.swift        # Cleanup operations
│   ├── ViewModels/
│   │   ├── DashboardViewModel.swift
│   │   ├── MonitorViewModel.swift
│   │   ├── CleanupViewModel.swift
│   │   ├── LogsViewModel.swift
│   │   └── SettingsViewModel.swift
│   ├── Views/
│   │   ├── Dashboard/
│   │   │   └── DashboardView.swift
│   │   ├── Monitor/
│   │   │   └── MonitorView.swift
│   │   ├── Cleanup/
│   │   │   └── CleanupView.swift
│   │   ├── Logs/
│   │   │   └── LogsView.swift
│   │   ├── Settings/
│   │   │   └── SettingsView.swift
│   │   └── Components/
│   │       ├── SidebarView.swift
│   │       ├── MetricCard.swift
│   │       ├── ProgressRing.swift
│   │       ├── LiveChart.swift
│   │       └── GlassCard.swift
│   ├── Utilities/
│   │   ├── DesignSystem.swift  # Colors, typography, spacing
│   │   └── Extensions.swift    # Swift extensions
│   └── Resources/
│       └── Assets.xcassets/
└── README.md
```

---

## Build Instructions

### Prerequisites

- **macOS 14.0 (Sonoma)** or later
- **Xcode 15.0** or later
- **Swift 5.9** or later

### Building the App

1. **Clone the repository:**
   ```bash
   git clone https://github.com/tw93/mole.git
   cd mole/MoleApp
   ```

2. **Open in Xcode:**
   ```bash
   open MoleApp.xcodeproj
   ```

3. **Select the target:**
   - Choose "MoleApp" scheme
   - Select "My Mac" as the run destination

4. **Build and Run:**
   - Press `Cmd + R` or click the Play button
   - The app will build and launch

### Optional: Install Mole CLI

For full functionality, install the Mole CLI tool:

```bash
brew install mole
# or
curl -fsSL https://raw.githubusercontent.com/tw93/mole/main/install.sh | bash
```

---

## Key Components

### Design System

The app follows Apple's **Liquid Glass** design principles:

- **Translucent materials** using `.ultraThinMaterial`
- **Rounded corners** with consistent radius values
- **Smooth animations** with spring dynamics
- **SF Symbols** for iconography
- **Dynamic Type** support
- **Dark/Light mode** automatic adaptation

```swift
// Example usage
GlassCard {
    VStack {
        HealthScoreRing(score: 85)
        Text("System Health")
    }
}
```

### CLI Integration

The `CLIService` provides a clean abstraction for shell command execution:

```swift
// Execute shell commands
let result = try await cliService.execute(command: "ps -A -o %cpu")

// Execute Mole CLI commands
let cleanResult = try await cliService.executeMole(command: "clean", dryRun: true)
```

### Real-time Monitoring

The `SystemMonitorService` collects metrics every 2 seconds:

```swift
// Start monitoring
await monitorService.startMonitoring { metrics in
    // Handle updated metrics
    self.currentMetrics = metrics
}

// Access metric history for charts
let cpuHistory = history.cpuHistory
```

---

## Screenshots Description

### Dashboard
- Large health score ring in the center (color-coded: green/yellow/orange/red)
- System info card showing hardware details
- Quick stats grid with CPU, Memory, Disk, Battery
- Quick action cards for common tasks
- Recent cleanup history

### Monitor
- Metric type picker (segmented control)
- Large live chart with smooth animation
- Detailed metric cards in 2-column grid
- Top processes table with CPU/Memory columns

### Cleanup
- Status card showing scan state and total size
- Expandable category cards with checkboxes
- Individual item rows with size and last accessed
- Preview (dry-run) and Clean buttons

### Logs
- Search bar with filter pills
- Timestamped log entries with type indicators
- Copy/Export functionality
- Auto-scroll toggle

### Settings
- Tabbed interface (General, Cleanup, Whitelist, About)
- Toggle switches for preferences
- Mole CLI status indicator
- Whitelist path management

---

## Extension Points

### Adding New Metrics

1. Add data model in `SystemModels.swift`:
   ```swift
   struct NewMetric: Equatable {
       let value: Double
       // ...
   }
   ```

2. Add collection method in `CLIService.swift`:
   ```swift
   func getNewMetric() async throws -> NewMetric {
       let result = try await execute(command: "...")
       // Parse and return
   }
   ```

3. Add to `SystemMonitorService.collectMetrics()`:
   ```swift
   async let newMetricTask = collectNewMetric()
   ```

4. Create UI component and integrate into views

### Adding New Cleanup Categories

1. Add category definition in `CleanupModels.swift`:
   ```swift
   CleanupCategory(
       id: "new_category",
       name: "New Category",
       description: "Description...",
       icon: "folder",
       items: [],
       isSelected: true,
       isExpanded: false
   )
   ```

2. Add scanner in `CleanupService.scanCategory()`:
   ```swift
   case "new_category":
       return try await scanNewCategory()
   ```

### Custom Styling

Modify `DesignSystem.swift` to customize:
- Colors
- Typography
- Spacing
- Corner radius
- Animations

---

## Production Hardening

### Next Steps for Production

1. **Code Signing**
   - Obtain Apple Developer certificate
   - Configure code signing in Xcode
   - Enable Hardened Runtime

2. **Sandboxing**
   - Enable App Sandbox entitlement
   - Request specific file access permissions
   - Use security-scoped bookmarks for user-selected paths

3. **Notarization**
   - Submit to Apple for notarization
   - Add stapled ticket to distributed app

4. **Error Handling**
   - Add comprehensive error recovery
   - Implement crash reporting
   - Add analytics (optional)

5. **Testing**
   - Unit tests for services
   - UI tests for critical flows
   - Performance testing

6. **Localization**
   - Extract strings to `.strings` files
   - Support multiple languages

7. **Accessibility**
   - Add VoiceOver labels
   - Support keyboard navigation
   - Dynamic Type compliance

---

## License

MIT License - feel free to enjoy and participate in open source.

---

## Credits

- **Mole CLI** - [tw93/mole](https://github.com/tw93/mole)
- **Design Inspiration** - Apple Human Interface Guidelines
- **Icons** - SF Symbols

---

<div align="center">
  <strong>Built with ❤️ for macOS</strong>
</div>
