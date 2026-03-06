import Foundation
import LocalAuthentication

/// Xác thực chủ sở hữu thiết bị qua Face ID / Touch ID
public final class FaceAuthenticator {
    
    // MARK: - Properties
    
    private let context = LAContext()
    
    /// Lý do hiển thị cho người dùng khi yêu cầu xác thực
    public var authenticationReason: String = "Verify your identity to view protected content"
    
    /// Cho phép fallback sang passcode nếu biometric thất bại
    public var allowPasscodeFallback: Bool = true
    
    // MARK: - Public API
    
    /// Kiểm tra biometric có khả dụng không
    public var isBiometricAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Loại biometric hiện tại
    public var biometricType: LABiometryType {
        _ = isBiometricAvailable
        return context.biometryType
    }
    
    /// Xác thực người dùng qua biometric
    /// - Parameter completion: Callback với kết quả (success/failure)
    public func authenticate(completion: @escaping (Result<Bool, PrivacyError>) -> Void) {
        let policy: LAPolicy = allowPasscodeFallback
            ? .deviceOwnerAuthentication
            : .deviceOwnerAuthenticationWithBiometrics
        
        guard context.canEvaluatePolicy(policy, error: nil) else {
            completion(.failure(.biometricNotAvailable))
            return
        }
        
        context.evaluatePolicy(policy, localizedReason: authenticationReason) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(.success(true))
                } else if let error = error as? LAError {
                    switch error.code {
                    case .userCancel, .systemCancel, .appCancel:
                        completion(.success(false))
                    case .biometryNotAvailable:
                        completion(.failure(.biometricNotAvailable))
                    default:
                        completion(.failure(.unknown(error.localizedDescription)))
                    }
                } else {
                    completion(.failure(.unknown("Authentication failed")))
                }
            }
        }
    }
    
    /// Xác thực người dùng qua biometric (async)
    @available(iOS 16.0, *)
    public func authenticate() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            authenticate { result in
                switch result {
                case .success(let authenticated):
                    continuation.resume(returning: authenticated)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Invalidate context hiện tại (force re-authenticate lần sau)
    public func invalidate() {
        context.invalidate()
    }
}
