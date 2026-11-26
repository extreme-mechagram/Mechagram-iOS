import Foundation
import UIKit

/// Falling snow over the whole app (Settings ▸ Appearance ▸ Winter ▸ Snow).
/// It lives in its own window that never takes touches, so the app below it
/// keeps working exactly as before.
final class MechagramSnowOverlay {
    static let shared = MechagramSnowOverlay()

    static let snowKey = "mechagram.winter.snow"
    static let changedNotification = Notification.Name("MechagramWinterSettingsChanged")

    private var window: UIWindow?
    private weak var hostWindow: UIWindow?
    private var observer: NSObjectProtocol?

    private init() {}

    static var isEnabled: Bool {
        return UserDefaults.standard.bool(forKey: MechagramSnowOverlay.snowKey)
    }

    func install(hostWindow: UIWindow) {
        self.hostWindow = hostWindow
        if self.observer == nil {
            self.observer = NotificationCenter.default.addObserver(forName: MechagramSnowOverlay.changedNotification, object: nil, queue: .main, using: { [weak self] _ in
                self?.update()
            })
        }
        // The host window gets its scene a moment after launch.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: { [weak self] in
            self?.update()
        })
    }

    private func update() {
        if MechagramSnowOverlay.isEnabled {
            self.show()
        } else {
            self.hide()
        }
    }

    private func show() {
        if let window = self.window {
            window.isHidden = false
            return
        }
        guard let hostWindow = self.hostWindow else {
            return
        }
        let window: UIWindow
        if #available(iOS 13.0, *), let scene = hostWindow.windowScene {
            window = PassthroughSnowWindow(windowScene: scene)
        } else {
            window = PassthroughSnowWindow(frame: hostWindow.bounds)
        }
        window.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.normal.rawValue + 1.0)
        window.backgroundColor = .clear
        window.isUserInteractionEnabled = false
        let controller = UIViewController()
        controller.view = SnowView(frame: window.bounds)
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.rootViewController = controller
        window.isHidden = false
        self.window = window
    }

    private func hide() {
        self.window?.isHidden = true
        self.window = nil
    }
}

private final class PassthroughSnowWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }
}

private final class SnowView: UIView {
    private let emitter = CAEmitterLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = false

        let cell = CAEmitterCell()
        cell.contents = SnowView.flakeImage()?.cgImage
        cell.birthRate = 7.0
        cell.lifetime = 16.0
        cell.velocity = 34.0
        cell.velocityRange = 18.0
        cell.yAcceleration = 6.0
        cell.xAcceleration = 2.0
        cell.emissionLongitude = .pi
        cell.emissionRange = .pi / 8.0
        cell.spin = 0.4
        cell.spinRange = 1.2
        cell.scale = 0.55
        cell.scaleRange = 0.35
        cell.alphaSpeed = -0.03
        cell.alphaRange = 0.3
        self.emitter.emitterCells = [cell]
        self.emitter.emitterShape = .line
        self.emitter.renderMode = .additive
        self.layer.addSublayer(self.emitter)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.emitter.frame = self.bounds
        self.emitter.emitterPosition = CGPoint(x: self.bounds.midX, y: -12.0)
        self.emitter.emitterSize = CGSize(width: self.bounds.width * 1.2, height: 1.0)
    }

    private static func flakeImage() -> UIImage? {
        let size = CGSize(width: 14.0, height: 14.0)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        let colors = [UIColor(white: 1.0, alpha: 0.95).cgColor, UIColor(white: 1.0, alpha: 0.0).cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 1.0]) {
            let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
            context.drawRadialGradient(gradient, startCenter: center, startRadius: 0.0, endCenter: center, endRadius: size.width / 2.0, options: [])
        }
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
