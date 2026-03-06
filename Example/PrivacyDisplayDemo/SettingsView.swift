import SwiftUI
import PrivacyDisplayKit

struct SettingsView: View {
    @State private var detectionMode: DetectionMode = .combined
    @State private var sensitivity: Double = 0.5
    @State private var tiltThreshold: Double = 30
    @State private var overlayStyleIndex: Int = 0
    @State private var hapticFeedback: Bool = true
    @State private var debugLogging: Bool = false
    @State private var showCapabilities: Bool = false
    
    private let overlayOptions = ["Blur", "Dim", "Noise", "Gradient", "Blur + Dim"]
    
    var body: some View {
        NavigationStack {
            Form {
                // Detection Settings
                Section("Detection Mode") {
                    Picker("Mode", selection: $detectionMode) {
                        Text("Face Tracking").tag(DetectionMode.faceTracking)
                        Text("Tilt Detection").tag(DetectionMode.tiltDetection)
                        Text("Combined").tag(DetectionMode.combined)
                    }
                    .pickerStyle(.segmented)
                }
                
                // Sensitivity
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Sensitivity")
                            Spacer()
                            Text(sensitivityLabel)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $sensitivity, in: 0...1, step: 0.1)
                    }
                    
                    if detectionMode != .faceTracking {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Tilt Threshold")
                                Spacer()
                                Text("\(Int(tiltThreshold))°")
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $tiltThreshold, in: 10...60, step: 5)
                        }
                    }
                } header: {
                    Text("Sensitivity")
                } footer: {
                    Text("Higher sensitivity detects threats sooner but may cause more false positives.")
                }
                
                // Overlay Style
                Section("Overlay Style") {
                    Picker("Style", selection: $overlayStyleIndex) {
                        ForEach(0..<overlayOptions.count, id: \.self) { index in
                            Text(overlayOptions[index]).tag(index)
                        }
                    }
                }
                
                // Behavior
                Section("Behavior") {
                    Toggle("Haptic Feedback", isOn: $hapticFeedback)
                    Toggle("Debug Logging", isOn: $debugLogging)
                }
                
                // Device Capabilities
                Section("Device Capabilities") {
                    Button("Show Device Info") {
                        showCapabilities = true
                    }
                }
                
                // Presets
                Section("Quick Presets") {
                    Button("Default") { applyPreset(.default) }
                    Button("High Security") { applyPreset(.highSecurity) }
                    Button("Battery Saver") { applyPreset(.batterySaver) }
                    Button("Banking") { applyPreset(.banking) }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showCapabilities) {
                DeviceCapabilitiesView()
            }
        }
    }
    
    private var sensitivityLabel: String {
        if sensitivity < 0.3 { return "Low" }
        else if sensitivity < 0.7 { return "Medium" }
        else { return "High" }
    }
    
    private func applyPreset(_ config: PrivacyConfiguration) {
        detectionMode = config.detectionMode
        sensitivity = config.sensitivity.value
        tiltThreshold = config.tiltThreshold
        hapticFeedback = config.hapticFeedback
        debugLogging = config.debugLogging
    }
}

// MARK: - Device Capabilities View

struct DeviceCapabilitiesView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Hardware") {
                    CapabilityRow(
                        name: "Face Tracking (TrueDepth)",
                        isAvailable: DeviceCapabilities.isFaceTrackingSupported
                    )
                    CapabilityRow(
                        name: "Motion Sensors",
                        isAvailable: DeviceCapabilities.isMotionAvailable
                    )
                    CapabilityRow(
                        name: "Gyroscope",
                        isAvailable: DeviceCapabilities.isGyroscopeAvailable
                    )
                    CapabilityRow(
                        name: "Accelerometer",
                        isAvailable: DeviceCapabilities.isAccelerometerAvailable
                    )
                    CapabilityRow(
                        name: "Biometric Auth",
                        isAvailable: DeviceCapabilities.isBiometricAvailable
                    )
                }
                
                Section("Recommendation") {
                    HStack {
                        Text("Best Detection Mode")
                        Spacer()
                        Text(modeLabel(DeviceCapabilities.recommendedDetectionMode))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Supported Modes") {
                    ForEach(DeviceCapabilities.supportedDetectionModes, id: \.self) { mode in
                        Text(modeLabel(mode))
                    }
                }
            }
            .navigationTitle("Device Info")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func modeLabel(_ mode: DetectionMode) -> String {
        switch mode {
        case .faceTracking: return "Face Tracking"
        case .tiltDetection: return "Tilt Detection"
        case .combined: return "Combined"
        }
    }
}

struct CapabilityRow: View {
    let name: String
    let isAvailable: Bool
    
    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Image(systemName: isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isAvailable ? .green : .red)
        }
    }
}

// Make DetectionMode Hashable for ForEach
extension DetectionMode: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .faceTracking: hasher.combine(0)
        case .tiltDetection: hasher.combine(1)
        case .combined: hasher.combine(2)
        }
    }
    
    public static func == (lhs: DetectionMode, rhs: DetectionMode) -> Bool {
        switch (lhs, rhs) {
        case (.faceTracking, .faceTracking): return true
        case (.tiltDetection, .tiltDetection): return true
        case (.combined, .combined): return true
        default: return false
        }
    }
}

#Preview {
    SettingsView()
}
