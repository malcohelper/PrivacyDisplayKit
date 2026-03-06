import Foundation
import Combine
import UIKit

/// Manager chính điều phối toàn bộ hệ thống Privacy Display
///
/// Sử dụng:
/// ```swift
/// // Cách 1: Singleton
/// PrivacyDisplayManager.shared.start()
///
/// // Cách 2: Custom instance
/// let manager = PrivacyDisplayManager(configuration: .banking)
/// manager.start()
/// ```
@MainActor
public final class PrivacyDisplayManager: ObservableObject {
    
    // MARK: - Singleton
    
    /// Shared instance với cấu hình mặc định
    public static let shared = PrivacyDisplayManager()
    
    // MARK: - Published Properties
    
    /// Privacy mode hiện đang active hay không
    @Published public private(set) var isPrivacyModeActive: Bool = false
    
    /// Cấp độ đe dọa hiện tại
    @Published public private(set) var currentThreatLevel: ThreatLevel = .none
    
    /// Mức độ che phủ (từ 0.0 đến 1.0) để tạo hiệu ứng mượt mà
    @Published public private(set) var threatIntensity: Double = 0.0
    
    /// Hướng che phủ
    @Published public private(set) var threatDirection: ThreatDirection = .uniform
    
    /// Trạng thái hệ thống
    @Published public private(set) var currentState: PrivacyState = .inactive
    
    // MARK: - Properties
    
    /// Cấu hình hiện tại
    public private(set) var configuration: PrivacyConfiguration
    
    /// Delegate nhận thông báo
    public weak var delegate: PrivacyDisplayDelegate?
    
    // MARK: - Internal Components
    
    private var faceTrackingEngine: FaceTrackingEngine?
    private var tiltDetectionEngine: TiltDetectionEngine?
    private var overlayRenderer: PrivacyOverlayRenderer?
    
    private var cancellables = Set<AnyCancellable>()
    private var activationTimer: Timer?
    private var deactivationTimer: Timer?
    private var hapticGenerator: UINotificationFeedbackGenerator?
    
    // MARK: - Initialization
    
    public init(configuration: PrivacyConfiguration = .default) {
        self.configuration = configuration
        setupNotifications()
    }
    
    // MARK: - Public API
    
    /// Bắt đầu giám sát privacy với cấu hình hiện tại
    public func start() {
        start(with: configuration)
    }
    
    /// Bắt đầu giám sát privacy với cấu hình mới
    public func start(with config: PrivacyConfiguration) {
        guard case .inactive = currentState else {
            PrivacyLogger.log("Manager already running, call stop() first", level: .warning)
            return
        }
        
        self.configuration = config
        updateState(.initializing)
        
        PrivacyLogger.isEnabled = config.debugLogging
        PrivacyLogger.log("Starting PrivacyDisplayManager with mode: \(config.detectionMode)")
        
        if config.hapticFeedback {
            hapticGenerator = UINotificationFeedbackGenerator()
            hapticGenerator?.prepare()
        }
        
        setupEngines()
        startEngines()
    }
    
    /// Dừng hoàn toàn hệ thống
    public func stop() {
        PrivacyLogger.log("Stopping PrivacyDisplayManager")
        
        stopEngines()
        deactivatePrivacyMode(animated: false)
        
        faceTrackingEngine = nil
        tiltDetectionEngine = nil
        
        activationTimer?.invalidate()
        deactivationTimer?.invalidate()
        activationTimer = nil
        deactivationTimer = nil
        hapticGenerator = nil
        
        updateState(.inactive)
        currentThreatLevel = .none
        threatIntensity = 0.0
        threatDirection = .uniform
    }
    
    /// Tạm dừng giám sát (ví dụ khi app vào background)
    public func pause() {
        guard case .monitoring = currentState else { return }
        PrivacyLogger.log("Pausing PrivacyDisplayManager")
        stopEngines()
        updateState(.paused)
    }
    
    /// Tiếp tục giám sát sau khi tạm dừng
    public func resume() {
        guard case .paused = currentState else { return }
        PrivacyLogger.log("Resuming PrivacyDisplayManager")
        startEngines()
    }
    
    /// Cập nhật cấu hình khi đang chạy
    public func updateConfiguration(_ config: PrivacyConfiguration) {
        let wasRunning: Bool
        switch currentState {
        case .inactive:
            wasRunning = false
        default:
            wasRunning = true
        }
        
        if wasRunning {
            stop()
            start(with: config)
        } else {
            self.configuration = config
        }
    }
    
