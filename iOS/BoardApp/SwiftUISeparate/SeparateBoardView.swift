import SwiftUI

enum SeparateRoute: Hashable {
    case detail(Int)
    case create
}

struct SeparateBoardView: View {
    @State private var path = NavigationPath()
    @State private var viewModel = SeparateViewModel()

    var body: some View {
        NavigationStack(path: $path) {
            SeparatePostListView(viewModel: viewModel, path: $path)
                .navigationDestination(for: SeparateRoute.self) { route in
                    switch route {
                    case .detail(let postId):
                        SeparatePostDetailView(viewModel: viewModel, postId: postId, path: $path)
                    case .create:
                        SeparatePostCreateView(viewModel: viewModel, path: $path)
                    }
                }
        }
    }
}
