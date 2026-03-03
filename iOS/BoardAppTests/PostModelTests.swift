import XCTest
@testable import BoardApp

final class PostModelTests: XCTestCase {

    private var decoder: JSONDecoder!

    override func setUp() {
        super.setUp()
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
    }

    func testPostDecoding() throws {
        let json = """
        {
            "id": 1,
            "title": "테스트 게시글",
            "content": "테스트 내용입니다.",
            "created_at": "2024-01-15T10:30:00Z",
            "updated_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let post = try decoder.decode(Post.self, from: json)

        XCTAssertEqual(post.id, 1)
        XCTAssertEqual(post.title, "테스트 게시글")
        XCTAssertEqual(post.content, "테스트 내용입니다.")
        XCTAssertNotNil(post.createdAt)
        XCTAssertNotNil(post.updatedAt)
    }

    func testPostListResponseDecoding() throws {
        let json = """
        {
            "data": [
                {
                    "id": 1,
                    "title": "첫번째 글",
                    "content": "내용 1",
                    "created_at": "2024-01-15T10:30:00Z",
                    "updated_at": "2024-01-15T10:30:00Z"
                },
                {
                    "id": 2,
                    "title": "두번째 글",
                    "content": "내용 2",
                    "created_at": "2024-01-16T11:00:00Z",
                    "updated_at": "2024-01-16T11:00:00Z"
                }
            ],
            "pagination": {
                "page": 1,
                "limit": 10,
                "total_items": 2,
                "total_pages": 1,
                "has_next": false,
                "has_prev": false
            }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PostListResponse.self, from: json)

        XCTAssertEqual(response.data.count, 2)
        XCTAssertEqual(response.data[0].title, "첫번째 글")
        XCTAssertEqual(response.data[1].title, "두번째 글")
        XCTAssertEqual(response.pagination.page, 1)
        XCTAssertEqual(response.pagination.totalItems, 2)
        XCTAssertEqual(response.pagination.totalPages, 1)
        XCTAssertFalse(response.pagination.hasNext)
        XCTAssertFalse(response.pagination.hasPrev)
    }

    func testPostResponseDecoding() throws {
        let json = """
        {
            "data": {
                "id": 5,
                "title": "단일 게시글",
                "content": "상세 내용",
                "created_at": "2024-02-01T09:00:00Z",
                "updated_at": "2024-02-01T09:00:00Z"
            }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PostResponse.self, from: json)

        XCTAssertEqual(response.data.id, 5)
        XCTAssertEqual(response.data.title, "단일 게시글")
    }

    func testDeleteResponseDecoding() throws {
        let json = """
        {
            "message": "게시글이 삭제되었습니다."
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(DeleteResponse.self, from: json)

        XCTAssertEqual(response.message, "게시글이 삭제되었습니다.")
    }

    func testPostHashable() {
        let date = Date()
        let post1 = Post(id: 1, title: "Test", content: "Content", createdAt: date, updatedAt: date)
        let post2 = Post(id: 1, title: "Test", content: "Content", createdAt: date, updatedAt: date)

        XCTAssertEqual(post1, post2)
        XCTAssertEqual(post1.hashValue, post2.hashValue)
    }

    func testPostIdentifiable() {
        let date = Date()
        let post = Post(id: 42, title: "Test", content: "Content", createdAt: date, updatedAt: date)
        XCTAssertEqual(post.id, 42)
    }
}
