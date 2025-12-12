//
//  WatchNewsFeedViewModel.swift
//  NewsStoriesWatch Watch App
//
//  Created by Radif Sharafullin on 12/11/25.
//

import Foundation

// MARK: - Watch View State

enum WatchViewState: Equatable {
    case idle
    case loading
    case loaded
    case loadingMore
    case error(String)
    case empty

    static func == (lhs: WatchViewState, rhs: WatchViewState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.loading, .loading),
             (.loaded, .loaded),
             (.loadingMore, .loadingMore),
             (.empty, .empty):
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

// MARK: - Watch AI Summary State

enum WatchAISummaryState: Equatable {
    case idle
    case checking
    case loading
    case loaded(short: String, full: String)
    case unavailable
}

// MARK: - Watch News Feed ViewModel

@Observable
final class WatchNewsFeedViewModel {
    // MARK: - Published Properties

    private(set) var articles: [Article] = []
    private(set) var state: WatchViewState = .idle
    private(set) var selectedCategory: NewsCategory? = nil
    private(set) var aiSummaryState: WatchAISummaryState = .idle

    // MARK: - Private Properties

    private let newsService: WatchNewsAPIService
    private var currentPage = 1
    private var totalResults = 0
    private let pageSize = 10 // Smaller page size for watch

    var hasMorePages: Bool {
        articles.count < totalResults
    }

    var isLoading: Bool {
        state == .loading || state == .loadingMore
    }

    var shortSummary: String? {
        if case .loaded(let short, _) = aiSummaryState {
            return short
        }
        return nil
    }

    var fullSummary: String? {
        if case .loaded(_, let full) = aiSummaryState {
            return full
        }
        return nil
    }

    var showAISummaryCell: Bool {
        switch aiSummaryState {
        case .idle, .unavailable:
            return false
        case .checking, .loading, .loaded:
            return true
        }
    }

    // MARK: - Initialization

    init(newsService: WatchNewsAPIService = WatchNewsAPIService()) {
        self.newsService = newsService
    }

    // MARK: - Public Methods

    @MainActor
    func fetchArticles() async {
        guard state != .loading else { return }

        state = .loading
        currentPage = 1
        articles = []

        await loadArticles()
    }

    @MainActor
    func loadMoreArticlesIfNeeded(currentArticle: Article) async {
        guard let lastArticle = articles.last,
              lastArticle.id == currentArticle.id,
              hasMorePages,
              state != .loadingMore else {
            return
        }

        state = .loadingMore
        currentPage += 1
        await loadArticles(isLoadingMore: true)
    }

    @MainActor
    func selectCategory(_ category: NewsCategory?) async {
        guard category != selectedCategory else { return }

        selectedCategory = category
        await fetchArticles()
    }

    @MainActor
    func retry() async {
        await fetchArticles()
    }

    // MARK: - Private Methods

    @MainActor
    private func loadArticles(isLoadingMore: Bool = false) async {
        do {
            let response = try await newsService.fetchTopHeadlines(
                category: selectedCategory,
                page: currentPage,
                pageSize: pageSize
            )

            totalResults = response.totalResults

            if isLoadingMore {
                let newArticles = response.articles.filter { newArticle in
                    !articles.contains { $0.id == newArticle.id }
                }
                articles.append(contentsOf: newArticles)
            } else {
                articles = response.articles
            }

            state = articles.isEmpty ? .empty : .loaded

            // Generate AI summary after initial load
            if !isLoadingMore && !articles.isEmpty {
                await generateAISummary()
            }
        } catch {
            if !isLoadingMore {
                articles = []
            }
            state = .error(error.localizedDescription)

            if isLoadingMore {
                currentPage -= 1
            }
        }
    }

    // MARK: - AI Summary

    @MainActor
    private func generateAISummary() async {
        aiSummaryState = .checking

        let isAvailable = await WatchClaudeAPIService.shared.isAvailable
        guard isAvailable else {
            aiSummaryState = .unavailable
            return
        }

        aiSummaryState = .loading

        do {
            let (short, full) = try await WatchClaudeAPIService.shared.generateNewsDigest(for: articles)
            aiSummaryState = .loaded(short: short, full: full)
        } catch {
            print("Watch: Failed to generate AI summary: \(error.localizedDescription)")
            aiSummaryState = .unavailable
        }
    }
}
