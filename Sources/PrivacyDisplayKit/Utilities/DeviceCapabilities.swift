import Foundation
import ARKit
import CoreMotion
import LocalAuthentication

/// Kiểm tra khả năng phần cứng của thiết bị
public struct DeviceCapabilities {
    
    /// Thiết bị hỗ trợ ARKit face tracking (TrueDepth camera)
    public static var isFaceTrackingSupported: Bool {
        return ARFaceTrackingConfiguration.isSupported
    }
    
    /// Cảm biến motion (gyroscope + accelerometer) khả dụng
    public static var isMotionAvailable: Bool {
        let manager = CMMotionManager()
        return manager.isDeviceMotionAvailable
    }
    
    /// Gyroscope khả dụng
    public static var isGyroscopeAvailable: Bool {
        let manager = CMMotionManager()
        return manager.isGyroAvailable
    }
    
    /// Accelerometer khả dụng
    public static var isAccelerometerAvailable: Bool {
        let manager = CMMotionManager()
        return manager.isAccelerometerAvailable
    }
    
    /// Face ID / Biometric authentication khả dụng
    public static var isBiometricAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Loại biometric authentication
    public static var biometricType: LABiometryType {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return context.biometryType
    }
    
    /// Tổng hợp các chế độ detection được hỗ trợ
    public static var supportedDetectionModes: [DetectionMode] {
        var modes: [DetectionMode] = []
        
        if isFaceTrackingSupported {
            modes.append(.faceTracking)
        }
        
        if isMotionAvailable {
            modes.append(.tiltDetection)
        }
        
        if isFaceTrackingSupported && isMotionAvailable {
            modes.append(.combined)
        }
        
        return modes
    }
    
    /// Chế độ detection tốt nhất được đề xuất cho thiết bị
    public static var recommendedDetectionMode: DetectionMode {
        if isFaceTrackingSupported && isMotionAvailable {
            return .combined
        } else if isFaceTrackingSupported {
            return .faceTracking
        } else if isMotionAvailable {
            return .tiltDetection
        } else {
            return .tiltDetection // Fallback
        }
    }
    
    /// In thông tin debug về capabilities
    public static func printCapabilities() {
        PrivacyLogger.log("""
        Device Capabilities:
        - Face Tracking: \(isFaceTrackingSupported)
        - Motion Sensors: \(isMotionAvailable)
        - Gyroscope: \(isGyroscopeAvailable)
        - Accelerometer: \(isAccelerometerAvailable)
        - Biometric: \(isBiometricAvailable) (\(biometricType))
        - Recommended Mode: \(recommendedDetectionMode)
        """, level: .info)
    }
}
