import Foundation
import Observation

@Observable
final class SeparateViewModel {
    var posts: [Post] = []
    var isLoading = false
    var errorMessage: String?
    var currentPage = 1
    var hasNextPage = false

    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
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
        currentPage = 1
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiService.fetchPosts(page: 1, limit: 10)
            posts = response.data
            hasNextPage = response.pagination.hasNext
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false

        // Preload second page so the list is scrollable enough for
        // .onAppear-based pagination to continue loading further pages.
        if hasNextPage && !isLoading && posts.count <= 10 {
            currentPage += 1
            await loadPosts()
        }
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

    func fetchPost(id: Int) async throws -> Post {
        try await apiService.fetchPost(id: id)
    }

    func createPost(title: String, content: String) async throws {
        _ = try await apiService.createPost(title: title, content: content)
    }

    func deletePost(id: Int) async throws {
        _ = try await apiService.deletePost(id: id)
    }
}
