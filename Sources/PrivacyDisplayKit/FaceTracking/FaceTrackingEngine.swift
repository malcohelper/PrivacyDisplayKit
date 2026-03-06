import Foundation
import ARKit

/// Engine phát hiện khuôn mặt sử dụng ARKit TrueDepth camera
public final class FaceTrackingEngine: NSObject, DetectionEngine {
    
    // MARK: - DetectionEngine Protocol
    
    public var onThreatDetected: ((ThreatLevel) -> Void)?
    public var onThreatIntensityUpdated: ((Double, ThreatDirection) -> Void)?
    public var onError: ((PrivacyError) -> Void)?
    public private(set) var isRunning: Bool = false
    
    // MARK: - Public Callbacks
    
    /// Callback khi trạng thái face tracking thay đổi
    public var onStateChanged: ((FaceTrackingState) -> Void)?
    
    /// Callback khi có kết quả tracking mới
    public var onTrackingResult: ((FaceTrackingResult) -> Void)?
    
    // MARK: - Configuration
    
    private let maxAllowedFaces: Int
    private let absenceTimeout: TimeInterval
    private let targetFPS: Int
    
    // MARK: - ARKit
    
    private var arSession: ARSession?
    private var lastFaceDetectedTime: TimeInterval = 0
    private var absenceTimer: Timer?
    private var currentFaceCount: Int = 0
    
    // MARK: - Initialization
    
    public init(
        maxAllowedFaces: Int = 1,
        absenceTimeout: TimeInterval = 3.0,
        targetFPS: Int = 15
    ) {
        self.maxAllowedFaces = maxAllowedFaces
        self.absenceTimeout = absenceTimeout
        self.targetFPS = targetFPS
        super.init()
    }
    
    // MARK: - DetectionEngine
    
    public func start() throws {
        guard ARFaceTrackingConfiguration.isSupported else {
            throw PrivacyError.faceTrackingNotSupported
        }
        
        let session = ARSession()
        session.delegate = self
        
        let configuration = ARFaceTrackingConfiguration()
        if ARFaceTrackingConfiguration.supportsWorldTracking {
            configuration.isWorldTrackingEnabled = true
        }
        configuration.maximumNumberOfTrackedFaces = min(ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces, 3)
        
        // Điều chỉnh frame rate
        if targetFPS < 60 {
            // ARKit tự quản lý frame rate, nhưng ta sẽ sample ở delegate
        }
        
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        self.arSession = session
        self.isRunning = true
        self.lastFaceDetectedTime = CACurrentMediaTime()
        
        startAbsenceTimer()
        onStateChanged?(.starting)
        
        PrivacyLogger.log("FaceTrackingEngine started")
    }
    
    public func stop() {
        arSession?.pause()
        arSession = nil
        absenceTimer?.invalidate()
        absenceTimer = nil
        isRunning = false
        currentFaceCount = 0
        
        onStateChanged?(.idle)
        PrivacyLogger.log("FaceTrackingEngine stopped")
    }
    
    // MARK: - Absence Detection
    
