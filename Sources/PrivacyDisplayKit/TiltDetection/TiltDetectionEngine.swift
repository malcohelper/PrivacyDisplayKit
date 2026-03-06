import Foundation
import CoreMotion

/// Engine phát hiện góc nghiêng thiết bị sử dụng CoreMotion
public final class TiltDetectionEngine: DetectionEngine {
    
    // MARK: - DetectionEngine Protocol
    
    public var onThreatDetected: ((ThreatLevel) -> Void)?
    public var onThreatIntensityUpdated: ((Double, ThreatDirection) -> Void)?
    public var onError: ((PrivacyError) -> Void)?
    public private(set) var isRunning: Bool = false
    
    // MARK: - Public Callbacks
    
    /// Callback khi trạng thái thay đổi
    public var onStateChanged: ((TiltState) -> Void)?
    
    /// Callback khi góc nghiêng cập nhật
    public var onTiltUpdated: ((TiltAngle) -> Void)?
    
    // MARK: - Configuration
    
    private let threshold: Double // degrees
    private let sensitivity: Sensitivity
    private let adaptive: Bool
    
    // MARK: - Core Motion
    
    private let motionManager = CMMotionManager()
    private let operationQueue = OperationQueue()
    
    // MARK: - Adaptive Calibration
    
    /// Vị trí "bình thường" — baseline mà user hay giữ điện thoại
    private var baselinePitch: Double = 0
    private var baselineRoll: Double = 0
    private var calibrationSamples: [(pitch: Double, roll: Double)] = []
    private let calibrationSampleCount = 30 // ~1 giây data
    private var isCalibrated = false
    
    // MARK: - Smoothing
    
    private var smoothedPitch: Double = 0
    private var smoothedRoll: Double = 0
    private let smoothingFactor: Double = 0.15 // Low-pass filter alpha
    
    // MARK: - Update Interval
    
    /// Tần suất cập nhật sensor (giây)
    private let updateInterval: TimeInterval = 1.0 / 30.0 // 30 Hz
    
    // MARK: - Initialization
    
    public init(
        threshold: Double = 30.0,
        sensitivity: Sensitivity = .medium,
        adaptive: Bool = true
    ) {
        self.threshold = threshold
        self.sensitivity = sensitivity
        self.adaptive = adaptive
        
        operationQueue.name = "com.privacydisplaykit.tilt"
        operationQueue.maxConcurrentOperationCount = 1
    }
    
    // MARK: - DetectionEngine
    
    public func start() throws {
        guard motionManager.isDeviceMotionAvailable else {
            throw PrivacyError.motionSensorsNotAvailable
        }
        
        motionManager.deviceMotionUpdateInterval = updateInterval
        
        // Reset calibration
        if adaptive {
            isCalibrated = false
            calibrationSamples.removeAll()
            onStateChanged?(.calibrating)
            PrivacyLogger.log("TiltDetection: Starting calibration...")
        }
        
        motionManager.startDeviceMotionUpdates(
            using: .xArbitraryZVertical,
            to: operationQueue
        ) { [weak self] motion, error in
            guard let self = self else { return }
            
            if let error = error {
                PrivacyLogger.log("CoreMotion error: \(error.localizedDescription)", level: .error)
                self.onError?(.unknown("CoreMotion: \(error.localizedDescription)"))
                return
            }
            
            guard let motion = motion else { return }
            self.processMotionData(motion)
        }
        
        isRunning = true
        PrivacyLogger.log("TiltDetectionEngine started (threshold: \(threshold)°, adaptive: \(adaptive))")
    }
    
    public func stop() {
        motionManager.stopDeviceMotionUpdates()
        isRunning = false
        isCalibrated = false
        calibrationSamples.removeAll()
        
        onStateChanged?(.idle)
        PrivacyLogger.log("TiltDetectionEngine stopped")
    }
    
    // MARK: - Recalibrate
    
    /// Recalibrate baseline — gọi khi user thay đổi tư thế
    public func recalibrate() {
        isCalibrated = false
        calibrationSamples.removeAll()
        onStateChanged?(.calibrating)
        PrivacyLogger.log("TiltDetection: Recalibrating...")
    }
    
