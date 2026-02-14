//
//  NewsDetailViewController.swift
//  YNews
//
//  Created by Gaurav Bhardwaj on 13/02/26.
//

import UIKit

class NewsDetailViewController: UIViewController {
    
    private let article: Article
    private var currentImageURL: URL?
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var newsImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    init(article: Article) {
        self.article = article
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureWithArticle()
    }
    
    private var hasImage: Bool {
        guard let urlString = article.urlToImage, !urlString.isEmpty else { return false }
        return URL(string: urlString) != nil
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = article.source?.name
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(contentLabel)
        
        var constraints: [NSLayoutConstraint] = [
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .spacing_4),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .spacing_4),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.spacing_4),
            
            contentLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: .spacing_4),
            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .spacing_4),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.spacing_4),
            contentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -.spacing_4)
        ]
        
        if hasImage {
            contentView.addSubview(newsImageView)
            constraints += [
                newsImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .spacing_4),
                newsImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .spacing_4),
                newsImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.spacing_4),
                newsImageView.heightAnchor.constraint(equalToConstant: 250),
                
                titleLabel.topAnchor.constraint(equalTo: newsImageView.bottomAnchor, constant: .spacing_4)
            ]
        } else {
            constraints += [
                titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .spacing_4)
            ]
        }
        
        constraints += [
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .spacing_4),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.spacing_4)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func configureWithArticle() {
        titleLabel.text = article.title
        descriptionLabel.text = article.description
        contentLabel.text = article.content
        
        guard hasImage, let urlString = article.urlToImage, let url = URL(string: urlString) else { return }
        currentImageURL = url
        ImageLoader.shared.loadImage(from: url) { [weak self] image in
            guard let self = self else { return }
            guard self.currentImageURL == url else { return }
            self.newsImageView.image = image
        }
    }
}

