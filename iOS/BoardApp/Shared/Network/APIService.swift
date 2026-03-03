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
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
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
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }
}
