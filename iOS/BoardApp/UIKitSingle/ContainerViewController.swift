import UIKit

final class ContainerViewController: UIViewController {

    private var currentChild: UIViewController?
    private var listVC: SinglePostListVC?
    private let customNavBar = UIView()
    private let navTitleLabel = UILabel()
    private let backButton = UIButton(type: .system)
    private let homeButton = UIButton(type: .system)
    private let containerView = UIView()

    var onDismiss: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupCustomNavBar()
        setupContainerView()
        showList(animated: false)
    }

    private func setupCustomNavBar() {
        customNavBar.translatesAutoresizingMaskIntoConstraints = false
        customNavBar.backgroundColor = .systemBackground
        view.addSubview(customNavBar)

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .separator
        customNavBar.addSubview(separator)

        homeButton.translatesAutoresizingMaskIntoConstraints = false
        homeButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        homeButton.setTitle(" 홈", for: .normal)
        homeButton.addTarget(self, action: #selector(homeButtonTapped), for: .touchUpInside)
        homeButton.accessibilityLabel = "홈으로 돌아가기"
        homeButton.isHidden = true
        customNavBar.addSubview(homeButton)

        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.setTitle(" 뒤로", for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.isHidden = true
        customNavBar.addSubview(backButton)

        navTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        navTitleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        navTitleLabel.textAlignment = .center
        customNavBar.addSubview(navTitleLabel)

        NSLayoutConstraint.activate([
            customNavBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            customNavBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customNavBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customNavBar.heightAnchor.constraint(equalToConstant: 44),

            separator.leadingAnchor.constraint(equalTo: customNavBar.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: customNavBar.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: customNavBar.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),

            homeButton.leadingAnchor.constraint(equalTo: customNavBar.leadingAnchor, constant: 8),
            homeButton.centerYAnchor.constraint(equalTo: customNavBar.centerYAnchor),

            backButton.leadingAnchor.constraint(equalTo: customNavBar.leadingAnchor, constant: 8),
            backButton.centerYAnchor.constraint(equalTo: customNavBar.centerYAnchor),

            navTitleLabel.centerXAnchor.constraint(equalTo: customNavBar.centerXAnchor),
            navTitleLabel.centerYAnchor.constraint(equalTo: customNavBar.centerYAnchor),
            navTitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 8),
            navTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: customNavBar.trailingAnchor, constant: -60)
        ])
    }

    private func setupContainerView() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: customNavBar.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func transition(to newChild: UIViewController, forward: Bool, animated: Bool) {
        let oldChild = currentChild

        addChild(newChild)
        newChild.view.frame = containerView.bounds

        if animated, let oldView = oldChild?.view {
            let offsetX = forward ? containerView.bounds.width : -containerView.bounds.width
            newChild.view.frame.origin.x = offsetX
            containerView.addSubview(newChild.view)

            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
                newChild.view.frame.origin.x = 0
                oldView.frame.origin.x = forward ? -self.containerView.bounds.width : self.containerView.bounds.width
            } completion: { _ in
                oldChild?.willMove(toParent: nil)
                oldChild?.view.removeFromSuperview()
                oldChild?.removeFromParent()
                newChild.didMove(toParent: self)
            }
        } else {
            containerView.addSubview(newChild.view)
            oldChild?.willMove(toParent: nil)
            oldChild?.view.removeFromSuperview()
            oldChild?.removeFromParent()
            newChild.didMove(toParent: self)
        }

        currentChild = newChild
    }

    private func showList(animated: Bool) {
        navTitleLabel.text = "UIKit 단일 화면"
        backButton.isHidden = true
        homeButton.isHidden = false

        if listVC == nil {
            let vc = SinglePostListVC()
            vc.delegate = self
            listVC = vc
        }
        transition(to: listVC!, forward: false, animated: animated)

        // 스크롤이 상단 근처일 때만 자동 새로고침
        if let listVC = listVC {
            let isNearTop = listVC.tableView.contentOffset.y <= 44
            if isNearTop {
                listVC.refreshData()
            }
        }

        restoreAccessibilityFocus()
    }

    // MARK: - VoiceOver 접근성 초점 복원
    private func restoreAccessibilityFocus() {
        guard let listVC = listVC, let postId = listVC.lastSelectedPostId else { return }
        listVC.lastSelectedPostId = nil
        let neighbors = listVC.neighborPostIds
        listVC.neighborPostIds = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self, let listVC = self.listVC else { return }

            if listVC.wasPostDeleted {
                listVC.wasPostDeleted = false
                // 삭제된 경우: 이전 이웃 > 다음 이웃 > 작성 버튼
                let targetIndex: Int?
                if let prevId = neighbors?.previous,
                   let idx = listVC.posts.firstIndex(where: { $0.id == prevId }) {
                    targetIndex = idx
                } else if let nextId = neighbors?.next,
                          let idx = listVC.posts.firstIndex(where: { $0.id == nextId }) {
                    targetIndex = idx
                } else {
                    targetIndex = nil
                }

                if let idx = targetIndex {
                    let indexPath = IndexPath(row: idx, section: 0)
                    listVC.tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
                    if let cell = listVC.tableView.cellForRow(at: indexPath) {
                        UIAccessibility.post(notification: .screenChanged, argument: cell)
                    }
                } else {
                    // 게시글이 없으면 작성 버튼으로 초점
                    UIAccessibility.post(notification: .screenChanged, argument: listVC.createButton)
                }
            } else {
                // 삭제 안 된 경우: id로 현재 인덱스 찾기
                if let idx = listVC.posts.firstIndex(where: { $0.id == postId }) {
                    let indexPath = IndexPath(row: idx, section: 0)
                    listVC.tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
                    if let cell = listVC.tableView.cellForRow(at: indexPath) {
                        UIAccessibility.post(notification: .screenChanged, argument: cell)
                    }
                }
                // 못 찾으면 (페이지네이션 리셋 등) 조용히 스킵
            }
        }
    }

    @objc private func backButtonTapped() {
        showList(animated: true)
    }

    @objc private func homeButtonTapped() {
        onDismiss?()
    }
}

// MARK: - ContainerNavigationDelegate
extension ContainerViewController: ContainerNavigationDelegate {
    func navigateToDetail(postId: Int) {
        navTitleLabel.text = "게시글 상세"
        homeButton.isHidden = true
        backButton.isHidden = false
        let detailVC = SinglePostDetailVC(postId: postId)
        detailVC.delegate = self
        transition(to: detailVC, forward: true, animated: true)
    }

    func navigateToCreate() {
        navTitleLabel.text = "게시글 작성"
        homeButton.isHidden = true
        backButton.isHidden = false
        let createVC = SinglePostCreateVC()
        createVC.delegate = self
        transition(to: createVC, forward: true, animated: true)
    }

    func navigateBack() {
        showList(animated: true)
    }

    func refreshList() {
        // 작성/삭제 후에는 무조건 새로고침
        listVC?.wasPostDeleted = true
        listVC?.refreshData()
        showList(animated: true)
    }
}
