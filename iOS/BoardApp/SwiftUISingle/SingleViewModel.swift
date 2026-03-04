import SwiftUI
import Observation

enum SingleScreenState: Equatable {
    case list
    case detail(Int)
    case create

    static func == (lhs: SingleScreenState, rhs: SingleScreenState) -> Bool {
        switch (lhs, rhs) {
        case (.list, .list): return true
        case (.detail(let a), .detail(let b)): return a == b
        case (.create, .create): return true
        default: return false
        }
    }
}

@Observable
final class SingleViewModel {
    var posts: [Post] = []
    var isLoading = false
    var errorMessage: String?
    var currentPage = 1
    var hasNextPage = false
    var currentScreen: SingleScreenState = .list

    // Detail state
    var detailPost: Post?
    var isDetailLoading = false

    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }

    var navigationTitle: String {
        switch currentScreen {
        case .list: return "SwiftUI 단일 화면"
        case .detail: return "게시글 상세"
        case .create: return "게시글 작성"
        }
    }

    var showBackButton: Bool {
        currentScreen != .list
    }

    func loadPosts() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiService.fetchPosts(page: currentPage, limit: 10)
            posts.append(contentsOf: response.data)
            hasNextPage = response.pagination.hasNext
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Auto-load additional pages until the list has enough items to be scrollable.
    /// Call this after the initial load to fill the visible area.
    func loadInitialPages() async {
        await loadPosts()
        // If the first page loaded and there are more pages, preload one more page
        // to ensure the list is scrollable so .onAppear can trigger further pagination.
        if hasNextPage && !isLoading && posts.count <= 10 {
            currentPage += 1
            await loadPosts()
        }
    }

    func refreshPosts() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            // Load first page
            let first = try await apiService.fetchPosts(page: 1, limit: 10)
            var allPosts = first.data
            var nextPage = first.pagination.hasNext

            // Preload second page to keep the list scrollable
            if nextPage {
                let second = try await apiService.fetchPosts(page: 2, limit: 10)
                allPosts.append(contentsOf: second.data)
                nextPage = second.pagination.hasNext
            }

            // Atomic swap to avoid flicker
            posts = allPosts
            currentPage = nextPage ? 2 : 1
            hasNextPage = nextPage
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadNextPageIfNeeded(currentPost: Post) async {
        guard hasNextPage, !isLoading else { return }
        // Trigger when the displayed item is within the last 3 items
        guard let index = posts.firstIndex(where: { $0.id == currentPost.id }) else { return }
        let threshold = max(posts.count - 3, 0)
        guard index >= threshold else { return }
        currentPage += 1
        await loadPosts()
    }

    func navigateToDetail(postId: Int) {
        withAnimationCompat {
            currentScreen = .detail(postId)
        }
        loadDetail(postId: postId)
    }

    func navigateToCreate() {
        withAnimationCompat {
            currentScreen = .create
        }
    }

    func navigateBack(shouldRefresh: Bool = false) {
        withAnimationCompat {
            currentScreen = .list
            detailPost = nil
        }
        if shouldRefresh {
            Task { await refreshPosts() }
        }
    }

    func loadDetail(postId: Int) {
        isDetailLoading = true
        detailPost = nil
        Task {
            do {
                detailPost = try await apiService.fetchPost(id: postId)
            } catch {
                errorMessage = error.localizedDescription
            }
            isDetailLoading = false
        }
    }

    func createPost(title: String, content: String) async throws {
        _ = try await apiService.createPost(title: title, content: content)
    }

    func deletePost(id: Int) async throws {
        _ = try await apiService.deletePost(id: id)
    }

    private func withAnimationCompat(_ body: () -> Void) {
        withAnimation(.easeInOut(duration: 0.3), body)
    }
}
