import SwiftUI

struct SinglePostListContent: View {
    let viewModel: SingleViewModel

    var body: some View {
        ZStack {
            List {
                ForEach(Array(viewModel.posts.enumerated()), id: \.element.id) { index, post in
                    Button {
                        viewModel.navigateToDetail(postId: post.id)
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
                        // 첫 번째 게시글 가시성 추적 (스크롤 위치 판단용)
                        if index == 0 {
                            viewModel.isFirstPostVisible = true
                        }
                        // 페이지네이션
                        Task {
                            await viewModel.loadNextPageIfNeeded(currentPost: post)
                        }
                    }
                    .onDisappear {
                        if index == 0 {
                            viewModel.isFirstPostVisible = false
                        }
                    }
                }
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.refreshPosts()
            }

            if viewModel.isLoadingPage && viewModel.posts.isEmpty {
                ProgressView()
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
        .safeAreaInset(edge: .bottom) {
            Button("게시글 작성") {
                viewModel.navigateToCreate()
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
    }
}
