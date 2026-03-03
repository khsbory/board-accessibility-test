import Foundation

protocol ContainerNavigationDelegate: AnyObject {
    func navigateToDetail(postId: Int)
    func navigateToCreate()
    func navigateBack()
    func refreshList()
}
