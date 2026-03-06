import XCTest
@testable import PrivacyDisplayKit

final class PrivacyConfigurationTests: XCTestCase {
    
    func testDefaultConfiguration() {
        let config = PrivacyConfiguration.default
        
        XCTAssertEqual(config.tiltThreshold, 30.0)
        XCTAssertEqual(config.activationDelay, 0.5)
        XCTAssertEqual(config.deactivationDelay, 1.0)
        XCTAssertEqual(config.animationDuration, 0.3)
        XCTAssertEqual(config.maxAllowedFaces, 1)
        XCTAssertEqual(config.faceAbsenceTimeout, 3.0)
        XCTAssertEqual(config.faceTrackingFPS, 15)
        XCTAssertTrue(config.pauseInBackground)
        XCTAssertTrue(config.hapticFeedback)
        XCTAssertFalse(config.debugLogging)
        XCTAssertTrue(config.adaptiveTilt)
    }
    
    func testHighSecurityPreset() {
        let config = PrivacyConfiguration.highSecurity
        
        XCTAssertEqual(config.tiltThreshold, 20.0)
        XCTAssertEqual(config.activationDelay, 0.2)
        XCTAssertEqual(config.deactivationDelay, 1.5)
        XCTAssertEqual(config.faceAbsenceTimeout, 1.5)
    }
    
    func testBatterySaverPreset() {
        let config = PrivacyConfiguration.batterySaver
        
        XCTAssertEqual(config.tiltThreshold, 35.0)
        XCTAssertEqual(config.activationDelay, 1.0)
        XCTAssertEqual(config.deactivationDelay, 0.5)
    }
    
    func testBankingPreset() {
        let config = PrivacyConfiguration.banking
        
        XCTAssertEqual(config.tiltThreshold, 15.0)
        XCTAssertEqual(config.activationDelay, 0.1)
        XCTAssertEqual(config.faceTrackingFPS, 30)
        XCTAssertTrue(config.hapticFeedback)
    }
    
    func testCustomConfiguration() {
        let config = PrivacyConfiguration(
            detectionMode: .tiltDetection,
            sensitivity: .custom(0.9),
            tiltThreshold: 25.0,
            adaptiveTilt: false,
            maxAllowedFaces: 2,
            faceAbsenceTimeout: 5.0,
            faceTrackingFPS: 10,
            activationDelay: 0.3,
            deactivationDelay: 2.0,
            animationDuration: 0.5,
            pauseInBackground: false,
            hapticFeedback: false,
            debugLogging: true
        )
        
        XCTAssertEqual(config.tiltThreshold, 25.0)
        XCTAssertFalse(config.adaptiveTilt)
        XCTAssertEqual(config.maxAllowedFaces, 2)
        XCTAssertEqual(config.faceAbsenceTimeout, 5.0)
        XCTAssertEqual(config.faceTrackingFPS, 10)
        XCTAssertFalse(config.pauseInBackground)
        XCTAssertFalse(config.hapticFeedback)
        XCTAssertTrue(config.debugLogging)
    }
    
    func testSensitivityValues() {
        XCTAssertEqual(Sensitivity.low.value, 0.3)
        XCTAssertEqual(Sensitivity.medium.value, 0.5)
        XCTAssertEqual(Sensitivity.high.value, 0.8)
        XCTAssertEqual(Sensitivity.custom(0.6).value, 0.6)
    }
    
    func testSensitivityClamping() {
        XCTAssertEqual(Sensitivity.custom(-0.5).value, 0.0)
        XCTAssertEqual(Sensitivity.custom(1.5).value, 1.0)
        XCTAssertEqual(Sensitivity.custom(0.0).value, 0.0)
        XCTAssertEqual(Sensitivity.custom(1.0).value, 1.0)
    }
    
    func testThreatLevelComparable() {
        XCTAssertTrue(ThreatLevel.none < ThreatLevel.low)
        XCTAssertTrue(ThreatLevel.low < ThreatLevel.medium)
        XCTAssertTrue(ThreatLevel.medium < ThreatLevel.high)
        XCTAssertTrue(ThreatLevel.high < ThreatLevel.critical)
        XCTAssertFalse(ThreatLevel.high < ThreatLevel.low)
    }
    
    func testThreatLevelMax() {
        XCTAssertEqual(max(ThreatLevel.low, ThreatLevel.high), .high)
        XCTAssertEqual(max(ThreatLevel.none, ThreatLevel.critical), .critical)
    }
    
    func testPrivacyErrorDescriptions() {
        let errors: [PrivacyError] = [
            .faceTrackingNotSupported,
            .motionSensorsNotAvailable,
            .cameraPermissionDenied,
            .motionPermissionDenied,
            .biometricNotAvailable,
            .invalidConfiguration("test"),
            .unknown("test error")
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
}
