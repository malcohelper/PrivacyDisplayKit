import XCTest
@testable import PrivacyDisplayKit

final class TiltDetectionEngineTests: XCTestCase {
    
    func testTiltAngleDegrees() {
        let angle = TiltAngle(
            pitch: .pi / 6, // 30°
            roll: .pi / 4,  // 45°
            yaw: .pi / 3    // 60°
        )
        
        XCTAssertEqual(angle.pitchDegrees, 30.0, accuracy: 0.01)
        XCTAssertEqual(angle.rollDegrees, 45.0, accuracy: 0.01)
        XCTAssertEqual(angle.yawDegrees, 60.0, accuracy: 0.01)
    }
    
    func testTiltAngleTotalTilt() {
        // Chỉ pitch
        let pitchOnly = TiltAngle(pitch: .pi / 6, roll: 0, yaw: 0)
        XCTAssertEqual(pitchOnly.totalTiltDegrees, 30.0, accuracy: 0.01)
        
        // Chỉ roll
        let rollOnly = TiltAngle(pitch: 0, roll: .pi / 4, yaw: 0)
        XCTAssertEqual(rollOnly.totalTiltDegrees, 45.0, accuracy: 0.01)
        
        // Kết hợp
        let combined = TiltAngle(pitch: .pi / 6, roll: .pi / 6, yaw: 0)
        let expected = sqrt(30.0 * 30.0 + 30.0 * 30.0) // ~42.43°
        XCTAssertEqual(combined.totalTiltDegrees, expected / (180 / .pi) * (180 / .pi), accuracy: 1.0)
    }
    
    func testZeroTiltAngle() {
        let angle = TiltAngle(pitch: 0, roll: 0, yaw: 0)
        XCTAssertEqual(angle.totalTiltDegrees, 0.0, accuracy: 0.001)
        XCTAssertEqual(angle.pitchDegrees, 0.0)
        XCTAssertEqual(angle.rollDegrees, 0.0)
    }
    
    func testTiltEngineInitialState() {
        let engine = TiltDetectionEngine(
            threshold: 25.0,
            sensitivity: .high,
            adaptive: false
        )
        
        XCTAssertFalse(engine.isRunning)
    }
}
