//
//  BookmarkViewModel.swift
//  YNews
//
//  Created by Gaurav Bhardwaj on 14/02/26.
//

import Foundation
import Combine


final class BookmarkViewModel: ObservableObject {

    @Published private(set) var bookmarkedArticles: [Article] = []
    @Published private(set) var errorMessage: String?

    var bookmarkCount: Int { bookmarkedArticles.count }
    var hasBookmarks: Bool { !bookmarkedArticles.isEmpty }

    private let repository: BookmarkRepositoryProtocol

    init(repository: BookmarkRepositoryProtocol = BookmarkRepository.shared) {
        self.repository = repository
    }

    func loadBookmarks() {
        do {
            bookmarkedArticles = try repository.fetchBookmarks()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load bookmarks"
        }
    }

    func addBookmark(_ article: Article) {
        do {
            try repository.addBookmark(article)
            loadBookmarks()
        } catch {
            errorMessage = "Failed to add bookmark"
        }
    }

    func removeBookmark(_ article: Article) {
        do {
            try repository.removeBookmark(article)
            loadBookmarks()
        } catch {
            errorMessage = "Failed to remove bookmark"
        }
    }

    func toggleBookmark(_ article: Article) {
        if isBookmarked(article) {
            removeBookmark(article)
        } else {
            addBookmark(article)
        }
    }

    func isBookmarked(_ article: Article) -> Bool {
        repository.isBookmarked(article)
    }
}
