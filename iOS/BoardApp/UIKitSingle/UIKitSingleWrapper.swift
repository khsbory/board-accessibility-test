import SwiftUI
import UIKit

struct UIKitSingleWrapper: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UINavigationController {
        let containerVC = ContainerViewController()
        containerVC.onDismiss = { [dismiss] in
            dismiss()
        }
        let navController = UINavigationController(rootViewController: containerVC)
        navController.isNavigationBarHidden = true
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
