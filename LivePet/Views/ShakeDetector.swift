import SwiftUI
#if canImport(UIKit)
import UIKit

extension Notification.Name {
    static let livePetDidShake = Notification.Name("livepet.didShake")
}

/// Becomes first responder so `motionEnded(.motionShake)` can post a notification.
struct ShakeDetector: UIViewControllerRepresentable {
    final class Controller: UIViewController {
        override var canBecomeFirstResponder: Bool { true }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            becomeFirstResponder()
        }

        override func viewWillDisappear(_ animated: Bool) {
            resignFirstResponder()
            super.viewWillDisappear(animated)
        }

        override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            if motion == .motionShake {
                NotificationCenter.default.post(name: .livePetDidShake, object: nil)
            }
            super.motionEnded(motion, with: event)
        }
    }

    func makeUIViewController(context: Context) -> Controller { Controller() }
    func updateUIViewController(_ uiViewController: Controller, context: Context) {}
}
#endif
