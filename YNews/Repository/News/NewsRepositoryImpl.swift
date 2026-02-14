//
//  NewsRepositoryImpl.swift
//  YNews
//
//  Created by Gaurav Bhardwaj on 14/02/26.
//

import Foundation

protocol NewsRepository {
    func getArticles(page: Int, pageSize: Int, query: String?, forceRemote: Bool) async throws -> NewsResponse
}

final class NewsRepositoryImpl: NewsRepository {

    private let local:  NewsLocalRepository
    private let remote: NewsRemoteRepository

    /// Cached value of the last known totalResults from a successful remote call.
    /// Persisted in UserDefaults so it survives app restarts and keeps hasMore correct
    /// when serving from cache on next launch.
    private var cachedTotalResults: Int {
        get { UserDefaults.standard.integer(forKey: "cachedTotalResults") }
        set { UserDefaults.standard.set(newValue, forKey: "cachedTotalResults") }
    }

    init(local:  NewsLocalRepository = .shared,
         remote: NewsRemoteRepository = .init()) {
        self.local  = local
        self.remote = remote
    }

    func getArticles(page: Int, pageSize: Int, query: String?, forceRemote: Bool = false) async throws -> NewsResponse {

        let hasActiveQuery = !(query?.isEmpty ?? true)

        if !forceRemote {
            do {
                let remoteResponse = try await remote.getArticles(
                    page: page, pageSize: pageSize, query: query
                )

                if page <= NewsLocalRepository.maxCachedPages && !hasActiveQuery {
                    cachedTotalResults = remoteResponse.totalResults
                    Task.detached(priority: .background) { [local] in
                        await local.save(articles: remoteResponse.articles, page: page)
                    }
                }

                return remoteResponse

            } catch {
                let networkError = NetworkError.from(error)

                guard !hasActiveQuery, page <= NewsLocalRepository.maxCachedPages else {
                    throw networkError
                }

                return try serveCachedPage(page: page, pageSize: pageSize, networkError: networkError)
            }
        }


        guard !hasActiveQuery else {
            return NewsResponse(totalResults: 0, articles: [])
        }
        return try serveCachedPage(page: page, pageSize: pageSize, networkError: nil)
    }

    // MARK: - Private

    private func serveCachedPage(page: Int, pageSize: Int, networkError: NetworkError?) throws -> NewsResponse {
        do {
            let cached = try local.getArticles(page: page, pageSize: pageSize)
            if !cached.isEmpty {
                // Use the persisted totalResults so the ViewModel's hasMore logic
                // knows the real ceiling rather than just the cached slice count.
                let total = max(cachedTotalResults, cached.count)
                return NewsResponse(totalResults: total, articles: cached)
            }
        } catch {
            print("NewsRepositoryImpl local fetch error:", error)
        }

        if let networkError { throw networkError }

        return NewsResponse(totalResults: 0, articles: [])
    }
}
