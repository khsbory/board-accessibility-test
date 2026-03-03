import SwiftUI
import UIKit

struct UIKitSingleWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let containerVC = ContainerViewController()
        let navController = UINavigationController(rootViewController: containerVC)
        navController.isNavigationBarHidden = true
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
