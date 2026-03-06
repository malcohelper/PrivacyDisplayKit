import Foundation
import UIKit

/// Renderer chịu trách nhiệm hiển thị overlay privacy trên màn hình
public final class PrivacyOverlayRenderer {
    
    // MARK: - Properties
    
    private let style: OverlayStyle
    private let animationDuration: TimeInterval
    
    private weak var hostView: UIView?
    private var overlayView: UIView?
    private var customOverlayView: UIView?
    private var isShowing: Bool = false
    
    // MARK: - Initialization
    
    public init(style: OverlayStyle, animationDuration: TimeInterval = 0.3) {
        self.style = style
        self.animationDuration = animationDuration
    }
    
    // MARK: - Attach
    
    /// Gắn renderer vào UIWindow
    public func attach(to window: UIWindow) {
        self.hostView = window
    }
    
    /// Gắn renderer vào UIView
    public func attach(to view: UIView) {
        self.hostView = view
    }
    
    /// Đặt custom overlay view
    public func setCustomOverlayView(_ view: UIView) {
        self.customOverlayView = view
    }
    
    // MARK: - Show / Hide
    
    /// Hiển thị overlay với animation
    @MainActor
    public func show() {
        guard let host = hostView, !isShowing else { return }
        
        let overlay = createOverlay(for: host.bounds)
        overlay.alpha = 0
        overlay.frame = host.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.tag = 99887766 // Unique tag để tìm lại
        
        host.addSubview(overlay)
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseInOut) {
            overlay.alpha = 1
        }
        
        overlayView = overlay
        isShowing = true
    }
    
    /// Ẩn overlay với animation
    @MainActor
    public func hide() {
        guard let overlay = overlayView, isShowing else { return }
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseInOut) {
            overlay.alpha = 0
        } completion: { [weak self] _ in
            overlay.removeFromSuperview()
            self?.overlayView = nil
            self?.isShowing = false
        }
    }
    
    /// Ẩn overlay ngay lập tức (không animation)
    @MainActor
    public func hideImmediately() {
        overlayView?.removeFromSuperview()
        overlayView = nil
        isShowing = false
    }
    
    // MARK: - Create Overlay
    
    private func createOverlay(for bounds: CGRect) -> UIView {
        switch style {
        case .blur(let radius):
            return createBlurOverlay(radius: radius, bounds: bounds)
        case .dim(let opacity):
            return createDimOverlay(opacity: opacity, bounds: bounds)
        case .noise:
            return createNoiseOverlay(bounds: bounds)
        case .gradient:
            return createGradientOverlay(bounds: bounds)
        case .blurAndDim(let blurRadius, let dimOpacity):
            return createBlurAndDimOverlay(blurRadius: blurRadius, dimOpacity: dimOpacity, bounds: bounds)
        case .custom:
            return customOverlayView ?? createDimOverlay(opacity: 0.85, bounds: bounds)
        }
    }
    
    // MARK: - Overlay Builders
    
    private func createBlurOverlay(radius: CGFloat, bounds: CGRect) -> UIView {
        let container = UIView(frame: bounds)
        container.backgroundColor = .clear
        
        let blurStyle: UIBlurEffect.Style = .systemUltraThinMaterialDark
        let blurEffect = UIBlurEffect(style: blurStyle)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(blurView)
        
        // Icon ổ khóa ở giữa
        addLockIcon(to: container, bounds: bounds)
        
        return container
    }
    
    private func createDimOverlay(opacity: Double, bounds: CGRect) -> UIView {
        let container = UIView(frame: bounds)
        container.backgroundColor = UIColor.black.withAlphaComponent(opacity)
        
        addLockIcon(to: container, bounds: bounds)
        
        return container
    }
    
    private func createNoiseOverlay(bounds: CGRect) -> UIView {
        let container = UIView(frame: bounds)
        container.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        
        // Noise pattern layer
        let noiseLayer = CALayer()
        noiseLayer.frame = bounds
        noiseLayer.opacity = 0.3
        
        // Tạo noise texture
        if let noiseImage = generateNoiseImage(size: bounds.size) {
            noiseLayer.contents = noiseImage.cgImage
            noiseLayer.contentsGravity = .resizeAspectFill
        }
        
        container.layer.addSublayer(noiseLayer)
        
        // Animation noise (flickering effect)
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.2
        animation.toValue = 0.4
        animation.duration = 0.1
        animation.autoreverses = true
        animation.repeatCount = .infinity
        noiseLayer.add(animation, forKey: "noise")
        
        addLockIcon(to: container, bounds: bounds)
        
        return container
    }
    
    private func createGradientOverlay(bounds: CGRect) -> UIView {
        let container = UIView(frame: bounds)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.type = .radial
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.3).cgColor,
            UIColor.black.withAlphaComponent(0.7).cgColor,
            UIColor.black.withAlphaComponent(0.95).cgColor
        ]
        gradientLayer.locations = [0.0, 0.3, 0.6, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        
        container.layer.addSublayer(gradientLayer)
        
        addLockIcon(to: container, bounds: bounds)
        
        return container
    }
    
    private func createBlurAndDimOverlay(blurRadius: CGFloat, dimOpacity: Double, bounds: CGRect) -> UIView {
        let container = UIView(frame: bounds)
        container.backgroundColor = .clear
        
        // Blur layer
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(blurView)
        
        // Dim layer on top
        let dimView = UIView(frame: bounds)
        dimView.backgroundColor = UIColor.black.withAlphaComponent(dimOpacity)
        dimView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(dimView)
        
        addLockIcon(to: container, bounds: bounds)
        
        return container
    }
    
    // MARK: - Helpers
    
    private func addLockIcon(to container: UIView, bounds: CGRect) {
        let iconSize: CGFloat = 48
        let lockImageView = UIImageView(frame: CGRect(
            x: (bounds.width - iconSize) / 2,
            y: (bounds.height - iconSize) / 2,
            width: iconSize,
            height: iconSize
        ))
        lockImageView.autoresizingMask = [
            .flexibleLeftMargin, .flexibleRightMargin,
            .flexibleTopMargin, .flexibleBottomMargin
        ]
        
        let config = UIImage.SymbolConfiguration(pointSize: 36, weight: .medium)
        lockImageView.image = UIImage(systemName: "lock.shield.fill", withConfiguration: config)
        lockImageView.tintColor = UIColor.white.withAlphaComponent(0.6)
        lockImageView.contentMode = .scaleAspectFit
        
        container.addSubview(lockImageView)
        
        // Label
        let label = UILabel()
        label.text = "Privacy Protected"
        label.textColor = UIColor.white.withAlphaComponent(0.5)
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.sizeToFit()
        label.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2 + iconSize / 2 + 16)
        label.autoresizingMask = [
            .flexibleLeftMargin, .flexibleRightMargin,
            .flexibleTopMargin, .flexibleBottomMargin
        ]
        container.addSubview(label)
    }
    
    private func generateNoiseImage(size: CGSize) -> UIImage? {
        let width = Int(min(size.width, 200))
        let height = Int(min(size.height, 200))
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        for y in stride(from: 0, to: height, by: 2) {
            for x in stride(from: 0, to: width, by: 2) {
                let brightness = CGFloat.random(in: 0...1)
                context.setFillColor(UIColor(white: brightness, alpha: 0.3).cgColor)
                context.fill(CGRect(x: x, y: y, width: 2, height: 2))
            }
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
