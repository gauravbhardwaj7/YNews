//
//  BookmarkedArticlesViewController.swift
//  YNews
//
//  Created by Gaurav Bhardwaj on 14/02/26.
//

import UIKit
import Combine

class BookmarkedArticlesViewController: UIViewController {

    private let viewModel: BookmarkViewModel
    private var cancellables = Set<AnyCancellable>()

    private lazy var collectionView: UICollectionView = {
        let layout: UICollectionViewCompositionalLayout = {
            let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(80))
            let item = NSCollectionLayoutItem(layoutSize: size)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
            group.interItemSpacing = .fixed(.spacing_4)
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = .spacing_4
            section.contentInsets = .init(top: .spacing_4, leading: 0, bottom: .spacing_7, trailing: 0)
            return .init(section: section)
        }()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(NewsCellView.self, forCellWithReuseIdentifier: "NewsCell")
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "No bookmarked articles"
        label.font = .preferredFont(forTextStyle: .title2)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    init(viewModel: BookmarkViewModel = BookmarkViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bookmarks"
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        viewModel.loadBookmarks()

        viewModel.$bookmarkedArticles
            .receive(on: RunLoop.main)
            .sink { [weak self] articles in
                self?.collectionView.reloadData()
                self?.emptyStateLabel.isHidden = !articles.isEmpty
            }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadBookmarks()
    }
}

extension BookmarkedArticlesViewController: UICollectionViewDataSource, UICollectionViewDelegate, NewsCellViewDelegate {

    func newsCellDidTap(_ cell: NewsCellView, article: Article) {
        let detailVC = NewsDetailViewController(article: article)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func newsCellDidTapBookmark(_ cell: NewsCellView, article: Article) {
        viewModel.removeBookmark(article)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.bookmarkedArticles.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsCell", for: indexPath) as? NewsCellView else {
            return UICollectionViewCell()
        }
        let article = viewModel.bookmarkedArticles[indexPath.item]
        cell.delegate = self
        cell.setData(article: article, isBookmarked: true)
        return cell
    }
}
