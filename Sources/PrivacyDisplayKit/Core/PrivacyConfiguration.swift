import Foundation
import UIKit

/// Cấu hình cho hệ thống Privacy Display
public struct PrivacyConfiguration: Sendable {
    
    // MARK: - Detection Settings
    
    /// Chế độ phát hiện: face tracking, tilt, hoặc kết hợp
    public var detectionMode: DetectionMode
    
    /// Mức độ nhạy của hệ thống phát hiện
    public var sensitivity: Sensitivity
    
    // MARK: - Tilt Settings
    
    /// Ngưỡng góc nghiêng để kích hoạt privacy mode (tính bằng độ)
    /// Default: 30°
    public var tiltThreshold: Double
    
    /// Bật adaptive tilt — hệ thống sẽ học vị trí "bình thường" của user
    public var adaptiveTilt: Bool
    
    // MARK: - Face Tracking Settings
    
    /// Số khuôn mặt tối đa cho phép trước khi kích hoạt privacy mode
    /// Default: 1 (chỉ cho phép 1 khuôn mặt - chủ sở hữu)
    public var maxAllowedFaces: Int
    
    /// Timeout khi không phát hiện khuôn mặt chủ sở hữu (giây)
    /// Default: 3.0 giây
    public var faceAbsenceTimeout: TimeInterval
    
    /// Frame rate cho face tracking (frames per second)
    /// Giảm để tiết kiệm pin. Default: 15
    public var faceTrackingFPS: Int
    
    // MARK: - Overlay Settings
    
    /// Kiểu hiệu ứng overlay
    public var overlayStyle: OverlayStyle
    
    /// Thời gian delay trước khi kích hoạt overlay (giây)
    /// Tránh false positives. Default: 0.5
    public var activationDelay: TimeInterval
    
    /// Thời gian delay trước khi tắt overlay (giây)
    /// Default: 1.0
    public var deactivationDelay: TimeInterval
    
    /// Thời gian animation cho overlay transition (giây)
    /// Default: 0.3
    public var animationDuration: TimeInterval
    
    // MARK: - Behavior Settings
    
    /// Tự động tạm dừng khi app vào background
    /// Default: true
    public var pauseInBackground: Bool
    
    /// Bật haptic feedback khi privacy mode thay đổi
    /// Default: true
    public var hapticFeedback: Bool
    
    /// Bật logging cho debug
    /// Default: false
    public var debugLogging: Bool
    
    // MARK: - Initialization
    
    public init(
        detectionMode: DetectionMode = .combined,
        sensitivity: Sensitivity = .medium,
        tiltThreshold: Double = 30.0,
        adaptiveTilt: Bool = true,
        maxAllowedFaces: Int = 1,
        faceAbsenceTimeout: TimeInterval = 3.0,
        faceTrackingFPS: Int = 15,
        overlayStyle: OverlayStyle = .blur(),
        activationDelay: TimeInterval = 0.5,
        deactivationDelay: TimeInterval = 1.0,
        animationDuration: TimeInterval = 0.3,
        pauseInBackground: Bool = true,
        hapticFeedback: Bool = true,
        debugLogging: Bool = false
    ) {
        self.detectionMode = detectionMode
        self.sensitivity = sensitivity
        self.tiltThreshold = tiltThreshold
        self.adaptiveTilt = adaptiveTilt
        self.maxAllowedFaces = maxAllowedFaces
        self.faceAbsenceTimeout = faceAbsenceTimeout
        self.faceTrackingFPS = faceTrackingFPS
        self.overlayStyle = overlayStyle
        self.activationDelay = activationDelay
        self.deactivationDelay = deactivationDelay
        self.animationDuration = animationDuration
        self.pauseInBackground = pauseInBackground
        self.hapticFeedback = hapticFeedback
        self.debugLogging = debugLogging
    }
    
    // MARK: - Presets
    
    /// Cấu hình mặc định — cân bằng giữa bảo mật và hiệu năng
    public static let `default` = PrivacyConfiguration()
    
    /// Cấu hình bảo mật cao — nhạy hơn, phản ứng nhanh hơn
    public static let highSecurity = PrivacyConfiguration(
        sensitivity: .high,
        tiltThreshold: 20.0,
        maxAllowedFaces: 1,
        faceAbsenceTimeout: 1.5,
        overlayStyle: .blurAndDim(),
        activationDelay: 0.2,
        deactivationDelay: 1.5
    )
    
    /// Cấu hình tiết kiệm pin — chỉ dùng tilt detection
    public static let batterySaver = PrivacyConfiguration(
        detectionMode: .tiltDetection,
        sensitivity: .low,
        tiltThreshold: 35.0,
        overlayStyle: .dim(),
        activationDelay: 1.0,
        deactivationDelay: 0.5
    )
    
    /// Cấu hình cho banking apps — bảo mật tối đa
    public static let banking = PrivacyConfiguration(
        detectionMode: .combined,
        sensitivity: .high,
        tiltThreshold: 15.0,
        maxAllowedFaces: 1,
        faceAbsenceTimeout: 1.0,
        faceTrackingFPS: 30,
        overlayStyle: .blurAndDim(blurRadius: 25, dimOpacity: 0.7),
        activationDelay: 0.1,
        deactivationDelay: 2.0,
        hapticFeedback: true
    )
}
