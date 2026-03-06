import Foundation
import CoreMotion

/// Góc nghiêng thiết bị
public struct TiltAngle: Sendable {
    /// Góc nghiêng trục X (pitch) — radian
    public let pitch: Double
    /// Góc nghiêng trục Y (roll) — radian
    public let roll: Double
    /// Góc nghiêng trục Z (yaw) — radian
    public let yaw: Double
    
    /// Pitch tính bằng độ
    public var pitchDegrees: Double { pitch * 180 / .pi }
    /// Roll tính bằng độ
    public var rollDegrees: Double { roll * 180 / .pi }
    /// Yaw tính bằng độ
    public var yawDegrees: Double { yaw * 180 / .pi }
    
    /// Tổng góc nghiêng từ vị trí thẳng đứng (độ)
    public var totalTiltDegrees: Double {
        let totalRadians = sqrt(pitch * pitch + roll * roll)
        return totalRadians * 180 / .pi
    }
}

/// Trạng thái tilt detection
public enum TiltState: Sendable {
    case idle
    case calibrating
    case monitoring
    case tilted(angle: TiltAngle)
    case error(PrivacyError)
}
