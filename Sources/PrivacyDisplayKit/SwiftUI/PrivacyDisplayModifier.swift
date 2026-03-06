import SwiftUI
import Combine

// MARK: - Privacy Display ViewModifier

/// ViewModifier chính để áp dụng privacy display cho SwiftUI views
public struct PrivacyDisplayModifier: ViewModifier {
    
    @StateObject private var manager: PrivacyDisplayManager
    
    let mode: DetectionMode
    let overlayStyle: OverlayStyle
    let sensitivity: Sensitivity
    let tiltThreshold: Double
    let autoStart: Bool
    
    public init(
        mode: DetectionMode = .combined,
        overlay: OverlayStyle = .blur(),
        sensitivity: Sensitivity = .medium,
        tiltThreshold: Double = 30.0,
        autoStart: Bool = true
    ) {
        self.mode = mode
        self.overlayStyle = overlay
        self.sensitivity = sensitivity
        self.tiltThreshold = tiltThreshold
        self.autoStart = autoStart
        
        let config = PrivacyConfiguration(
            detectionMode: mode,
            sensitivity: sensitivity,
            tiltThreshold: tiltThreshold,
            overlayStyle: overlay
        )
        _manager = StateObject(wrappedValue: PrivacyDisplayManager(configuration: config))
    }
    
    public func body(content: Content) -> some View {
        content
            .environment(\.isPrivacyModeActive, manager.isPrivacyModeActive)
            .environment(\.privacyThreatLevel, manager.currentThreatLevel)
            .environment(\.privacyThreatIntensity, manager.threatIntensity)
            .environment(\.privacyThreatDirection, manager.threatDirection)
            .onAppear {
                if autoStart {
                    manager.start()
                }
            }
            .onDisappear {
                manager.stop()
            }
    }
}

// MARK: - Privacy Sensitive ViewModifier

/// ViewModifier để đánh dấu view chứa nội dung nhạy cảm
public struct PrivacySensitiveModifier: ViewModifier {
    
    @Environment(\.privacyThreatIntensity) private var threatIntensity
    @Environment(\.privacyThreatDirection) private var threatDirection
    
    let style: OverlayStyle
    
    public init(style: OverlayStyle = .blur(radius: 15)) {
        self.style = style
    }
    
    public func body(content: Content) -> some View {
        content
            .overlay {
                if threatIntensity > 0 {
                    PrivacyOverlayView(style: style)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .opacity(threatIntensity)
                        .mask(directionalMask)
                        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: threatIntensity)
                }
            }
    }
    
    @ViewBuilder
    private var directionalMask: some View {
        switch threatDirection {
        case .left:
            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
        case .right:
            LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
        case .top:
            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
        case .bottom:
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
        case .uniform:
            Color.black
        }
    }
}

// MARK: - View Extensions

public extension View {
    
    /// Áp dụng privacy display protection cho view
    ///
    /// ```swift
    /// ContentView()
    ///     .privacyDisplay()
    /// ```
    func privacyDisplay(
        mode: DetectionMode = .combined,
        overlay: OverlayStyle = .blur(),
        sensitivity: Sensitivity = .medium,
        tiltThreshold: Double = 30.0,
        autoStart: Bool = true
    ) -> some View {
        modifier(PrivacyDisplayModifier(
            mode: mode,
            overlay: overlay,
            sensitivity: sensitivity,
            tiltThreshold: tiltThreshold,
            autoStart: autoStart
        ))
    }
    
    /// Đánh dấu view này chứa nội dung nhạy cảm
    /// Chỉ hoạt động khi view cha đã áp dụng `.privacyDisplay()`
    ///
    /// ```swift
    /// Text("Secret: 1234-5678")
    ///     .privacySensitive()
    /// ```
    func privacySensitive(style: OverlayStyle = .blur(radius: 15)) -> some View {
        modifier(PrivacySensitiveModifier(style: style))
    }
}
