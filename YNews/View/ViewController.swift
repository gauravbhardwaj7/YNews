//
//  ViewController.swift
//  YNews
//
//  Created by Gaurav Bhardwaj on 13/02/26.
//

import UIKit
import Combine

class ViewController: UIViewController {

    private let viewModel         = NewsViewModel()
    private let bookmarkViewModel = BookmarkViewModel()
    private var cancellables      = Set<AnyCancellable>()


    private lazy var searchTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder   = "Search here"
        tf.borderStyle   = .roundedRect
        tf.delegate = self
        tf.clearButtonMode = .whileEditing
        tf.layer.cornerRadius = 8
        tf.layer.backgroundColor = .init(gray: 0.1, alpha: 0.1)
        tf.addTarget(self, action: #selector(didSearchFieldChanged(_:)), for: .editingChanged)
        return tf
    }()


    private lazy var inlineBannerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 8
        v.isHidden = true
        return v
    }()

    private lazy var inlineBannerIconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        return iv
    }()

    private lazy var inlineBannerLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font         = .systemFont(ofSize: 12, weight: .medium)
        l.numberOfLines = 0
        return l
    }()


    private lazy var loadingIndicatorView: UIActivityIndicatorView = {
        let i = UIActivityIndicatorView(style: .large)
        i.translatesAutoresizingMaskIntoConstraints = false
        i.hidesWhenStopped = true
        return i
    }()

    private lazy var loadingLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text          = "Loading articles…"
        l.font          = .systemFont(ofSize: 14)
        l.textColor     = .secondaryLabel
        l.textAlignment = .center
        l.isHidden      = true
        return l
    }()

    // MARK: - Full-screen error

    private lazy var errorContainerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

    private lazy var errorIconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 52, weight: .thin)
        iv.tintColor = .secondaryLabel
        return iv
    }()

    private lazy var errorTitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font          = .systemFont(ofSize: 17, weight: .semibold)
        l.textAlignment = .center
        l.textColor     = .label
        return l
    }()

    private lazy var errorMessageLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font          = .systemFont(ofSize: 14)
        l.textColor     = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private lazy var retryButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.title             = "Try Again"
        cfg.cornerStyle       = .medium
        cfg.baseBackgroundColor = .systemBlue
        cfg.contentInsets     = .init(top: 10, leading: 24, bottom: 10, trailing: 24)
        let b = UIButton(configuration: cfg)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(didTapRetry), for: .touchUpInside)
        return b
    }()


    private lazy var loadingMoreIndicator: UIActivityIndicatorView = {
        let i = UIActivityIndicatorView(style: .medium)
        i.translatesAutoresizingMaskIntoConstraints = false
        i.hidesWhenStopped = true
        return i
    }()

    private lazy var loadingMoreLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font          = .systemFont(ofSize: 12)
        l.textColor     = .tertiaryLabel
        l.textAlignment = .center
        l.isHidden      = true
        return l
    }()


    private lazy var collectionView: UICollectionView = {
        let size  = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(80))
        let item  = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
        group.interItemSpacing = .fixed(.spacing_5)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = .spacing_5
        section.contentInsets = .init(top: .spacing_4, leading: 0, bottom: .spacing_7, trailing: 0)
        let layout = UICollectionViewCompositionalLayout(section: section)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(NewsCellView.self, forCellWithReuseIdentifier: "NewsCell")
        cv.dataSource = self
        cv.delegate   = self

        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(didPulledToRefresh), for: .valueChanged)
        cv.refreshControl = rc

        return cv
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
        title = "News"
        view.backgroundColor = .systemBackground

        setupBookmarkBarButton()
        setupTestNotificationButton()
        setupLayout()
        bindViewModel()

        bookmarkViewModel.loadBookmarks()
        viewModel.paginator = Paginator(delegate: viewModel)

        NotificationCenter.default.addObserver(self, selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePendingDeepLinkNotification),
            name: DeepLinkRouter.didSetPendingArticleNotification, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bookmarkViewModel.loadBookmarks()
        collectionView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tryOpenPendingDeepLink()
    }


    private func setupLayout() {

        inlineBannerView.addSubview(inlineBannerIconView)
        inlineBannerView.addSubview(inlineBannerLabel)


        errorContainerView.addSubview(errorIconView)
        errorContainerView.addSubview(errorTitleLabel)
        errorContainerView.addSubview(errorMessageLabel)
        errorContainerView.addSubview(retryButton)

        [searchTextField, inlineBannerView, collectionView,
         loadingIndicatorView, loadingLabel,
         loadingMoreIndicator, loadingMoreLabel,
         errorContainerView].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([


            searchTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: .spacing_4),
            searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: .spacing_4),
            searchTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -.spacing_4),


            inlineBannerView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: .spacing_2),
            inlineBannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: .spacing_4),
            inlineBannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -.spacing_4),

            inlineBannerIconView.leadingAnchor.constraint(equalTo: inlineBannerView.leadingAnchor, constant: .spacing_4),
            inlineBannerIconView.centerYAnchor.constraint(equalTo: inlineBannerView.centerYAnchor),
            inlineBannerIconView.widthAnchor.constraint(equalToConstant: 20),
            inlineBannerIconView.heightAnchor.constraint(equalToConstant: 20),

            inlineBannerLabel.topAnchor.constraint(equalTo: inlineBannerView.topAnchor, constant: 8),
            inlineBannerLabel.bottomAnchor.constraint(equalTo: inlineBannerView.bottomAnchor, constant: -8),
            inlineBannerLabel.leadingAnchor.constraint(equalTo: inlineBannerIconView.trailingAnchor, constant: 8),
            inlineBannerLabel.trailingAnchor.constraint(equalTo: inlineBannerView.trailingAnchor, constant: -.spacing_4),

         
            collectionView.topAnchor.constraint(equalTo: inlineBannerView.bottomAnchor, constant: .spacing_2),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),


            loadingIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -16),
            loadingLabel.topAnchor.constraint(equalTo: loadingIndicatorView.bottomAnchor, constant: 8),
            loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

        
            loadingMoreIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingMoreIndicator.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -.spacing_4),
            loadingMoreLabel.bottomAnchor.constraint(equalTo: loadingMoreIndicator.topAnchor, constant: -4),
            loadingMoreLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

        
            errorContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: .spacing_7),
            errorContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -.spacing_7),

            errorIconView.topAnchor.constraint(equalTo: errorContainerView.topAnchor),
            errorIconView.centerXAnchor.constraint(equalTo: errorContainerView.centerXAnchor),
            errorIconView.widthAnchor.constraint(equalToConstant: 64),
            errorIconView.heightAnchor.constraint(equalToConstant: 64),

            errorTitleLabel.topAnchor.constraint(equalTo: errorIconView.bottomAnchor, constant: .spacing_4),
            errorTitleLabel.leadingAnchor.constraint(equalTo: errorContainerView.leadingAnchor),
            errorTitleLabel.trailingAnchor.constraint(equalTo: errorContainerView.trailingAnchor),

            errorMessageLabel.topAnchor.constraint(equalTo: errorTitleLabel.bottomAnchor, constant: .spacing_2),
            errorMessageLabel.leadingAnchor.constraint(equalTo: errorContainerView.leadingAnchor),
            errorMessageLabel.trailingAnchor.constraint(equalTo: errorContainerView.trailingAnchor),

            retryButton.topAnchor.constraint(equalTo: errorMessageLabel.bottomAnchor, constant: .spacing_5),
            retryButton.centerXAnchor.constraint(equalTo: errorContainerView.centerXAnchor),
            retryButton.bottomAnchor.constraint(equalTo: errorContainerView.bottomAnchor),
        ])
    }



    private func bindViewModel() {
        viewModel.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in self?.applyState(state) }
            .store(in: &cancellables)

        viewModel.$articles
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                collectionView.reloadData()
                collectionView.refreshControl?.endRefreshing()
            }
            .store(in: &cancellables)

        viewModel.$isLoadingNextPage
            .receive(on: RunLoop.main)
            .sink { [weak self] loading in
                if loading {
                    self?.loadingMoreIndicator.startAnimating()
                    self?.loadingMoreLabel.isHidden = false
                } else {
                    self?.loadingMoreIndicator.stopAnimating()
                    self?.loadingMoreLabel.isHidden = true
                }
            }
            .store(in: &cancellables)


        viewModel.$isOnline
            .receive(on: RunLoop.main)
            .sink { [weak self] online in
                guard let self else { return }
                collectionView.refreshControl?.isEnabled = online
                if !online {
                    collectionView.refreshControl?.endRefreshing()
                }
            }
            .store(in: &cancellables)

        bookmarkViewModel.$bookmarkedArticles
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateBookmarkBarButtonVisibility() }
            .store(in: &cancellables)
    }



    private func applyState(_ state: NewsViewState) {

        loadingIndicatorView.stopAnimating()
        loadingLabel.isHidden       = true
        errorContainerView.isHidden = true
        inlineBannerView.isHidden   = true
        collectionView.isHidden     = true

        switch state {

        case .idle:
            break

        case .loading:
            if viewModel.articles.isEmpty {
                loadingIndicatorView.startAnimating()
                loadingLabel.isHidden = false
            } else {

                collectionView.isHidden = false
            }

        case .loaded:
            collectionView.isHidden = false

        case .cachedData(let networkError):
            collectionView.isHidden   = false
            inlineBannerView.isHidden = false
            configureBanner(for: networkError)

        case .error(let networkError):
            errorContainerView.isHidden = false
            configureFullScreenError(for: networkError)
        }
    }

    private func configureBanner(for error: NetworkError) {
        let icon: UIImage?
        let tint: UIColor
        let text: String

        switch error {
        case .noInternet:
            icon = UIImage(systemName: "wifi.slash")
            tint = .systemOrange
            text = "No internet connection"
        case .serverError(let msg):
            icon = UIImage(systemName: "exclamationmark.triangle")
            tint = .systemRed
            text = "Server error — showing cached articles. \(msg)"
        case .requestFailed(let msg):
            icon = UIImage(systemName: "clock.badge.xmark")
            tint = .systemOrange
            text = "Request failed — showing cached articles. \(msg)"
        }

        inlineBannerView.backgroundColor     = tint.withAlphaComponent(0.12)
        inlineBannerIconView.image           = icon
        inlineBannerIconView.tintColor       = tint
        inlineBannerLabel.text               = text
        inlineBannerLabel.textColor          = tint
    }


    private func configureFullScreenError(for error: NetworkError) {
        errorIconView.image      = UIImage(systemName: error.icon)
        errorTitleLabel.text     = error.title
        errorMessageLabel.text   = error.message

        switch error {
        case .noInternet:
            errorIconView.tintColor  = .systemOrange
            errorTitleLabel.textColor = .label
        case .serverError, .requestFailed:
            errorIconView.tintColor  = .systemRed
            errorTitleLabel.textColor = .label
        }
    }

 

    @objc private func didTapRetry() { viewModel.retry() }



    @objc private func handleAppDidBecomeActive()          { tryOpenPendingDeepLink() }
    @objc private func handlePendingDeepLinkNotification() { tryOpenPendingDeepLink() }

    private func tryOpenPendingDeepLink() {
        DispatchQueue.main.async { [weak self] in self?.openPendingDeepLinkIfNeeded() }
    }

    private static var deepLinkRetryCount = 0
    private static let deepLinkMaxRetries = 3

    private func openPendingDeepLinkIfNeeded() {
        guard let article = DeepLinkRouter.shared.consumePendingArticle() else { return }
        guard let nav = navigationController, isViewLoaded else {
            DeepLinkRouter.shared.setPendingArticle(article)
            guard Self.deepLinkRetryCount < Self.deepLinkMaxRetries else { Self.deepLinkRetryCount = 0; return }
            Self.deepLinkRetryCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in self?.openPendingDeepLinkIfNeeded() }
            return
        }
        Self.deepLinkRetryCount = 0
        if nav.viewControllers.count > 1 { nav.popToViewController(self, animated: false) }
        nav.pushViewController(NewsDetailViewController(article: article), animated: true)
    }



    private func setupBookmarkBarButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Bookmarks", style: .plain, target: self, action: #selector(didTapBookmarkButton))
        updateBookmarkBarButtonVisibility()
    }

    private func updateBookmarkBarButtonVisibility() {
        navigationItem.rightBarButtonItem?.isHidden = !bookmarkViewModel.hasBookmarks
    }

    @objc private func didTapBookmarkButton() {
        navigationController?.pushViewController(
            BookmarkedArticlesViewController(viewModel: bookmarkViewModel), animated: true)
    }

    private func setupTestNotificationButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Notify", style: .plain, target: self, action: #selector(didTapTestNotification))
    }

    @objc private func didTapTestNotification() {
        guard let article = viewModel.articles.randomElement() else {
            present(UIAlertController.present(title: "No articles", message: "Load some news first."), animated: true)
            return
        }
        NotificationService.scheduleTrendingNotification(for: article, delaySeconds: 3)
        present(UIAlertController.present(
            title: "Notification scheduled",
            message: "You'll see a trending notification in 3 seconds."), animated: true)
    }
}


extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate, NewsCellViewDelegate {

    func newsCellDidTap(_ cell: NewsCellView, article: Article) {
        navigationController?.pushViewController(NewsDetailViewController(article: article), animated: true)
    }

    func newsCellDidTapBookmark(_ cell: NewsCellView, article: Article) {
        bookmarkViewModel.toggleBookmark(article)
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.articles.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsCell", for: indexPath) as? NewsCellView else {
            return UICollectionViewCell()
        }
        let article = viewModel.articles[indexPath.row]
        cell.delegate = self
        cell.setData(article: article, isBookmarked: bookmarkViewModel.isBookmarked(article))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        viewModel.paginator?.viewingItemAt(indexPath: indexPath, currentItemCount: viewModel.articles.count)
    }

    @objc private func didSearchFieldChanged(_ tf: UITextField) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.viewModel.query = tf.text }
    }

    @objc private func didPulledToRefresh() {
        guard viewModel.isOnline else {
            collectionView.refreshControl?.endRefreshing()
            return
        }
        Task {
            await viewModel.pullToRefresh()
            await MainActor.run { collectionView.refreshControl?.endRefreshing() }
        }
    }
}


private extension UIAlertController {
    static func present(title: String, message: String) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        return alert
    }
}


extension ViewController: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        viewModel.query = nil
        textField.resignFirstResponder()
        Task {
            await viewModel.pullToRefresh()
        }
        return true
    }
}
