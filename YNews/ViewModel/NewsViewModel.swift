//
//  NewsViewModel.swift
//  YNews
//
//  Created by Gaurav Bhardwaj on 13/02/26.
//

import Foundation
import Combine

enum NewsViewState: Equatable {
    case idle
    case loading
    case loaded
    case cachedData(error: NetworkError)
    case error(NetworkError)
}

final class NewsViewModel: ObservableObject, PaginatorDelegate {

    @Published var articles: [Article] = []
    @Published var state: NewsViewState = .idle
    @Published var isLoadingNextPage: Bool = false
    @Published private(set) var isOnline: Bool = true

    private let repository:     NewsRepository
    private let networkMonitor: NetworkMonitor
    private var cancellables  = Set<AnyCancellable>()

    private let perPageCount = 20
    private(set) var hasMore = true
    private var isFetching   = false
    private var totalResults = 0

    var query: String? {
        didSet { restartPagination() }
    }

    var paginator: Paginator? {
        didSet { paginator?.pagingDelegate = self }
    }

    init(repository:     NewsRepository  = NewsRepositoryImpl(),
         networkMonitor: NetworkMonitor  = .shared) {
        self.repository     = repository
        self.networkMonitor = networkMonitor
        observeConnectivity()
    }



    private func observeConnectivity() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                guard let self else { return }
                self.isOnline = connected

                if !connected {
                    self.handleOffline()
                } else if case .error(let err) = self.state, err == .noInternet {
                    self.retry()
                } else if case .cachedData(let err) = self.state, err == .noInternet {
                    Task { await self.pullToRefresh() }
                }
            }
            .store(in: &cancellables)
    }

    private func handleOffline() {
        guard !isFetching else { return }

        if articles.isEmpty {
            state   = .error(.noInternet)
            hasMore = false
        } else if case .loaded = state {
            state = .cachedData(error: .noInternet)
        }
    }



    func restartPagination() {
        hasMore      = true
        totalResults = 0
        articles     = []
        paginator?.reset()
    }

    // MARK: - PaginatorDelegate

    func paginate(to page: Int, for paginator: Paginator) {
        guard hasMore else {
            paginator.finishedPaginating()
            return
        }
        Task { await fetch(page: page) }
    }

    // MARK: - Fetch

    private func fetch(page: Int) async {
        guard !isFetching else { return }
        isFetching = true

        // Check connectivity before even attempting the request.
        if !networkMonitor.isConnected {
            await MainActor.run {
                isFetching = false
                paginator?.finishedPaginating()
                handleOffline()
            }
            return
        }

        await MainActor.run {
            if page == 1 { state = .loading }
            else         { isLoadingNextPage = true }
        }

        do {
            let response = try await repository.getArticles(
                page: page, pageSize: perPageCount, query: query, forceRemote: false
            )

            await MainActor.run {
                if page == 1 {
                    self.totalResults = response.totalResults
                    self.articles     = response.articles
                } else {
                    self.articles.append(contentsOf: response.articles)
                }

                self.hasMore           = !response.articles.isEmpty && self.articles.count < self.totalResults
                self.state             = .loaded
                self.isLoadingNextPage = false
                self.paginator?.finishedPaginating()
                self.isFetching        = false
            }

        } catch {
            let networkError = NetworkError.from(error)

            await MainActor.run {
                if self.articles.isEmpty {
                    self.state = .error(networkError)
                } else {
                    self.state = .cachedData(error: networkError)
                }
                self.hasMore           = false
                self.isLoadingNextPage = false
                self.paginator?.finishedPaginating()
                self.isFetching        = false
            }
        }
    }


    func pullToRefresh() async {
        guard networkMonitor.isConnected else { return }
        hasMore      = true
        totalResults = 0
        paginator?.page = 1
        paginator?.finishedPaginating()
        await fetch(page: 1)
    }

    func retry() {
        restartPagination()
    }
}
