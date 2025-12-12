//
//  WatchNewsFeedView.swift
//  NewsStoriesWatch Watch App
//
//  Created by Radif Sharafullin on 12/11/25.
//

import SwiftUI

struct WatchNewsFeedView: View {
    @State private var viewModel = WatchNewsFeedViewModel()
    @State private var showCategoryPicker = false
    @State private var showAISummary = false

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    loadingView

                case .loaded, .loadingMore:
                    articlesList

                case .error(let message):
                    errorView(message: message)

                case .empty:
                    emptyView
                }
            }
            .navigationTitle("News")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCategoryPicker = true
                    } label: {
                        Image(systemName: viewModel.selectedCategory?.icon ?? "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                categoryPickerSheet
            }
        }
        .task {
            await viewModel.fetchArticles()
        }
    }

    // MARK: - Articles List

    private var articlesList: some View {
        List {
            // AI Summary Cell (first)
            if viewModel.showAISummaryCell {
                Button {
                    if viewModel.fullSummary != nil {
                        showAISummary = true
                    }
                } label: {
                    WatchAISummaryRowView(
                        state: viewModel.aiSummaryState,
                        shortSummary: viewModel.shortSummary
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.fullSummary == nil)
            }

            ForEach(viewModel.articles) { article in
                NavigationLink(value: article) {
                    WatchArticleRowView(article: article)
                }
                .task {
                    await viewModel.loadMoreArticlesIfNeeded(currentArticle: article)
                }
            }

            if viewModel.state == .loadingMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
        .listStyle(.carousel)
        .navigationDestination(for: Article.self) { article in
            WatchArticleDetailView(article: article)
        }
        .sheet(isPresented: $showAISummary) {
            if let fullSummary = viewModel.fullSummary {
                WatchAISummaryView(fullSummary: fullSummary)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text("Loading...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
                .font(.title2)
                .foregroundStyle(.red)
            Text("Error")
                .font(.headline)
            Text(message)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task {
                    await viewModel.retry()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "newspaper")
                .font(.title2)
            Text("No Articles")
                .font(.headline)
            Button("Refresh") {
                Task {
                    await viewModel.fetchArticles()
                }
            }
        }
    }

    // MARK: - Category Picker

    private var categoryPickerSheet: some View {
        List {
            Button("All") {
                Task {
                    await viewModel.selectCategory(nil)
                }
                showCategoryPicker = false
            }
            .foregroundStyle(viewModel.selectedCategory == nil ? .blue : .primary)

            ForEach(NewsCategory.allCases) { category in
                Button {
                    Task {
                        await viewModel.selectCategory(category)
                    }
                    showCategoryPicker = false
                } label: {
                    Label(category.displayName, systemImage: category.icon)
                }
                .foregroundStyle(viewModel.selectedCategory == category ? .blue : .primary)
            }
        }
    }
}

#Preview {
    WatchNewsFeedView()
}
