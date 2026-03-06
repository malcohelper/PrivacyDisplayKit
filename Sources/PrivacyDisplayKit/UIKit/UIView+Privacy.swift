import UIKit

// MARK: - UIView Privacy Extensions

public extension UIView {
    
    /// Bật privacy display cho view này
    ///
    /// ```swift
    /// view.enablePrivacyDisplay()
    /// // hoặc
    /// view.enablePrivacyDisplay(config: .banking)
    /// ```
    func enablePrivacyDisplay(config: PrivacyConfiguration = .default) {
        let manager = PrivacyDisplayManager.shared
        manager.start(with: config)
    }
    
    /// Tắt privacy display
    func disablePrivacyDisplay() {
        PrivacyDisplayManager.shared.stop()
    }
    
    /// Đánh dấu view chứa nội dung nhạy cảm
    /// Sẽ tự động được che khi privacy mode active
    func markAsPrivacySensitive(style: OverlayStyle = .blur(radius: 15)) {
        let tag = 99887700
        
        // Tránh duplicate
        if viewWithTag(tag) != nil { return }
        
        let sensitiveOverlay = UIView(frame: bounds)
        sensitiveOverlay.tag = tag
        sensitiveOverlay.backgroundColor = .clear
        sensitiveOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sensitiveOverlay.isHidden = true
        sensitiveOverlay.isUserInteractionEnabled = false
        
        // Tạo blur effect (hiệu ứng dìm tối tinh tế)
        let blurEffect = UIBlurEffect(style: .systemMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sensitiveOverlay.addSubview(blurView)
        
        // Add a gradient mask layer
        let maskLayer = CAGradientLayer()
        maskLayer.frame = bounds
        maskLayer.colors = [UIColor.black.cgColor, UIColor.black.cgColor]
        sensitiveOverlay.layer.mask = maskLayer
        
        // Observe bounds changes if needed for the mask, but autoresizingMask handles visual effect. 
        // We observe bounds via KVO or layoutSubviews if needed, but for now we set frame statically.
        
        addSubview(sensitiveOverlay)
        
        // Observe privacy intensity and direction changes
        Publishers.CombineLatest(PrivacyDisplayManager.shared.$threatIntensity, PrivacyDisplayManager.shared.$threatDirection)
            .receive(on: DispatchQueue.main)
            .sink { [weak sensitiveOverlay] intensity, direction in
                guard let overlay = sensitiveOverlay, let mask = overlay.layer.mask as? CAGradientLayer else { return }
                
                // Cập nhật hướng gradient mask
                switch direction {
                case .left:
                    mask.startPoint = CGPoint(x: 0, y: 0.5)
                    mask.endPoint = CGPoint(x: 1, y: 0.5)
                    mask.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
                case .right:
                    mask.startPoint = CGPoint(x: 0, y: 0.5)
                    mask.endPoint = CGPoint(x: 1, y: 0.5)
                    mask.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
                case .top:
                    mask.startPoint = CGPoint(x: 0.5, y: 0)
                    mask.endPoint = CGPoint(x: 0.5, y: 1)
                    mask.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
                case .bottom:
                    mask.startPoint = CGPoint(x: 0.5, y: 0)
                    mask.endPoint = CGPoint(x: 0.5, y: 1)
                    mask.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
                case .uniform:
                    mask.colors = [UIColor.black.cgColor, UIColor.black.cgColor]
                }
                
                mask.frame = overlay.bounds
                
                UIView.animate(withDuration: 0.1, delay: 0, options: [.beginFromCurrentState, .curveLinear]) {
                    overlay.isHidden = intensity == 0
                    overlay.alpha = CGFloat(intensity)
                }
            }
            .store(in: &associatedCancellables)
    }
    
    /// Bỏ đánh dấu sensitive
    func removePrivacySensitive() {
        viewWithTag(99887700)?.removeFromSuperview()
    }
}

// MARK: - Associated Objects for Combine

import Combine

private var cancellablesKey: UInt8 = 0

private extension UIView {
    var associatedCancellables: Set<AnyCancellable> {
        get {
            objc_getAssociatedObject(self, &cancellablesKey) as? Set<AnyCancellable> ?? Set()
        }
        set {
            objc_setAssociatedObject(self, &cancellablesKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
