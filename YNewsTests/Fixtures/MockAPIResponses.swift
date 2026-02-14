//
//  MockAPIResponses.swift
//  YNewsTests
//
//  Created by Gaurav Bhardwaj on 14/02/26.
//

import Foundation
@testable import YNews

enum MockAPIResponses {

    /// Sample article for reuse in tests.
    static let sampleArticle = Article(
        title: "Test Article Title",
        description: "Test description",
        content: "Test content",
        source: Article.Source(name: "Test Source"),
        urlToImage: "https://example.com/image.jpg",
        publishedAt: "2026-02-14T10:00:00Z"
    )

    static let sampleArticle2 = Article(
        title: "Second Article",
        description: nil,
        content: "More content",
        source: Article.Source(name: "Another Source"),
        urlToImage: nil,
        publishedAt: "2026-02-13T08:00:00Z"
    )

    /// Valid News API JSON response (minimal).
    static var validNewsResponseJSON: String {
        """
        {
          "articles": [
            {
              "title": "Test Article Title",
              "description": "Test description",
              "content": "Test content",
              "source": { "name": "Test Source" },
              "urlToImage": "https://example.com/image.jpg",
              "publishedAt": "2026-02-14T10:00:00Z"
            }
          ]
        }
        """
    }

    /// JSON for an empty articles list.
    static var emptyArticlesResponseJSON: String {
        """
        {"articles":[]}
        """
    }

    /// Invalid JSON to simulate malformed response.
    static var invalidJSON: String {
        "{ invalid json }"
    }

    static func validNewsResponseData() -> Data {
        Data(validNewsResponseJSON.utf8)
    }

    static func emptyArticlesResponseData() -> Data {
        Data(emptyArticlesResponseJSON.utf8)
    }

    static func invalidJSONData() -> Data {
        Data(invalidJSON.utf8)
    }
}
