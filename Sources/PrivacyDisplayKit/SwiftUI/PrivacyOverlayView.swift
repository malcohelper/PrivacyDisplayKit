import SwiftUI

/// SwiftUI view hiển thị privacy overlay (raw visual effect)
public struct PrivacyOverlayView: View {
    let style: OverlayStyle
    
    public init(style: OverlayStyle = .blur()) {
        self.style = style
    }
    
    public var body: some View {
        ZStack {
            overlayContent
            
            VStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
                
                Text("Confidential")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("This content is only visible when you look directly at your phone.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
    }
    
    @ViewBuilder
    private var overlayContent: some View {
        switch style {
        case .blur(let radius):
            Rectangle()
                .fill(.ultraThinMaterial)
                .blur(radius: radius * 0.3)
                .background(Color.black.opacity(0.3))
            
        case .dim(let opacity):
            Color.black.opacity(opacity)
            
        case .noise:
            ZStack {
                Color.black.opacity(0.85)
                NoisePatternView()
                    .opacity(0.3)
            }
            
        case .gradient:
            RadialGradient(
                gradient: Gradient(colors: [
                    .clear,
                    .black.opacity(0.3),
                    .black.opacity(0.7),
                    .black.opacity(0.95)
                ]),
                center: .center,
                startRadius: 50,
                endRadius: UIScreen.main.bounds.width
            )
            
        case .blurAndDim(let blurRadius, let dimOpacity):
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .blur(radius: blurRadius * 0.3)
                Color.black.opacity(dimOpacity)
            }
            
        case .custom:
            Color.black.opacity(0.85)
        }
    }
}

/// Noise pattern view cho SwiftUI
private struct NoisePatternView: View {
    @State private var phase: Double = 0
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.1)) { _ in
            Canvas { context, size in
                for _ in 0..<500 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let brightness = Double.random(in: 0...1)
                    
                    context.fill(
                        Path(CGRect(x: x, y: y, width: 2, height: 2)),
                        with: .color(Color.white.opacity(brightness * 0.5))
                    )
                }
            }
        }
    }
}
