//
//  ArticleEntity.swift
//  YNews
//
//  Created by Gaurav Bhardwaj on 13/02/26.
//

import Foundation
import CoreData

@objc(ArticleEntity)
class ArticleEntity: NSManagedObject {
    @NSManaged var title:       String?
    @NSManaged var desc:        String?
    @NSManaged var content:     String?
    @NSManaged var sourceName:  String?
    @NSManaged var urlToImage:  String?
    @NSManaged var publishedAt: String?   // stores the RAW ISO-8601 string, not the formatted one
    @NSManaged var isBookmarked: Bool
}

extension ArticleEntity {

    @nonobjc class func fetchRequest() -> NSFetchRequest<ArticleEntity> {
        NSFetchRequest<ArticleEntity>(entityName: "ArticleEntity")
    }

    // MARK: - Insert

    static func insert(from article: Article,
                       in context: NSManagedObjectContext,
                       isBookmarked: Bool = false) {
        let entity = ArticleEntity(context: context)
        entity.title        = article.title
        entity.desc         = article.description
        entity.content      = article.content
        entity.sourceName   = article.source?.name
        entity.urlToImage   = article.urlToImage
        entity.publishedAt  = article.publishedAt   // ← raw ISO string, not publishedAtDate
        entity.isBookmarked = isBookmarked
    }

    // MARK: - Fetch helpers

    /// Predicate matches on the raw publishedAt string so ISO re-parsing stays intact.
    static func predicate(for article: Article) -> NSPredicate {
        NSPredicate(
            format: "title == %@ AND publishedAt == %@ AND sourceName == %@",
            article.title         ?? "",
            article.publishedAt,          // raw ISO string matches what we stored
            article.source?.name  ?? ""
        )
    }

    static func fetchExisting(from article: Article,
                              in context: NSManagedObjectContext) -> ArticleEntity? {
        let request = ArticleEntity.fetchRequest()
        request.predicate  = predicate(for: article)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    // MARK: - Mapping

    func toArticle() -> Article {
        Article(
            title:       title,                 // stays nil-safe — Article.title is String?
            description: desc,
            content:     content,               // Article.content is String?
            source:      .init(name: sourceName ?? ""),
            urlToImage:  urlToImage,
            publishedAt: publishedAt ?? ""      // raw ISO string → publishedAtDate computed var works correctly
        )
    }
}
