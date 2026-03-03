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

    func refreshPosts() async {
        currentPage = 1
        posts = []
        await loadPosts()
    }

    func loadNextPageIfNeeded(currentPost: Post) async {
        guard hasNextPage, !isLoading else { return }
        guard let lastPost = posts.last, lastPost.id == currentPost.id else { return }
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
