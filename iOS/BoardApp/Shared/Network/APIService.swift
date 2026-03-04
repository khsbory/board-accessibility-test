import Foundation

protocol APIServiceProtocol {
    func fetchPosts(page: Int, limit: Int) async throws -> PostListResponse
    func fetchPost(id: Int) async throws -> Post
    func createPost(title: String, content: String) async throws -> Post
    func deletePost(id: Int) async throws -> String
}

final class APIService: APIServiceProtocol {
    static let shared = APIService()

    private let baseURL = "http://172.30.1.25:3000/api/posts"
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        // API already returns camelCase keys (createdAt, totalPages), no snake_case conversion needed
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO 8601 with fractional seconds first (e.g., "2026-03-02T04:22:49.004Z")
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }

            // Fallback to ISO 8601 without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
    }

    func fetchPosts(page: Int = 1, limit: Int = 10) async throws -> PostListResponse {
        guard var components = URLComponents(string: baseURL) else {
            throw APIError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        guard let url = components.url else {
            throw APIError.invalidURL
        }

        return try await request(url: url, type: PostListResponse.self)
    }

    func fetchPost(id: Int) async throws -> Post {
        guard let url = URL(string: "\(baseURL)/\(id)") else {
            throw APIError.invalidURL
        }
        let response: PostResponse = try await request(url: url, type: PostResponse.self)
        return response.data
    }

    func createPost(title: String, content: String) async throws -> Post {
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = CreatePostRequest(title: title, content: content)
        urlRequest.httpBody = try JSONEncoder().encode(body)

        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError(httpResponse.statusCode)
            }
            let postResponse = try decoder.decode(PostResponse.self, from: data)
            return postResponse.data
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            print("[APIService] Decoding error in createPost: \(error)")
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }

    func deletePost(id: Int) async throws -> String {
        guard let url = URL(string: "\(baseURL)/\(id)") else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"

        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError(httpResponse.statusCode)
            }
            let deleteResponse = try decoder.decode(DeleteResponse.self, from: data)
            return deleteResponse.message
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func request<T: Decodable>(url: URL, type: T.Type) async throws -> T {
        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError(httpResponse.statusCode)
            }
            return try decoder.decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            print("[APIService] Decoding error for \(T.self): \(error)")
            if let data = try? await session.data(from: url).0,
               let jsonString = String(data: data, encoding: .utf8) {
                print("[APIService] Raw JSON: \(jsonString.prefix(500))")
            }
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }
}
