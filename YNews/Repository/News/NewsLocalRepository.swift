//
//  NewsLocalRepository.swift
//  YNews
//
//  Created by Gaurav Bhardwaj on 14/02/26.
//

import Foundation
import CoreData
import UIKit

final class NewsLocalRepository {

    static let shared = NewsLocalRepository()

    static let maxCachedPages = 2

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate)
            .persistentContainer.newBackgroundContext()) {
        self.context = context
    }

    func getArticles(page: Int, pageSize: Int) throws -> [Article] {
        guard page <= Self.maxCachedPages else { return [] }

        var result: Result<[Article], Error>!

        context.performAndWait {
            let request: NSFetchRequest<ArticleEntity> = ArticleEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "publishedAt", ascending: false)]
            request.fetchLimit  = pageSize
            request.fetchOffset = (page - 1) * pageSize

            do {
                let entities = try self.context.fetch(request)
                result = .success(entities.map { $0.toArticle() })
            } catch {
                result = .failure(error)
            }
        }

        switch result! {
        case .success(let articles): return articles
        case .failure(let error):    throw error
        }
    }

    // MARK: - Write

    /// Persists remote articles into the cache for pages 1–`maxCachedPages`.
    ///
    /// Page 1 clears all non-bookmarked cached articles first so stale content never lingers.
    /// Uses `NSBatchDeleteRequest` for efficiency, then merges changes back into the
    /// context so in-memory objects stay consistent (avoids the broken-object-graph
    /// problem caused by calling `context.reset()` after a batch delete).
    func save(articles: [Article], page: Int) {
        guard page <= Self.maxCachedPages, !articles.isEmpty else { return }

        context.perform {
            do {
                if page == 1 {
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ArticleEntity")
                    fetchRequest.predicate = NSPredicate(format: "isBookmarked == NO")
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    // Return deleted object IDs so we can merge into the live context.
                    deleteRequest.resultType = .resultTypeObjectIDs
                    let deleteResult = try self.context.execute(deleteRequest) as? NSBatchDeleteResult
                    if let deletedIDs = deleteResult?.result as? [NSManagedObjectID], !deletedIDs.isEmpty {
                        NSManagedObjectContext.mergeChanges(
                            fromRemoteContextSave: [NSDeletedObjectsKey: deletedIDs],
                            into: [self.context]
                        )
                    }
                }

                for article in articles {
                    if let existing = ArticleEntity.fetchExisting(from: article, in: self.context) {
                        existing.title      = article.title
                        existing.desc       = article.description
                        existing.content    = article.content
                        existing.sourceName = article.source?.name
                        existing.urlToImage = article.urlToImage
                        existing.publishedAt = article.publishedAtDate
                    } else {
                        ArticleEntity.insert(from: article, in: self.context, isBookmarked: false)
                    }
                }

                if self.context.hasChanges {
                    try self.context.save()
                }
            } catch {
                print("NewsLocalRepository save error:", error)
            }
        }
    }
}
