import XCTest
@testable import BoardApp

final class MockAPIService: APIServiceProtocol {
    var fetchPostsResult: Result<PostListResponse, Error> = .failure(APIError.unknown)
    var fetchPostResult: Result<Post, Error> = .failure(APIError.unknown)
    var createPostResult: Result<Post, Error> = .failure(APIError.unknown)
    var deletePostResult: Result<String, Error> = .failure(APIError.unknown)

    var fetchPostsCalled = false
    var fetchPostCalled = false
    var createPostCalled = false
    var deletePostCalled = false

    var lastFetchPostsPage: Int?
    var lastFetchPostsLimit: Int?
    var lastFetchPostId: Int?
    var lastCreateTitle: String?
    var lastCreateContent: String?
    var lastDeletePostId: Int?

    func fetchPosts(page: Int, limit: Int) async throws -> PostListResponse {
        fetchPostsCalled = true
        lastFetchPostsPage = page
        lastFetchPostsLimit = limit
        return try fetchPostsResult.get()
    }

    func fetchPost(id: Int) async throws -> Post {
        fetchPostCalled = true
        lastFetchPostId = id
        return try fetchPostResult.get()
    }

    func createPost(title: String, content: String) async throws -> Post {
        createPostCalled = true
        lastCreateTitle = title
        lastCreateContent = content
        return try createPostResult.get()
    }

    func deletePost(id: Int) async throws -> String {
        deletePostCalled = true
        lastDeletePostId = id
        return try deletePostResult.get()
    }
}

final class APIServiceTests: XCTestCase {

    private var mockService: MockAPIService!

    override func setUp() {
        super.setUp()
        mockService = MockAPIService()
    }

    func testFetchPostsSuccess() async throws {
        let date = Date()
        let posts = [
            Post(id: 1, title: "글 1", content: "내용 1", createdAt: date, updatedAt: date),
            Post(id: 2, title: "글 2", content: "내용 2", createdAt: date, updatedAt: date)
        ]
        let pagination = Pagination(page: 1, limit: 10, total: 2, totalPages: 1)
        let response = PostListResponse(data: posts, pagination: pagination)
        mockService.fetchPostsResult = .success(response)

        let result = try await mockService.fetchPosts(page: 1, limit: 10)

        XCTAssertTrue(mockService.fetchPostsCalled)
        XCTAssertEqual(mockService.lastFetchPostsPage, 1)
        XCTAssertEqual(mockService.lastFetchPostsLimit, 10)
        XCTAssertEqual(result.data.count, 2)
        XCTAssertEqual(result.pagination.total, 2)
    }

    func testFetchPostSuccess() async throws {
        let date = Date()
        let post = Post(id: 5, title: "상세 글", content: "상세 내용", createdAt: date, updatedAt: date)
        mockService.fetchPostResult = .success(post)

        let result = try await mockService.fetchPost(id: 5)

        XCTAssertTrue(mockService.fetchPostCalled)
        XCTAssertEqual(mockService.lastFetchPostId, 5)
        XCTAssertEqual(result.id, 5)
        XCTAssertEqual(result.title, "상세 글")
    }

    func testCreatePostSuccess() async throws {
        let date = Date()
        let newPost = Post(id: 10, title: "새 글", content: "새 내용", createdAt: date, updatedAt: date)
        mockService.createPostResult = .success(newPost)

        let result = try await mockService.createPost(title: "새 글", content: "새 내용")

        XCTAssertTrue(mockService.createPostCalled)
        XCTAssertEqual(mockService.lastCreateTitle, "새 글")
        XCTAssertEqual(mockService.lastCreateContent, "새 내용")
        XCTAssertEqual(result.id, 10)
    }

    func testDeletePostSuccess() async throws {
        mockService.deletePostResult = .success("삭제되었습니다.")

        let message = try await mockService.deletePost(id: 3)

        XCTAssertTrue(mockService.deletePostCalled)
        XCTAssertEqual(mockService.lastDeletePostId, 3)
        XCTAssertEqual(message, "삭제되었습니다.")
    }

    func testFetchPostsFailure() async {
        mockService.fetchPostsResult = .failure(APIError.networkError(URLError(.notConnectedToInternet)))

        do {
            _ = try await mockService.fetchPosts(page: 1, limit: 10)
            XCTFail("Should have thrown")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }

    func testAPIErrorDescriptions() {
        XCTAssertNotNil(APIError.invalidURL.errorDescription)
        XCTAssertNotNil(APIError.unknown.errorDescription)
        XCTAssertNotNil(APIError.serverError(500).errorDescription)
        XCTAssertTrue(APIError.serverError(500).errorDescription!.contains("500"))
    }
}