    private func startAbsenceTimer() {
        absenceTimer?.invalidate()
        absenceTimer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: true
        ) { [weak self] _ in
            self?.checkFaceAbsence()
        }
    }
    
    private func checkFaceAbsence() {
        let elapsed = CACurrentMediaTime() - lastFaceDetectedTime
        
        if elapsed > absenceTimeout && currentFaceCount == 0 {
            PrivacyLogger.log("No face detected for \(String(format: "%.1f", elapsed))s")
            onStateChanged?(.noFaceDetected)
            onThreatDetected?(.medium)
            onThreatIntensityUpdated?(1.0, .uniform)
        }
    }
    
    // MARK: - Face Analysis
    
    private func analyzeFaceAnchors(_ anchors: [ARFaceAnchor]) {
        let faceCount = anchors.count
        currentFaceCount = faceCount
        
        if faceCount > 0 {
            lastFaceDetectedTime = CACurrentMediaTime()
        }
        
        // Lấy thông tin khuôn mặt chính (đầu tiên)
        let primaryFace = anchors.first
        let faceAngle: FaceAngle? = primaryFace.map { anchor in
            let euler = anchor.transform.eulerAngles
            return FaceAngle(yaw: euler.y, pitch: euler.x, roll: euler.z)
        }
        
        // Ước tính khoảng cách
        let distance: Float? = primaryFace.map { anchor in
            let position = anchor.transform.columns.3
            return sqrt(position.x * position.x + position.y * position.y + position.z * position.z)
        }
        
        let result = FaceTrackingResult(
            faceCount: faceCount,
            faceAngle: faceAngle,
            estimatedDistance: distance,
            timestamp: CACurrentMediaTime()
        )
        
        onTrackingResult?(result)
        
        // Đánh giá mối đe dọa
        evaluateThreat(faceCount: faceCount, faceAngle: faceAngle)
    }
    
    private func evaluateThreat(faceCount: Int, faceAngle: FaceAngle?) {
        // Phát hiện nhiều khuôn mặt -> uniform blur
        if faceCount > maxAllowedFaces {
            PrivacyLogger.log("Multiple faces detected: \(faceCount)")
            onStateChanged?(.multipleFacesDetected(count: faceCount))
            
            let level: ThreatLevel = faceCount > maxAllowedFaces + 1 ? .critical : .high
            onThreatDetected?(level)
            onThreatIntensityUpdated?(1.0, .uniform)
            return
        }
        
        // Kiểm tra góc nhìn đáng ngờ
        if let angle = faceAngle {
            let absYaw = abs(angle.yawDegrees)
            let absPitch = abs(angle.pitchDegrees)
            
            // Tính toán cường độ mờ dần dựa trên góc nghiêng khuôn mặt
            let maxAngle = max(absYaw, absPitch)
            let startFade: Float = 20.0
            let endFade: Float = 35.0
            
            let intensity: Double
            if maxAngle <= startFade {
                intensity = 0.0
            } else if maxAngle >= endFade {
                intensity = 1.0
            } else {
                intensity = Double((maxAngle - startFade) / (endFade - startFade))
            }
            
            let direction: ThreatDirection
            if abs(angle.yawDegrees) > abs(angle.pitchDegrees) {
                // yaw âm => mặt quay sang phải (viewed from phone perspective) => nhìn trộm từ bên trái màn hình
                // yaw dương => mặt quay sang trái => nhìn trộm từ bên phải
                direction = angle.yawDegrees > 0 ? .right : .left
            } else {
                // pitch âm => ngẩng đầu => nhìn từ dưới
                // pitch dương => cúi đầu => nhìn từ trên
                direction = angle.pitchDegrees > 0 ? .top : .bottom
            }
            
            onThreatIntensityUpdated?(intensity, direction)
            
            // Khuôn mặt nghiêng quá nhiều — có thể là ai đó nhìn từ góc
            if absYaw > 35 || absPitch > 30 {
                onStateChanged?(.suspiciousAngle(angle: angle))
                
                let level: ThreatLevel
                if maxAngle > 50 { level = .high }
                else if maxAngle > 40 { level = .medium }
                else { level = .low }
                
                onThreatDetected?(level)
                return
            }
        }
        
        // Không có mối đe dọa
        if faceCount >= 1 {
            onStateChanged?(.tracking)
            onThreatDetected?(.none)
            onThreatIntensityUpdated?(0.0, .uniform)
        }
    }
}

// MARK: - ARSessionDelegate

extension FaceTrackingEngine: ARSessionDelegate {
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Rate limiting dựa trên targetFPS
        // ARSession callback tự động, ta chỉ process theo frame mong muốn
    }
    
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        let faceAnchors = anchors.compactMap { $0 as? ARFaceAnchor }
        if !faceAnchors.isEmpty {
            analyzeFaceAnchors(faceAnchors)
        }
    }
    
    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        let faceAnchors = anchors.compactMap { $0 as? ARFaceAnchor }
        if !faceAnchors.isEmpty {
            analyzeFaceAnchors(faceAnchors)
        }
    }
    
    public func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        let faceAnchors = anchors.compactMap { $0 as? ARFaceAnchor }
        if !faceAnchors.isEmpty {
            currentFaceCount = max(0, currentFaceCount - faceAnchors.count)
            if currentFaceCount == 0 {
                PrivacyLogger.log("All faces lost")
            }
        }
    }
    
    public func session(_ session: ARSession, didFailWithError error: Error) {
        PrivacyLogger.log("ARSession error: \(error.localizedDescription)", level: .error)
        onError?(.unknown("ARSession failed: \(error.localizedDescription)"))
        onStateChanged?(.error(.unknown(error.localizedDescription)))
    }
}

// MARK: - simd_float4x4 Extension

private extension simd_float4x4 {
    var eulerAngles: SIMD3<Float> {
        let pitch = asin(-self[2][0])
        let yaw: Float
        let roll: Float
        
        if cos(pitch) > 0.0001 {
            yaw = atan2(self[2][1], self[2][2])
            roll = atan2(self[1][0], self[0][0])
        } else {
            yaw = 0
            roll = atan2(-self[0][1], self[1][1])
        }
        
        return SIMD3<Float>(pitch, yaw, roll)
    }
}
