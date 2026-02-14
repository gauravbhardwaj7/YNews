//
//  NewsCellView.swift
//  YNews
//
//  Created by Gaurav Bhardwaj on 13/02/26.
//

import Foundation
import UIKit

protocol NewsCellViewDelegate: AnyObject {
    func newsCellDidTap(_ cell: NewsCellView, article: Article)
    func newsCellDidTapBookmark(_ cell: NewsCellView, article: Article)
}

class NewsCellView: UICollectionViewCell {

    weak var delegate: NewsCellViewDelegate?
    private var article: Article?
    private var currentImageURL: URL?


    private static let placeholderImage = UIImage(systemName: "photo")

    private lazy var newsImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Self.placeholderImage
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 72).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 72).isActive = true
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.numberOfLines = 2
        label.textColor = .label
        return label
    }()

    private lazy var sourceLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .tertiaryLabel
        return label
    }()

    private lazy var bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "bookmark"), for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(self, action: #selector(bookmarkButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 40).isActive = true
        return button
    }()

    private lazy var metaStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [sourceLabel, dateLabel])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        return stack
    }()

    private lazy var textStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, metaStack])
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .fill
        return stack
    }()

    private lazy var mainStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [newsImage, textStack, bookmarkButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return view
    }()


    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(mainStack)
        contentView.addSubview(separatorView)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        contentView.addGestureRecognizer(tapGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        newsImage.image = Self.placeholderImage
        currentImageURL = nil
    }

    // MARK: - Actions

    @objc private func cellTapped() {
        guard let article else { return }
        delegate?.newsCellDidTap(self, article: article)
    }

    @objc private func bookmarkButtonTapped() {
        guard let article else { return }
        delegate?.newsCellDidTapBookmark(self, article: article)
    }

    // MARK: - Data

    func setData(article: Article, isBookmarked: Bool = false) {
        self.article = article

        titleLabel.text = article.title
        sourceLabel.text = article.source?.name
        dateLabel.text = article.publishedAtDate
        bookmarkButton.setImage(
            UIImage(systemName: isBookmarked ? "bookmark.fill" : "bookmark"),
            for: .normal
        )

        newsImage.image = Self.placeholderImage

        guard let urlString = article.urlToImage,
              let url = URL(string: urlString) else { return }

        currentImageURL = url

        ImageLoader.shared.loadImage(from: url) { [weak self] image in
            guard let self = self else { return }
            guard self.currentImageURL == url else { return }
            self.newsImage.image = image ?? Self.placeholderImage
        }
    }
}
