import Foundation
import ARKit

/// Models cho Face Tracking module
public struct FaceTrackingResult: Sendable {
    /// Số khuôn mặt phát hiện được
    public let faceCount: Int
    /// Góc nhìn của khuôn mặt chính (euler angles)
    public let faceAngle: FaceAngle?
    /// Khoảng cách ước tính từ khuôn mặt đến camera (mét)
    public let estimatedDistance: Float?
    /// Thời điểm phát hiện
    public let timestamp: TimeInterval
}

/// Góc khuôn mặt (Euler angles)
public struct FaceAngle: Sendable {
    /// Góc xoay trái/phải (yaw) — radian
    public let yaw: Float
    /// Góc ngẩng lên/cúi xuống (pitch) — radian
    public let pitch: Float
    /// Góc nghiêng đầu (roll) — radian
    public let roll: Float
    
    /// Góc yaw tính bằng độ
    public var yawDegrees: Float { yaw * 180 / .pi }
    /// Góc pitch tính bằng độ
    public var pitchDegrees: Float { pitch * 180 / .pi }
    /// Góc roll tính bằng độ
    public var rollDegrees: Float { roll * 180 / .pi }
}

/// Trạng thái face tracking
public enum FaceTrackingState: Sendable {
    case idle
    case starting
    case tracking
    case noFaceDetected
    case multipleFacesDetected(count: Int)
    case suspiciousAngle(angle: FaceAngle)
    case error(PrivacyError)
}
