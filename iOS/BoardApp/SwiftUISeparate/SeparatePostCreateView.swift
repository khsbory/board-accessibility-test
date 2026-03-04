import SwiftUI

struct SeparatePostCreateView: View {
    let viewModel: SeparateViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var content = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            TextField("제목을 입력하세요", text: $title)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.top, 20)

            TextEditor(text: $content)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)

            Button {
                submitPost()
            } label: {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("등록")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.blue)
            .foregroundStyle(.white)
            .fontWeight(.semibold)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.bottom, 8)
            .disabled(isSubmitting)
        }
        .navigationTitle("게시글 작성")
        .alert("오류", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("확인") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func submitPost() {
        guard !title.isEmpty else {
            errorMessage = "제목을 입력하세요."
            return
        }
        guard !content.isEmpty else {
            errorMessage = "내용을 입력하세요."
            return
        }

        isSubmitting = true
        Task {
            do {
                try await viewModel.createPost(title: title, content: content)
                await viewModel.refreshPosts()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}
