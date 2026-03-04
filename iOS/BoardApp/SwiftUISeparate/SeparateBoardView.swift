import SwiftUI

/// Legacy wrapper kept for compatibility.
/// Navigation destinations are now registered at the root NavigationStack in ContentView
/// using the unified `AppRoute` enum.
struct SeparateBoardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var viewModel = SeparateViewModel()

    var body: some View {
        SeparatePostListView(viewModel: viewModel, onDismiss: { dismiss() })
    }
}
