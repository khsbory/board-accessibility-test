import UIKit

final class PostListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let createButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private let apiService: APIServiceProtocol
    private var posts: [Post] = []
    private var currentPage = 1
    private var hasNextPage = false
    private var isLoading = false
    private var needsRefreshOnAppear = false

    var onDismiss: (() -> Void)?

    init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UIKit 독립 화면"
        view.backgroundColor = .systemBackground
        setupHomeButton()
        setupTableView()
        setupCreateButton()
        setupActivityIndicator()
        loadPosts()
    }

    private func setupHomeButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(dismissToHome)
        )
        navigationItem.leftBarButtonItem?.title = "홈"
        navigationItem.leftBarButtonItem?.accessibilityLabel = "홈으로 돌아가기"
    }

    @objc private func dismissToHome() {
        onDismiss?()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if needsRefreshOnAppear {
            needsRefreshOnAppear = false
            refreshPosts()
        } else {
            // 스크롤이 상단 근처일 때만 자동 새로고침
            let isNearTop = tableView.contentOffset.y <= 44
            if isNearTop {
                refreshPosts()
            }
        }
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.prefetchDataSource = self
        tableView.register(PostCell.self, forCellReuseIdentifier: PostCell.reuseIdentifier)
        view.addSubview(tableView)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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
                    self.tableView.reloadData()
                    self.activityIndicator.stopAnimating()
                    self.tableView.refreshControl?.endRefreshing()
                    self.isLoading = false
                    self.loadMoreIfNeeded()
                }
            } catch {
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.tableView.refreshControl?.endRefreshing()
                    self.isLoading = false
                    self.showError(error)
                }
            }
        }
    }

    /// Auto-load next page if content does not fill the visible area
    private func loadMoreIfNeeded() {
        guard hasNextPage, !isLoading else { return }
        // After layout, check if content is shorter than the visible table height
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.tableView.contentSize.height <= self.tableView.frame.height {
                self.loadPosts()
            }
        }
    }

    private func refreshPosts() {
        currentPage = 1
        loadPosts(replacing: true)
    }

    private func showError(_ error: Error) {
        let alert = UIAlertController(title: "오류", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    @objc private func handlePullToRefresh() {
        refreshPosts()
    }

    @objc private func createButtonTapped() {
        let createVC = PostCreateViewController()
        createVC.onPostCreated = { [weak self] in
            self?.needsRefreshOnAppear = true
        }
        navigationController?.pushViewController(createVC, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension PostListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.reuseIdentifier, for: indexPath) as? PostCell else {
            return UITableViewCell()
        }
        cell.configure(with: posts[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension PostListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let post = posts[indexPath.row]
        let detailVC = PostDetailViewController(postId: post.id)
        detailVC.onPostDeleted = { [weak self] in
            self?.needsRefreshOnAppear = true
        }
        navigationController?.pushViewController(detailVC, animated: true)
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
extension PostListViewController: UITableViewDataSourcePrefetching {
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

// MARK: - PostCell
final class PostCell: UITableViewCell {
    static let reuseIdentifier = "PostCell"

    private let titleLabel = UILabel()
    private let dateLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.numberOfLines = 1

        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .systemFont(ofSize: 13)
        dateLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [titleLabel, dateLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with post: Post) {
        titleLabel.text = post.title
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        dateLabel.text = formatter.string(from: post.createdAt)
    }
}
