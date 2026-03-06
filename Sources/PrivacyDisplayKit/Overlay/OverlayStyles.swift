import Foundation
import UIKit

/// Protocol cho custom overlay views
public protocol PrivacyOverlayProvider {
    /// Tạo view overlay
    func createOverlayView() -> UIView
    /// Animation hiển thị overlay
    func showAnimation(view: UIView, duration: TimeInterval)
    /// Animation ẩn overlay
    func hideAnimation(view: UIView, duration: TimeInterval, completion: @escaping () -> Void)
}

/// Các kiểu overlay style có sẵn
public enum OverlayStylePreset {
    /// Blur nhẹ — thích hợp cho notification privacy
    public static let lightBlur = OverlayStyle.blur(radius: 10)
    /// Blur mạnh — thích hợp cho banking
    public static let heavyBlur = OverlayStyle.blur(radius: 30)
    /// Dim nhẹ
    public static let lightDim = OverlayStyle.dim(opacity: 0.5)
    /// Dim nặng
    public static let heavyDim = OverlayStyle.dim(opacity: 0.9)
    /// Kết hợp blur + dim cho bảo mật cao
    public static let secure = OverlayStyle.blurAndDim(blurRadius: 25, dimOpacity: 0.7)
}