    /// Manually kích hoạt privacy mode
    public func activateManually() {
        activatePrivacyMode()
    }
    
    /// Manually tắt privacy mode
    public func deactivateManually() {
        deactivatePrivacyMode(animated: true)
    }
    
    // MARK: - Overlay Management
    
    /// Gắn overlay renderer vào window/view cụ thể
    public func attachOverlay(to window: UIWindow) {
        overlayRenderer = PrivacyOverlayRenderer(
            style: configuration.overlayStyle,
            animationDuration: configuration.animationDuration
        )
        overlayRenderer?.attach(to: window)
    }
    
    /// Gắn overlay renderer vào view cụ thể
    public func attachOverlay(to view: UIView) {
        overlayRenderer = PrivacyOverlayRenderer(
            style: configuration.overlayStyle,
            animationDuration: configuration.animationDuration
        )
        overlayRenderer?.attach(to: view)
    }
    
    /// Đặt custom overlay view
    public func setCustomOverlay(_ view: UIView) {
        overlayRenderer?.setCustomOverlayView(view)
    }
    
    // MARK: - Private Methods
    
    private func setupEngines() {
        switch configuration.detectionMode {
        case .faceTracking:
            setupFaceTracking()
        case .tiltDetection:
            setupTiltDetection()
        case .combined:
            setupFaceTracking()
            setupTiltDetection()
        }
    }
    
    private func setupFaceTracking() {
        guard DeviceCapabilities.isFaceTrackingSupported else {
            PrivacyLogger.log("Face tracking not supported, falling back to tilt detection", level: .warning)
            if configuration.detectionMode == .combined {
                return // Tilt detection vẫn hoạt động
            }
            updateState(.error(.faceTrackingNotSupported))
            delegate?.privacyDisplay(didEncounterError: .faceTrackingNotSupported)
            return
        }
        
        let engine = FaceTrackingEngine(
            maxAllowedFaces: configuration.maxAllowedFaces,
            absenceTimeout: configuration.faceAbsenceTimeout,
            targetFPS: configuration.faceTrackingFPS
        )
        
        engine.onThreatDetected = { [weak self] level in
            Task { @MainActor in
                self?.handleThreatDetected(level, from: .faceTracking)
            }
        }
        
        engine.onThreatIntensityUpdated = { [weak self] intensity, direction in
            Task { @MainActor in
                self?.handleThreatIntensity(intensity, direction: direction)
            }
        }
        
        engine.onError = { [weak self] error in
            Task { @MainActor in
                self?.handleError(error)
            }
        }
        
        faceTrackingEngine = engine
    }
    
    private func setupTiltDetection() {
        guard DeviceCapabilities.isMotionAvailable else {
            PrivacyLogger.log("Motion sensors not available", level: .warning)
            if configuration.detectionMode == .combined {
                return
            }
            updateState(.error(.motionSensorsNotAvailable))
            delegate?.privacyDisplay(didEncounterError: .motionSensorsNotAvailable)
            return
        }
        
        let engine = TiltDetectionEngine(
            threshold: configuration.tiltThreshold,
            sensitivity: configuration.sensitivity,
            adaptive: configuration.adaptiveTilt
        )
        
        engine.onThreatDetected = { [weak self] level in
            Task { @MainActor in
                self?.handleThreatDetected(level, from: .tiltDetection)
            }
        }
        
        engine.onThreatIntensityUpdated = { [weak self] intensity, direction in
            Task { @MainActor in
                self?.handleThreatIntensity(intensity, direction: direction)
            }
        }
        
        engine.onError = { [weak self] error in
            Task { @MainActor in
                self?.handleError(error)
            }
        }
        
        tiltDetectionEngine = engine
    }
    
    private func startEngines() {
        do {
            if let faceEngine = faceTrackingEngine {
                try faceEngine.start()
            }
            if let tiltEngine = tiltDetectionEngine {
                try tiltEngine.start()
            }
            updateState(.monitoring)
            PrivacyLogger.log("All engines started successfully")
        } catch {
            let privacyError: PrivacyError = .unknown(error.localizedDescription)
            updateState(.error(privacyError))
            delegate?.privacyDisplay(didEncounterError: privacyError)
        }
    }
    
    private func stopEngines() {
        faceTrackingEngine?.stop()
        tiltDetectionEngine?.stop()
    }
    
