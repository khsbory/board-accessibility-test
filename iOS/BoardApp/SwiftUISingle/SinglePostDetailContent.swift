import SwiftUI

struct SinglePostDetailContent: View {
    let viewModel: SingleViewModel
    @State private var showDeleteAlert = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            if let post = viewModel.detailPost {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(post.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(post.createdAt, format: .dateTime.year().month().day().hour().minute())
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Divider()

                        Text(post.content)
                            .font(.body)

                        Spacer(minLength: 20)

                        Button("삭제", role: .destructive) {
                            showDeleteAlert = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.red)
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding()
                }
            }

            if viewModel.isDetailLoading {
                ProgressView()
            }
        }
        .alert("삭제 확인", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                Task {
                    if case .detail(let postId) = viewModel.currentScreen {
                        do {
                            try await viewModel.deletePost(id: postId)
                            viewModel.navigateBack(shouldRefresh: true)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        } message: {
            Text("이 게시글을 삭제하시겠습니까?")
        }
        .alert("오류", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("확인") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
}
