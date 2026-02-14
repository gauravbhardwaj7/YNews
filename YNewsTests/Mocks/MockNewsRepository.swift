//
//  MockNewsRepository.swift
//  YNewsTests
//
//  Created by Gaurav Bhardwaj on 14/02/26.
//

import Foundation
@testable import YNews


final class MockNewsRepository: NewsRepository {
    var mockResponse: NewsResponse?
    var mockError: Error?

    init(response: NewsResponse? = nil, error: Error? = nil) {
        self.mockResponse = response
        self.mockError = error
    }

    func getArticles(page: Int, pageSize: Int, query: String?, forceRemote: Bool = false) async throws -> NewsResponse {
        if let error = mockError {
            throw error
        }
        guard let response = mockResponse else {
            throw NSError(domain: "MockNewsRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "No mock response configured"])
        }
        return response
    }
}
