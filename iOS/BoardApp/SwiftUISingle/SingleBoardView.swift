import SwiftUI

struct SingleBoardView: View {
    @State private var viewModel = SingleViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                if viewModel.showBackButton {
                    Button {
                        viewModel.navigateBack()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("뒤로")
                        }
                    }
                }

                Spacer()

                Text(viewModel.navigationTitle)
                    .font(.headline)

                Spacer()

                if viewModel.showBackButton {
                    // Invisible spacer for centering title
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("뒤로")
                    }
                    .hidden()
                }
            }
            .padding(.horizontal)
            .frame(height: 44)
            .background(.bar)

            Divider()

            // Content area
            ZStack {
                switch viewModel.currentScreen {
                case .list:
                    SinglePostListContent(viewModel: viewModel)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading),
                            removal: .move(edge: .leading)
                        ))
                case .detail:
                    SinglePostDetailContent(viewModel: viewModel)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .trailing)
                        ))
                case .create:
                    SinglePostCreateContent(viewModel: viewModel)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .trailing)
                        ))
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            if viewModel.posts.isEmpty {
                await viewModel.loadPosts()
            }
        }
    }
}

#Preview {
    SingleBoardView()
}
