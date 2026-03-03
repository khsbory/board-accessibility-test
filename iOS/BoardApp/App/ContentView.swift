import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("화면 전환 패턴을 선택하세요")
                    .font(.headline)
                    .padding(.top, 40)

                VStack(spacing: 16) {
                    NavigationLink("UIKit 독립 화면") {
                        UIKitSeparateWrapper()
                            .navigationBarHidden(true)
                            .ignoresSafeArea()
                    }
                    .buttonStyle(.borderedProminent)

                    NavigationLink("UIKit 단일 화면") {
                        UIKitSingleWrapper()
                            .navigationBarHidden(true)
                            .ignoresSafeArea()
                    }
                    .buttonStyle(.borderedProminent)

                    NavigationLink("SwiftUI 독립 화면") {
                        SeparateBoardView()
                    }
                    .buttonStyle(.borderedProminent)

                    NavigationLink("SwiftUI 단일 화면") {
                        SingleBoardView()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .navigationTitle("게시판 접근성 테스트")
        }
    }
}

#Preview {
    ContentView()
}
