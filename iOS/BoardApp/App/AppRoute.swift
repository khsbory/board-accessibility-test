import Foundation

enum AppRoute: Hashable {
    // Main menu destinations
    case uikitSeparate
    case uikitSingle
    case swiftUISeparate
    case swiftUISingle

    // SwiftUI Separate sub-routes
    case separateDetail(Int)
    case separateCreate
}
