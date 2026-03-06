import Foundation
import UIKit

// MARK: - Detection Mode

/// Chế độ phát hiện mối đe dọa quyền riêng tư
public enum DetectionMode: Sendable {
    /// Sử dụng TrueDepth camera để theo dõi khuôn mặt
    case faceTracking
    /// Sử dụng gyroscope/accelerometer để phát hiện góc nghiêng
    case tiltDetection
    /// Kết hợp cả hai phương pháp
    case combined
}

// MARK: - Overlay Style

/// Kiểu hiệu ứng che phủ khi privacy mode được kích hoạt
public enum OverlayStyle: Sendable {
    /// Hiệu ứng blur Gaussian
    case blur(radius: CGFloat = 20)
    /// Hiệu ứng tối mờ
    case dim(opacity: Double = 0.85)
    /// Hiệu ứng nhiễu (noise pattern)
    case noise
    /// Hiệu ứng gradient từ rìa
    case gradient
    /// Kết hợp blur và dim
    case blurAndDim(blurRadius: CGFloat = 15, dimOpacity: Double = 0.5)
    /// Custom overlay view
    case custom
}

// MARK: - Sensitivity

/// Mức độ nhạy của hệ thống phát hiện
public enum Sensitivity: Sendable {
    case low
    case medium
    case high
    /// Giá trị tùy chỉnh từ 0.0 đến 1.0
    case custom(Double)
    
    public var value: Double {
        switch self {
        case .low: return 0.3
        case .medium: return 0.5
        case .high: return 0.8
        case .custom(let val): return min(max(val, 0.0), 1.0)
        }
    }
}

// MARK: - Threat Level

/// Cấp độ mối đe dọa quyền riêng tư hiện tại
public enum ThreatLevel: Int, Comparable, Sendable {
    /// Không có mối đe dọa
    case none = 0
    /// Mức thấp — thiết bị nghiêng nhẹ
    case low = 1
    /// Mức trung bình — có dấu hiệu đáng ngờ
    case medium = 2
    /// Mức cao — phát hiện rõ ràng người nhìn trộm
    case high = 3
    /// Mức nguy hiểm — nhiều người nhìn hoặc góc nghiêng quá lớn
    case critical = 4
    
    public static func < (lhs: ThreatLevel, rhs: ThreatLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Threat Direction

/// Hướng của mối đe dọa (ví dụ thiết bị bị nghiêng sang trái, hoặc có người nhìn từ bên phải)
public enum ThreatDirection: Sendable, Equatable {
    case left
    case right
    case top
    case bottom
    case uniform // Không xác định hướng, che toàn bộ
}

// MARK: - Privacy State

/// Trạng thái hoạt động của hệ thống privacy display
public enum PrivacyState: Sendable {
    /// Hệ thống đang tắt
    case inactive
    /// Đang khởi động / chuẩn bị sensors
    case initializing
    /// Đang giám sát, chưa phát hiện mối đe dọa
    case monitoring
    /// Privacy overlay đang hiển thị
    case activated
    /// Tạm dừng (app vào background, v.v.)
    case paused
    /// Lỗi xảy ra
    case error(PrivacyError)
}

// MARK: - Privacy Error

/// Các lỗi có thể xảy ra trong hệ thống
public enum PrivacyError: Error, Sendable {
    /// Thiết bị không hỗ trợ TrueDepth camera
    case faceTrackingNotSupported
    /// Thiết bị không hỗ trợ cảm biến motion
    case motionSensorsNotAvailable
    /// Người dùng từ chối quyền truy cập camera
    case cameraPermissionDenied
    /// Người dùng từ chối quyền truy cập motion sensors
    case motionPermissionDenied
    /// Face ID / biometric không khả dụng
    case biometricNotAvailable
    /// Lỗi cấu hình
    case invalidConfiguration(String)
    /// Lỗi không xác định
    case unknown(String)
}

extension PrivacyError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .faceTrackingNotSupported:
            return "Device does not support face tracking (TrueDepth camera required)"
        case .motionSensorsNotAvailable:
            return "Motion sensors are not available on this device"
        case .cameraPermissionDenied:
            return "Camera permission was denied"
        case .motionPermissionDenied:
            return "Motion sensor permission was denied"
        case .biometricNotAvailable:
            return "Biometric authentication is not available"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - Privacy Display Delegate

/// Protocol delegate nhận thông báo từ PrivacyDisplayManager
public protocol PrivacyDisplayDelegate: AnyObject {
    /// Được gọi khi trạng thái privacy thay đổi
    func privacyDisplay(didChangeState state: PrivacyState)
    /// Được gọi khi mức đe dọa (cấp độ) thay đổi
    func privacyDisplay(didChangeThreatLevel level: ThreatLevel)
    /// Được gọi khi mức độ che phủ hoặc hướng đe dọa thay đổi
    func privacyDisplay(didChangeThreatIntensity intensity: Double, direction: ThreatDirection)
    /// Được gọi khi privacy overlay được kích hoạt
    func privacyDisplayDidActivate()
    /// Được gọi khi privacy overlay được tắt
    func privacyDisplayDidDeactivate()
    /// Được gọi khi có lỗi xảy ra
    func privacyDisplay(didEncounterError error: PrivacyError)
}

/// Default implementations cho delegate methods (tất cả optional)
public extension PrivacyDisplayDelegate {
    func privacyDisplay(didChangeState state: PrivacyState) {}
    func privacyDisplay(didChangeThreatLevel level: ThreatLevel) {}
    func privacyDisplay(didChangeThreatIntensity intensity: Double, direction: ThreatDirection) {}
    func privacyDisplayDidActivate() {}
    func privacyDisplayDidDeactivate() {}
    func privacyDisplay(didEncounterError error: PrivacyError) {}
}

// MARK: - Detection Engine Protocol

/// Protocol chung cho các engine phát hiện
public protocol DetectionEngine: AnyObject {
    /// Bắt đầu phát hiện
    func start() throws
    /// Dừng phát hiện
    func stop()
    /// Callback khi phát hiện dời mức đe dọa
    var onThreatDetected: ((ThreatLevel) -> Void)? { get set }
    /// Callback khi mức độ che phủ hoặc hướng thay đổi
    var onThreatIntensityUpdated: ((Double, ThreatDirection) -> Void)? { get set }
    /// Callback khi có lỗi
    var onError: ((PrivacyError) -> Void)? { get set }
    /// Trạng thái hoạt động
    var isRunning: Bool { get }
}
