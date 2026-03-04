import SwiftUI

struct SeparatePostListView: View {
    let viewModel: SeparateViewModel
    var onDismiss: (() -> Void)?

    var body: some View {
        ZStack {
            List {
                ForEach(Array(viewModel.posts.enumerated()), id: \.element.id) { index, post in
                    NavigationLink(value: AppRoute.separateDetail(post.id)) {
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
                        if index == 0 {
                            viewModel.isFirstPostVisible = true
                        }
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
            .onAppear {
                // 상세에서 뒤로 돌아왔을 때 조건부 새로고침
                guard !viewModel.posts.isEmpty else { return }
                if viewModel.needsForceRefresh {
                    viewModel.needsForceRefresh = false
                    Task { await viewModel.refreshPosts() }
                } else if viewModel.isFirstPostVisible {
                    Task { await viewModel.refreshPosts() }
                }
            }

            if viewModel.isLoading && viewModel.posts.isEmpty {
                ProgressView()
            }
        }
        .navigationTitle("SwiftUI 독립 화면")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    onDismiss?()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("홈")
                    }
                }
                .accessibilityLabel("홈으로 돌아가기")
            }
        }
        .safeAreaInset(edge: .bottom) {
            NavigationLink(value: AppRoute.separateCreate) {
                Text("게시글 작성")
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
        .task {
            if viewModel.posts.isEmpty {
                await viewModel.loadInitialPages()
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
