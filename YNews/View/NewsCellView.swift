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

class NewsCellView: UICollectionViewCell{
    weak var delegate: NewsCellViewDelegate?
    private var article: Article?
    private var currentImageURL: URL?
    
    private lazy var title: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label
        label.numberOfLines = 2
        label.setContentHuggingPriority(.init(1), for: .horizontal)
        return label
    }()
    
    
    private lazy var sourceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private static let placeholderImage = UIImage(systemName: "photo")
    
    private lazy var newsImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Self.placeholderImage
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 64).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 64).isActive = true
        return imageView
    }()
    
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 2
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .caption1)
        return label
    }()

    private lazy var bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "bookmark"), for: .normal)
        button.addTarget(self, action: #selector(bookmarkButtonTapped), for: .touchUpInside)
        button.tintColor = .systemBlue
        return button
    }()
    
    private lazy var separatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray5
        return view
    }()

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(title)
        self.contentView.addSubview(sourceLabel)
        self.contentView.addSubview(newsImage)
        self.contentView.addSubview(dateLabel)
        self.contentView.addSubview(bookmarkButton)
        self.contentView.addSubview(separatorView)

        
        NSLayoutConstraint.activate([
            newsImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .spacing_2),
            newsImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .spacing_2),

            title.leadingAnchor.constraint(equalTo: newsImage.trailingAnchor, constant: .spacing_2),
            title.trailingAnchor.constraint(equalTo: bookmarkButton.leadingAnchor, constant: -.spacing_2),

            sourceLabel.topAnchor.constraint(equalTo: title.bottomAnchor, constant: .spacing_1),
            sourceLabel.leadingAnchor.constraint(equalTo: title.leadingAnchor),

            dateLabel.topAnchor.constraint(equalTo: sourceLabel.topAnchor),
            dateLabel.leadingAnchor.constraint(equalTo: sourceLabel.trailingAnchor, constant: .spacing_2),
            dateLabel.trailingAnchor.constraint(equalTo: bookmarkButton.leadingAnchor, constant: -.spacing_2),
            dateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -.spacing_2),

            bookmarkButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .spacing_2),
            bookmarkButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.spacing_2),
            bookmarkButton.widthAnchor.constraint(equalToConstant: 44),
            bookmarkButton.heightAnchor.constraint(equalToConstant: 44),


            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .spacing_2),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.spacing_2),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        contentView.addGestureRecognizer(tapGesture)
        contentView.isUserInteractionEnabled = true
    }
    
    @objc private func cellTapped() {
        guard let article = article else { return }
        delegate?.newsCellDidTap(self, article: article)
    }

    @objc private func bookmarkButtonTapped() {
        guard let article = article else { return }
        delegate?.newsCellDidTapBookmark(self, article: article)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        newsImage.image = Self.placeholderImage
        currentImageURL = nil
    }
    
    func setData(article: Article, isBookmarked: Bool = false) {
        self.article = article
        self.title.text = article.title
        bookmarkButton.setImage(UIImage(systemName: isBookmarked ? "bookmark.fill" : "bookmark"), for: .normal)
        self.dateLabel.text = article.publishedAtDate
        self.sourceLabel.text = article.source?.name
        newsImage.image = Self.placeholderImage
        
        guard let urlString = article.urlToImage, let url = URL(string: urlString) else {
            return
        }
        
        currentImageURL = url
        
        ImageLoader.shared.loadImage(from: url) { [weak self] image in
            guard let self = self else { return }
            guard self.currentImageURL == url else { return }
            
            self.newsImage.image = image ?? Self.placeholderImage
        }
    }
    
}
