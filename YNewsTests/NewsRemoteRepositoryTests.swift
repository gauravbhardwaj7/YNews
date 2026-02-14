//
//  NewsRemoteRepositoryTests.swift
//  YNewsTests
//
//  Created by Gaurav Bhardwaj on 14/02/26.
//

import XCTest
@testable import YNews

@MainActor
final class NewsRemoteRepositoryTests: XCTestCase {

    var urlSession: URLSession!
    let mockURL = URL(string: "https://newsapi.org/v2/everything")!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        urlSession = URLSession(configuration: config)
    }

    override func tearDown() {
        MockURLProtocol.reset()
        urlSession = nil
        super.tearDown()
    }

    func test_getArticles_decodesValidResponse() async throws {
        let data = MockAPIResponses.validNewsResponseData()
        MockURLProtocol.mockData = data
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: mockURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let repo = NewsRemoteRepository(session: urlSession)
        let response = try await repo.getArticles(page: 1, pageSize: 20, query: nil)

        XCTAssertEqual(response.articles.count, 1)
        XCTAssertEqual(response.totalResults, 0)
    }

}
