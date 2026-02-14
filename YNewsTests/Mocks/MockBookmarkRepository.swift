//
//  MockBookmarkRepository.swift
//  YNewsTests
//
//  Created by Gaurav Bhardwaj on 14/02/26.
//

import Foundation
@testable import YNews

/// In-memory mock for BookmarkRepositoryProtocol. Stores bookmarks in a Set keyed by bookmarkKey.
/// Uses value semantics only (struct copies) to avoid allocation/deallocation issues in tests.
final class MockBookmarkRepository: BookmarkRepositoryProtocol {
    private var storage: Set<String> = []
    private var articlesByKey: [String: Article] = [:]

    func addBookmark(_ article: Article) throws {
        let key = article.bookmarkKey
        storage.insert(key)
        articlesByKey[key] = article
    }

    func removeBookmark(_ article: Article) throws {
        let key = article.bookmarkKey
        storage.remove(key)
        articlesByKey.removeValue(forKey: key)
    }

    func fetchBookmarks() throws -> [Article] {
        let values = articlesByKey.values
        return values.sorted { $0.publishedAt > $1.publishedAt }
    }

    func isBookmarked(_ article: Article) -> Bool {
        storage.contains(article.bookmarkKey)
    }
}
