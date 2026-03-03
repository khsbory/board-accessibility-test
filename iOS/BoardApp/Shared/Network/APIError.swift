import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다."
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        case .decodingError(let error):
            return "데이터 처리 오류: \(error.localizedDescription)"
        case .serverError(let code):
            return "서버 오류 (코드: \(code))"
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
