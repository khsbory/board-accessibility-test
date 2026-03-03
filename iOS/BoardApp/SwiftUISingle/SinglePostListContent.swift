import SwiftUI

struct SinglePostListContent: View {
    let viewModel: SingleViewModel

    var body: some View {
        ZStack {
            List {
                ForEach(viewModel.posts) { post in
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
                        Task {
                            await viewModel.loadNextPageIfNeeded(currentPost: post)
                        }
                    }
                }
            }
            .listStyle(.plain)

            if viewModel.isLoading && viewModel.posts.isEmpty {
                ProgressView()
            }
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
