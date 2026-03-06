import Foundation
import os.log

/// Internal logger cho PrivacyDisplayKit
struct PrivacyLogger {
    
    static var isEnabled: Bool = false
    
    private static let logger = Logger(
        subsystem: "com.privacydisplaykit",
        category: "PrivacyDisplay"
    )
    
    enum Level {
        case debug
        case info
        case warning
        case error
    }
    
    static func log(_ message: String, level: Level = .info) {
        guard isEnabled else { return }
        
        switch level {
        case .debug:
            logger.debug("🔍 \(message)")
        case .info:
            logger.info("ℹ️ \(message)")
        case .warning:
            logger.warning("⚠️ \(message)")
        case .error:
            logger.error("❌ \(message)")
        }
    }
}
