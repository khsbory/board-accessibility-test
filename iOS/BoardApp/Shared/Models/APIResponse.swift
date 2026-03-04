import Foundation

struct PostListResponse: Codable {
    let data: [Post]
    let pagination: Pagination
}

struct Pagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int

    /// Computed: whether there is a next page (not in API response, derived from page/totalPages)
    var hasNext: Bool {
        page < totalPages
    }

    /// Computed: whether there is a previous page (not in API response, derived from page)
    var hasPrev: Bool {
        page > 1
    }
}

struct PostResponse: Codable {
    let data: Post
}

struct DeleteResponse: Codable {
    let message: String
}

struct CreatePostRequest: Codable {
    let title: String
    let content: String
}
