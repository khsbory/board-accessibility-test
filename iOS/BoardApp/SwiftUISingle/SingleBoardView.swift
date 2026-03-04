import SwiftUI

struct SingleBoardView: View {
    @Environment(\.dismiss) var dismiss
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
                } else {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("홈")
                        }
                    }
                    .accessibilityLabel("홈으로 돌아가기")
                }

                Spacer()

                Text(viewModel.navigationTitle)
                    .font(.headline)

                Spacer()

                // Invisible spacer for centering title
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text(viewModel.showBackButton ? "뒤로" : "홈")
                }
                .hidden()
            }
            .padding(.horizontal)
            .frame(height: 44)
            .background(.bar)

            Divider()

            // Content area - use ZStack with opacity instead of switch
            // to keep SinglePostListContent alive and preserve scroll position
            ZStack {
                SinglePostListContent(viewModel: viewModel)
                    .opacity(viewModel.currentScreen == .list ? 1 : 0)
                    .allowsHitTesting(viewModel.currentScreen == .list)

                if case .detail = viewModel.currentScreen {
                    SinglePostDetailContent(viewModel: viewModel)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .trailing)
                        ))
                }

                if case .create = viewModel.currentScreen {
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
                await viewModel.loadInitialPages()
            }
        }
    }
}

#Preview {
    SingleBoardView()
}