    private func handleThreatDetected(_ level: ThreatLevel, from source: DetectionMode) {
        let previousLevel = currentThreatLevel
        
        // Trong combined mode, lấy mức đe dọa cao nhất
        if configuration.detectionMode == .combined {
            currentThreatLevel = max(currentThreatLevel, level)
        } else {
            currentThreatLevel = level
        }
        
        if currentThreatLevel != previousLevel {
            delegate?.privacyDisplay(didChangeThreatLevel: currentThreatLevel)
            PrivacyLogger.log("Threat level changed: \(previousLevel) → \(currentThreatLevel) (source: \(source))")
        }
        
        // Quyết định kích hoạt hay tắt overlay dựa trên sensitivity
        let threshold: ThreatLevel
        switch configuration.sensitivity {
        case .low: threshold = .high
        case .medium: threshold = .medium
        case .high: threshold = .low
        case .custom(let val):
            if val > 0.7 { threshold = .low }
            else if val > 0.4 { threshold = .medium }
            else { threshold = .high }
        }
        
        if currentThreatLevel >= threshold {
            scheduleActivation()
        } else {
            scheduleDeactivation()
        }
    }
    
    private func handleThreatIntensity(_ intensity: Double, direction: ThreatDirection) {
        // Làm mượt sự thay đổi độ che phủ
        if abs(self.threatIntensity - intensity) > 0.01 || self.threatDirection != direction {
            self.threatIntensity = intensity
            self.threatDirection = direction
            delegate?.privacyDisplay(didChangeThreatIntensity: intensity, direction: direction)
            
            // Tự động kích hoạt/tắt dựa trên cường độ > 0
            if intensity > 0 && !isPrivacyModeActive {
                activatePrivacyMode()
            } else if intensity == 0 && isPrivacyModeActive && currentThreatLevel == .none {
                deactivatePrivacyMode(animated: true)
            }
        }
    }
    
    private func scheduleActivation() {
        deactivationTimer?.invalidate()
        deactivationTimer = nil
        
        guard !isPrivacyModeActive, activationTimer == nil else { return }
        
        activationTimer = Timer.scheduledTimer(
            withTimeInterval: configuration.activationDelay,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                self?.activatePrivacyMode()
            }
        }
    }
    
    private func scheduleDeactivation() {
        activationTimer?.invalidate()
        activationTimer = nil
        
        guard isPrivacyModeActive, deactivationTimer == nil else { return }
        
        deactivationTimer = Timer.scheduledTimer(
            withTimeInterval: configuration.deactivationDelay,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                self?.deactivatePrivacyMode(animated: true)
            }
        }
    }
    
    private func activatePrivacyMode() {
        guard !isPrivacyModeActive else { return }
        
        activationTimer?.invalidate()
        activationTimer = nil
        
        isPrivacyModeActive = true
        updateState(.activated)
        
        overlayRenderer?.show()
        
        if configuration.hapticFeedback {
            hapticGenerator?.notificationOccurred(.warning)
        }
        
        delegate?.privacyDisplayDidActivate()
        PrivacyLogger.log("Privacy mode ACTIVATED")
    }
    
    private func deactivatePrivacyMode(animated: Bool) {
        guard isPrivacyModeActive else { return }
        
        deactivationTimer?.invalidate()
        deactivationTimer = nil
        
        isPrivacyModeActive = false
        currentThreatLevel = .none
        
        if animated {
            overlayRenderer?.hide()
        } else {
            overlayRenderer?.hideImmediately()
        }
        
        switch currentState {
        case .activated:
            updateState(.monitoring)
        default:
            break
        }
        
        if configuration.hapticFeedback {
            hapticGenerator?.notificationOccurred(.success)
        }
        
        delegate?.privacyDisplayDidDeactivate()
        PrivacyLogger.log("Privacy mode DEACTIVATED")
    }
    
    private func updateState(_ newState: PrivacyState) {
        currentState = newState
        delegate?.privacyDisplay(didChangeState: newState)
    }
    
    private func handleError(_ error: PrivacyError) {
        PrivacyLogger.log("Error: \(error.localizedDescription)", level: .error)
        delegate?.privacyDisplay(didEncounterError: error)
    }
    
    // MARK: - App Lifecycle
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        guard configuration.pauseInBackground else { return }
        pause()
    }
    
    @objc private func appWillEnterForeground() {
        guard configuration.pauseInBackground else { return }
        resume()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