    // MARK: - Motion Processing
    
    private func processMotionData(_ motion: CMDeviceMotion) {
        let attitude = motion.attitude
        let currentPitch = attitude.pitch
        let currentRoll = attitude.roll
        
        // Low-pass filter để giảm noise
        smoothedPitch = smoothedPitch * (1 - smoothingFactor) + currentPitch * smoothingFactor
        smoothedRoll = smoothedRoll * (1 - smoothingFactor) + currentRoll * smoothingFactor
        
        // Adaptive calibration
        if adaptive && !isCalibrated {
            performCalibration(pitch: smoothedPitch, roll: smoothedRoll)
            return
        }
        
        // Tính góc nghiêng relative to baseline
        let relativePitch: Double
        let relativeRoll: Double
        
        if adaptive && isCalibrated {
            relativePitch = smoothedPitch - baselinePitch
            relativeRoll = smoothedRoll - baselineRoll
        } else {
            relativePitch = smoothedPitch
            relativeRoll = smoothedRoll
        }
        
        let tiltAngle = TiltAngle(
            pitch: relativePitch,
            roll: relativeRoll,
            yaw: attitude.yaw
        )
        
        onTiltUpdated?(tiltAngle)
        
        // Đánh giá mối đe dọa
        evaluateTilt(tiltAngle)
    }
    
    private func performCalibration(pitch: Double, roll: Double) {
        calibrationSamples.append((pitch: pitch, roll: roll))
        
        if calibrationSamples.count >= calibrationSampleCount {
            // Tính trung bình
            let avgPitch = calibrationSamples.reduce(0.0) { $0 + $1.pitch } / Double(calibrationSamples.count)
            let avgRoll = calibrationSamples.reduce(0.0) { $0 + $1.roll } / Double(calibrationSamples.count)
            
            baselinePitch = avgPitch
            baselineRoll = avgRoll
            isCalibrated = true
            
            onStateChanged?(.monitoring)
            PrivacyLogger.log("TiltDetection: Calibrated — baseline pitch: \(String(format: "%.1f", avgPitch * 180 / .pi))°, roll: \(String(format: "%.1f", avgRoll * 180 / .pi))°")
        }
    }
    
    private func evaluateTilt(_ tiltAngle: TiltAngle) {
        let totalTilt = tiltAngle.totalTiltDegrees
        
        // Điều chỉnh threshold dựa trên sensitivity
        let adjustedThreshold = threshold * (1.0 - sensitivity.value * 0.5)
        // sensitivity.high (0.8) → threshold * 0.6
        // sensitivity.medium (0.5) → threshold * 0.75
        // Tính toán cường độ mờ dần (0.0 -> 1.0)
        let startFade = adjustedThreshold * 0.4
        let endFade = adjustedThreshold * 0.85
        
        let intensity: Double
        if totalTilt <= startFade {
            intensity = 0.0
        } else if totalTilt >= endFade {
            intensity = 1.0
        } else {
            intensity = (totalTilt - startFade) / (endFade - startFade)
        }
        
        let level: ThreatLevel
        if totalTilt < adjustedThreshold * 0.5 {
            level = .none
            onStateChanged?(.monitoring)
        } else if totalTilt < adjustedThreshold * 0.75 {
            level = .low
            onStateChanged?(.tilted(angle: tiltAngle))
        } else if totalTilt < adjustedThreshold {
            level = .medium
            onStateChanged?(.tilted(angle: tiltAngle))
        } else if totalTilt < adjustedThreshold * 1.5 {
            level = .high
            onStateChanged?(.tilted(angle: tiltAngle))
        } else {
            level = .critical
            onStateChanged?(.tilted(angle: tiltAngle))
        }
        
        let direction: ThreatDirection
        if abs(tiltAngle.rollDegrees) > abs(tiltAngle.pitchDegrees) {
            direction = tiltAngle.rollDegrees > 0 ? .right : .left
        } else {
            direction = tiltAngle.pitchDegrees > 0 ? .top : .bottom
        }
        
        onThreatIntensityUpdated?(intensity, direction)
        onThreatDetected?(level)
    }
}
