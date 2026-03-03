import SwiftUI

struct SeparatePostListView: View {
    let viewModel: SeparateViewModel
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            List {
                ForEach(viewModel.posts) { post in
                    Button {
                        path.append(SeparateRoute.detail(post.id))
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(post.title)
                                .font(.body)
                                .foregroundStyle(.primary)
                            Text(post.createdAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onAppear {
                        Task {
                            await viewModel.loadNextPageIfNeeded(currentPost: post)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.refreshPosts()
            }

            if viewModel.isLoading && viewModel.posts.isEmpty {
                ProgressView()
            }
        }
        .navigationTitle("SwiftUI 독립 화면")
        .safeAreaInset(edge: .bottom) {
            Button("게시글 작성") {
                path.append(SeparateRoute.create)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.blue)
            .foregroundStyle(.white)
            .fontWeight(.semibold)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .task {
            if viewModel.posts.isEmpty {
                await viewModel.loadPosts()
            }
        }
        .alert("오류", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("확인") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
