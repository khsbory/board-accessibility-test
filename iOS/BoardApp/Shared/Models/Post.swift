import Foundation

struct Post: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
}
