import UIKit

final class PostDetailViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private let contentLabel = UILabel()
    private let deleteButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private let apiService: APIServiceProtocol
    private let postId: Int
    var onPostDeleted: (() -> Void)?

    init(postId: Int, apiService: APIServiceProtocol = APIService.shared) {
        self.postId = postId
        self.apiService = apiService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "게시글 상세"
        view.backgroundColor = .systemBackground
        setupUI()
        loadPost()
    }

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill
        scrollView.addSubview(contentStack)

        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.numberOfLines = 0

        dateLabel.font = .systemFont(ofSize: 14)
        dateLabel.textColor = .secondaryLabel

        contentLabel.font = .systemFont(ofSize: 16)
        contentLabel.numberOfLines = 0

        deleteButton.setTitle("삭제", for: .normal)
        deleteButton.setTitleColor(.white, for: .normal)
        deleteButton.backgroundColor = .systemRed
        deleteButton.layer.cornerRadius = 12
        deleteButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        deleteButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(dateLabel)
        contentStack.addArrangedSubview(contentLabel)
        contentStack.addArrangedSubview(deleteButton)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadPost() {
        activityIndicator.startAnimating()
        contentStack.isHidden = true

        Task {
            do {
                let post = try await apiService.fetchPost(id: postId)
                await MainActor.run {
                    titleLabel.text = post.title
                    let formatter = DateFormatter()
                    formatter.dateStyle = .long
                    formatter.timeStyle = .short
                    formatter.locale = Locale(identifier: "ko_KR")
                    dateLabel.text = formatter.string(from: post.createdAt)
                    contentLabel.text = post.content
                    contentStack.isHidden = false
                    activityIndicator.stopAnimating()
                }
            } catch {
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    showError(error)
                }
            }
        }
    }

    @objc private func deleteButtonTapped() {
        let alert = UIAlertController(title: "삭제 확인", message: "이 게시글을 삭제하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.deletePost()
        })
        present(alert, animated: true)
    }

    private func deletePost() {
        Task {
            do {
                _ = try await apiService.deletePost(id: postId)
                await MainActor.run {
                    onPostDeleted?()
                    navigationController?.popViewController(animated: true)
                }
            } catch {
                await MainActor.run {
                    showError(error)
                }
            }
        }
    }

    private func showError(_ error: Error) {
        let alert = UIAlertController(title: "오류", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
