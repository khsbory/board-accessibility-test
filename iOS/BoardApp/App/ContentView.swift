import SwiftUI

struct ContentView: View {
    @State private var path = NavigationPath()
    @State private var separateViewModel = SeparateViewModel()

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 20) {
                Text("화면 전환 패턴을 선택하세요")
                    .font(.headline)
                    .padding(.top, 40)

                VStack(spacing: 16) {
                    NavigationLink("UIKit 독립 화면", value: AppRoute.uikitSeparate)
                        .buttonStyle(.borderedProminent)

                    NavigationLink("UIKit 단일 화면", value: AppRoute.uikitSingle)
                        .buttonStyle(.borderedProminent)

                    NavigationLink("SwiftUI 독립 화면", value: AppRoute.swiftUISeparate)
                        .buttonStyle(.borderedProminent)

                    NavigationLink("SwiftUI 단일 화면", value: AppRoute.swiftUISingle)
                        .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .navigationTitle("게시판 접근성 테스트")
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .uikitSeparate:
                    UIKitSeparateWrapper()
                        .navigationBarHidden(true)
                        .ignoresSafeArea()
                case .uikitSingle:
                    UIKitSingleWrapper()
                        .navigationBarHidden(true)
                        .ignoresSafeArea()
                case .swiftUISeparate:
                    SeparatePostListView(
                        viewModel: separateViewModel,
                        onDismiss: { path = NavigationPath() }
                    )
                case .swiftUISingle:
                    SingleBoardView()
                        .navigationBarHidden(true)
                case .separateDetail(let postId):
                    SeparatePostDetailView(
                        viewModel: separateViewModel,
                        postId: postId
                    )
                case .separateCreate:
                    SeparatePostCreateView(viewModel: separateViewModel)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
