import SwiftUI
import UIKit

struct UIKitSeparateWrapper: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UINavigationController {
        let listVC = PostListViewController()
        listVC.onDismiss = { [dismiss] in
            dismiss()
        }
        let navController = UINavigationController(rootViewController: listVC)
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
