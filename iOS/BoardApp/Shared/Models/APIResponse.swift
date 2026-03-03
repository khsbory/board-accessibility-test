import Foundation

struct PostListResponse: Codable {
    let data: [Post]
    let pagination: Pagination
}

struct Pagination: Codable {
    let page: Int
    let limit: Int
    let totalItems: Int
    let totalPages: Int
    let hasNext: Bool
    let hasPrev: Bool
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
