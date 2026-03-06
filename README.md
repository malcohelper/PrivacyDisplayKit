# PrivacyDisplayKit

A software-based privacy display library for iOS, inspired by the Samsung Galaxy S26 Ultra's Privacy Display. Uses **Face ID / TrueDepth Camera** and **tilt sensors (gyroscope + accelerometer)** to detect shoulder surfers and automatically obscure sensitive content.

## Features

- 🔍 **Face Tracking** — Detects multiple faces, suspicious viewing angles via ARKit
- 📐 **Tilt Detection** — Monitors device tilt angle with adaptive calibration
- 🎨 **5 Overlay Styles** — Blur, Dim, Noise, Gradient, Blur+Dim
- 🔐 **Face ID Auth** — Verify device owner identity
- ⚡ **SwiftUI** — `.privacyDisplay()`, `.privacySensitive()` modifiers
- 🏗️ **UIKit** — `enablePrivacyDisplay()`, `markAsPrivacySensitive()` extensions
- 📱 **Presets** — Default, High Security, Battery Saver, Banking
- 🔋 **Battery Friendly** — Configurable FPS, auto-pause in background

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+
- TrueDepth camera (for Face Tracking) or Gyroscope (for Tilt Detection)

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/malcohelper/PrivacyDisplayKit.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** → paste the repo URL.

## Quick Start

### SwiftUI

```swift
import PrivacyDisplayKit

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Public info")
            
            VStack {
                Text("Account Balance")
                    .font(.headline)
                Text("$1,234,567.89")
                    .font(.title)
            }
            .padding()
            .privacySensitive()  // obscures the entire container with Lock UI
        }
        .privacyDisplay(mode: .combined, sensitivity: .high)
    }
}
```

### UIKit

```swift
import PrivacyDisplayKit

class MyViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.enablePrivacyDisplay(config: .banking)
        
        // or mark specific container views
        balanceContainerView.markAsPrivacySensitive()
    }
}
```

### Presets

```swift
PrivacyConfiguration.default       // balanced security & performance
PrivacyConfiguration.highSecurity  // more sensitive, faster reaction
PrivacyConfiguration.batterySaver  // tilt-only, minimal battery drain
PrivacyConfiguration.banking       // maximum protection
```

## API Reference

### PrivacyDisplayManager

```swift
let manager = PrivacyDisplayManager.shared
manager.start(with: .banking)
manager.stop()
manager.pause()
manager.resume()

// observe state
manager.$isPrivacyModeActive    // Published<Bool>
manager.$currentThreatLevel     // Published<ThreatLevel>
manager.$currentState           // Published<PrivacyState>
```

### Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `detectionMode` | `.combined` | Face tracking, tilt, or both |
| `sensitivity` | `.medium` | low / medium / high / custom |
| `tiltThreshold` | `30°` | Angle threshold to trigger |
| `overlayStyle` | `.blur()` | Visual overlay type |
| `activationDelay` | `0.5s` | Delay before activating |
| `deactivationDelay` | `1.0s` | Delay before deactivating |
| `maxAllowedFaces` | `1` | Max faces before triggering |
| `hapticFeedback` | `true` | Vibrate on state change |

### Detection Modes

| Mode | Source | Battery | Hardware Required |
|------|--------|---------|------------------|
| `.faceTracking` | ARKit TrueDepth | High | TrueDepth camera |
| `.tiltDetection` | CoreMotion | Low | Gyroscope |
| `.combined` | Both | Medium | TrueDepth + Gyroscope |

## Architecture

```
PrivacyDisplayKit/
├── Core/           → Manager, Configuration, Models
├── FaceTracking/   → ARKit engine, Face ID auth
├── TiltDetection/  → CoreMotion engine, calibration
├── Overlay/        → Visual overlay renderer
├── SwiftUI/        → ViewModifiers, Environment
├── UIKit/          → Extensions, Container VC
└── Utilities/      → Device capabilities, Logger
```

## License

MIT License
