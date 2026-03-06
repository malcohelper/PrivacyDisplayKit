import SwiftUI

/// Custom EnvironmentKey cho privacy state
private struct PrivacyModeActiveKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct PrivacyThreatLevelKey: EnvironmentKey {
    static let defaultValue: ThreatLevel = .none
}

private struct PrivacyThreatIntensityKey: EnvironmentKey {
    static let defaultValue: Double = 0.0
}

private struct PrivacyThreatDirectionKey: EnvironmentKey {
    static let defaultValue: ThreatDirection = .uniform
}

public extension EnvironmentValues {
    /// Privacy mode hiện đang active hay không
    var isPrivacyModeActive: Bool {
        get { self[PrivacyModeActiveKey.self] }
        set { self[PrivacyModeActiveKey.self] = newValue }
    }
    
    /// Cấp độ đe dọa hiện tại
    var privacyThreatLevel: ThreatLevel {
        get { self[PrivacyThreatLevelKey.self] }
        set { self[PrivacyThreatLevelKey.self] = newValue }
    }
    
    /// Cường độ che phủ hiện tại (0.0 -> 1.0)
    var privacyThreatIntensity: Double {
        get { self[PrivacyThreatIntensityKey.self] }
        set { self[PrivacyThreatIntensityKey.self] = newValue }
    }
    
    /// Hướng che phủ hiện tại
    var privacyThreatDirection: ThreatDirection {
        get { self[PrivacyThreatDirectionKey.self] }
        set { self[PrivacyThreatDirectionKey.self] = newValue }
    }
}
