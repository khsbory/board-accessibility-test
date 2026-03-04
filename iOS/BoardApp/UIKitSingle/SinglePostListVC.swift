import UIKit

final class SinglePostListVC: UIViewController {

    weak var delegate: ContainerNavigationDelegate?

    let tableView = UITableView(frame: .zero, style: .plain)
    let createButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private let apiService: APIServiceProtocol = APIService.shared
    private(set) var posts: [Post] = []
    private var currentPage = 1
    private var hasNextPage = false
    private var isLoading = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale = Locale(identifier: "ko_KR")
        return f
    }()

    // MARK: - VoiceOver 접근성 초점 추적
    var lastSelectedPostId: Int?
    var neighborPostIds: (previous: Int?, next: Int?)?
    var wasPostDeleted = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTableView()
        setupCreateButton()
        setupActivityIndicator()
        loadPosts()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.prefetchDataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60)
        ])
    }

    private func setupCreateButton() {
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.setTitle("게시글 작성", for: .normal)
        createButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        createButton.backgroundColor = .systemBlue
        createButton.setTitleColor(.white, for: .normal)
        createButton.layer.cornerRadius = 12
        createButton.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
        view.addSubview(createButton)

        NSLayoutConstraint.activate([
            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            createButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadPosts(replacing: Bool = false) {
        guard !isLoading else { return }
        isLoading = true
        activityIndicator.startAnimating()

        Task {
            do {
                let response = try await apiService.fetchPosts(page: currentPage, limit: 10)
                await MainActor.run {
                    if replacing {
                        self.posts = response.data
                    } else {
                        self.posts.append(contentsOf: response.data)
                    }
                    self.hasNextPage = response.pagination.hasNext
                    self.currentPage += 1
                    self.isLoading = false
                    self.tableView.reloadData()
                    self.activityIndicator.stopAnimating()
                    self.tableView.refreshControl?.endRefreshing()
                    self.loadMoreIfNeeded()
                }
            } catch {
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.tableView.refreshControl?.endRefreshing()
                    self.isLoading = false
                }
            }
        }
    }

    /// Auto-load next page if content does not fill the visible area
    private func loadMoreIfNeeded() {
        guard hasNextPage, !isLoading else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.tableView.contentSize.height <= self.tableView.frame.height {
                self.loadPosts()
            }
        }
    }

    @objc private func createButtonTapped() {
        delegate?.navigateToCreate()
    }

    @objc private func handlePullToRefresh() {
        refreshData()
    }

    /// Resets pagination state and reloads posts from the first page.
    /// Uses atomic swap: keeps current data visible until new data arrives.
    /// Called externally by ContainerViewController after create/delete operations.
    func refreshData() {
        currentPage = 1
        hasNextPage = false
        isLoading = false
        loadPosts(replacing: true)
    }
}

// MARK: - UITableViewDataSource
extension SinglePostListVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let post = posts[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = post.title
        config.secondaryText = Self.dateFormatter.string(from: post.createdAt)
        cell.contentConfiguration = config
        cell.accessibilityTraits = .button
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SinglePostListVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let post = posts[indexPath.row]
        lastSelectedPostId = post.id
        wasPostDeleted = false
        neighborPostIds = (
            previous: indexPath.row > 0 ? posts[indexPath.row - 1].id : nil,
            next: indexPath.row < posts.count - 1 ? posts[indexPath.row + 1].id : nil
        )
        delegate?.navigateToDetail(postId: post.id)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height

        // Trigger when user scrolls within 200pt of the bottom
        guard contentHeight > height else { return }
        if offsetY > contentHeight - height - 200, hasNextPage, !isLoading {
            loadPosts()
        }
    }
}

// MARK: - UITableViewDataSourcePrefetching
extension SinglePostListVC: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        // Trigger pagination when prefetching rows near the end
        guard hasNextPage, !isLoading else { return }
        let threshold = max(posts.count - 3, 0)
        for indexPath in indexPaths where indexPath.row >= threshold {
            loadPosts()
            break
        }
    }
}
