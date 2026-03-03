import UIKit

final class PostCreateViewController: UIViewController {

    private let titleTextField = UITextField()
    private let contentTextView = UITextView()
    private let submitButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    private let apiService: APIServiceProtocol
    var onPostCreated: (() -> Void)?

    init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "게시글 작성"
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        titleTextField.placeholder = "제목을 입력하세요"
        titleTextField.borderStyle = .roundedRect
        titleTextField.font = .systemFont(ofSize: 16)

        contentTextView.translatesAutoresizingMaskIntoConstraints = false
        contentTextView.font = .systemFont(ofSize: 16)
        contentTextView.layer.borderColor = UIColor.systemGray4.cgColor
        contentTextView.layer.borderWidth = 1
        contentTextView.layer.cornerRadius = 8

        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.setTitle("등록", for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.backgroundColor = .systemBlue
        submitButton.layer.cornerRadius = 12
        submitButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true

        view.addSubview(titleTextField)
        view.addSubview(contentTextView)
        view.addSubview(submitButton)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            titleTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleTextField.heightAnchor.constraint(equalToConstant: 44),

            contentTextView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 16),
            contentTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            contentTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            contentTextView.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -16),

            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            submitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            submitButton.heightAnchor.constraint(equalToConstant: 44),

            activityIndicator.centerXAnchor.constraint(equalTo: submitButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: submitButton.centerYAnchor)
        ])
    }

    @objc private func submitButtonTapped() {
        guard let title = titleTextField.text, !title.isEmpty else {
            showError("제목을 입력하세요.")
            return
        }
        guard let content = contentTextView.text, !content.isEmpty else {
            showError("내용을 입력하세요.")
            return
        }

        submitButton.isEnabled = false
        activityIndicator.startAnimating()

        Task {
            do {
                _ = try await apiService.createPost(title: title, content: content)
                await MainActor.run {
                    onPostCreated?()
                    navigationController?.popViewController(animated: true)
                }
            } catch {
                await MainActor.run {
                    submitButton.isEnabled = true
                    activityIndicator.stopAnimating()
                    showError(error.localizedDescription)
                }
            }
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
