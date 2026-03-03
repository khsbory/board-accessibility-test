import SwiftUI
import UIKit

struct UIKitSeparateWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let listVC = PostListViewController()
        let navController = UINavigationController(rootViewController: listVC)
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
