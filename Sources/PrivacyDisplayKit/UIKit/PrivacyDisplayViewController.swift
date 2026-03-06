import UIKit
import Combine

/// Container ViewController tự động quản lý privacy overlay
///
/// Sử dụng để bọc bất kỳ UIViewController nào với privacy protection:
/// ```swift
/// let protectedVC = PrivacyDisplayViewController(
///     child: myContentVC,
///     configuration: .banking
/// )
/// present(protectedVC, animated: true)
/// ```
public class PrivacyDisplayViewController: UIViewController {
    
    // MARK: - Properties
    
    private let childViewController: UIViewController
    private let configuration: PrivacyConfiguration
    private let manager: PrivacyDisplayManager
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Delegate nhận thông báo privacy events
    public weak var privacyDelegate: PrivacyDisplayDelegate? {
        didSet { manager.delegate = privacyDelegate }
    }
    
    /// Privacy mode hiện đang active hay không
    public var isPrivacyModeActive: Bool {
        manager.isPrivacyModeActive
    }
    
    // MARK: - Initialization
    
    public init(
        child: UIViewController,
        configuration: PrivacyConfiguration = .default
    ) {
        self.childViewController = child
        self.configuration = configuration
        self.manager = PrivacyDisplayManager(configuration: configuration)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Embed child VC
        addChild(childViewController)
        childViewController.view.frame = view.bounds
        childViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(childViewController.view)
        childViewController.didMove(toParent: self)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        manager.start(with: configuration)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        manager.stop()
    }
    
    // MARK: - Public API
    
    /// Manually kích hoạt privacy mode
    public func activatePrivacyMode() {
        manager.activateManually()
    }
    
    /// Manually tắt privacy mode
    public func deactivatePrivacyMode() {
        manager.deactivateManually()
    }
    
    /// Cập nhật cấu hình
    public func updateConfiguration(_ config: PrivacyConfiguration) {
        manager.updateConfiguration(config)
    }
}
