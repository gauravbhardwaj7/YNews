//
//  NewsRemoteRepository.swift
//  YNews
//
//  Created by Gaurav Bhardwaj on 14/02/26.
//

import Foundation

class NewsRemoteRepository: NewsRepository {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func getArticles(page: Int, pageSize: Int, query: String?, forceRemote: Bool = false) async throws -> NewsResponse {
        var components = URLComponents(string: "https://newsapi.org/v2/everything")
        let searchQuery = (query?.isEmpty == false) ? query! : "tesla"
        components?.queryItems = [
            .init(name: "q", value: searchQuery),
            .init(name: "sortBy", value: "publishedAt"),
            .init(name: "page", value: String(page)),
            .init(name: "pageSize", value: String(pageSize)),
            .init(name: "apiKey", value: "029221a5d74a4d94a5fcc8a66c7baa06")
        ]
        
        guard let url = components?.url else { throw URLError(.badURL) }
        
        do {
            let (data, _) = try await session.data(from: url)
            return try JSONDecoder().decode(NewsResponse.self, from: data)
        } catch {
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
                print("NewsRemoteRepository error:", error)
            }
            throw error
        }
    }
}
