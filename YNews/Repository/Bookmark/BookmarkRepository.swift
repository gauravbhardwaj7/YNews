//
//  BookmarkRepository.swift
//  YNews
//
//  Created by Gaurav Bhardwaj on 14/02/26.
//

import Foundation
import CoreData
import UIKit


protocol BookmarkRepositoryProtocol {
    func addBookmark(_ article: Article) throws
    func removeBookmark(_ article: Article) throws
    func fetchBookmarks() throws -> [Article]
    func isBookmarked(_ article: Article) -> Bool
}


final class BookmarkRepository: BookmarkRepositoryProtocol {

    static let shared = BookmarkRepository()

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()) {
        self.context = context
    }

    func addBookmark(_ article: Article) throws {
        guard !isBookmarked(article) else { return }
        var saveError: Error?
        context.performAndWait {
            if let existing = ArticleEntity.fetchExisting(from: article, in: context) {
                existing.isBookmarked = true
            } else {
                ArticleEntity.insert(from: article, in: context, isBookmarked: true)
            }
            do {
                try context.save()
            } catch {
                saveError = error
            }
        }
        if let error = saveError { throw error }
    }

    func removeBookmark(_ article: Article) throws {
        var saveError: Error?
        context.performAndWait {
            do {
                guard let existing = ArticleEntity.fetchExisting(from: article, in: context) else { return }
                existing.isBookmarked = false
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                saveError = error
            }
        }
        if let error = saveError { throw error }
    }

    func fetchBookmarks() throws -> [Article] {
        var result: Result<[Article], Error>!
        context.performAndWait {
            let request = ArticleEntity.fetchRequest()
            request.predicate = NSPredicate(format: "isBookmarked == YES")
            request.sortDescriptors = [NSSortDescriptor(key: "publishedAt", ascending: false)]
            do {
                let entities = try context.fetch(request)
                result = .success(entities.map { $0.toArticle() })
            } catch {
                result = .failure(error)
            }
        }
        switch result! {
        case .success(let articles):
            return articles
        case .failure(let error):
            throw error
        }
    }

    func isBookmarked(_ article: Article) -> Bool {
        var found = false
        context.performAndWait {
            guard let existing = ArticleEntity.fetchExisting(from: article, in: context) else { return }
            found = existing.isBookmarked
        }
        return found
    }
}
