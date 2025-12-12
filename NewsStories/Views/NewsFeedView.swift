//
//  NewsFeedView.swift
//  NewsStories
//
//  Created by Radif Sharafullin on 12/11/25.
//

import SwiftUI

struct NewsFeedView: View {
    @State private var viewModel = NewsFeedViewModel()
    @State private var showCategoryPicker = false

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
                    categoryButton
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
            // AI Summary Cell (first, slightly larger)
            if viewModel.showAISummaryCell {
                NavigationLink {
                    if let fullSummary = viewModel.fullSummary {
                        AISummaryView(fullSummary: fullSummary)
                    }
                } label: {
                    AISummaryRowView(
                        state: viewModel.aiSummaryState,
                        shortSummary: viewModel.shortSummary
                    )
                }
                .disabled(viewModel.fullSummary == nil)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
            }

            ForEach(viewModel.articles) { article in
                NavigationLink(value: article) {
                    ArticleRowView(article: article)
                }
                .task {
                    await viewModel.loadMoreArticlesIfNeeded(currentArticle: article)
                }
            }

            if viewModel.state == .loadingMore {
                loadingMoreRow
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.fetchArticles()
        }
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
        }
    }

    // MARK: - Loading Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading articles...")
                .foregroundStyle(.secondary)
        }
    }

    private var loadingMoreRow: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding()
            Spacer()
        }
        .listRowSeparator(.hidden)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label("Unable to Load", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task {
                    await viewModel.retry()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        ContentUnavailableView {
            Label("No Articles", systemImage: "newspaper")
        } description: {
            Text("No articles found for the selected category.")
        } actions: {
            Button("Refresh") {
                Task {
                    await viewModel.fetchArticles()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Category Picker

    private var categoryButton: some View {
        Button {
            showCategoryPicker = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.selectedCategory?.icon ?? "line.3.horizontal.decrease.circle")
                if let category = viewModel.selectedCategory {
                    Text(category.displayName)
                        .font(.caption)
                }
            }
        }
    }

    private var categoryPickerSheet: some View {
        NavigationStack {
            List {
                Button {
                    Task {
                        await viewModel.selectCategory(nil)
                    }
                    showCategoryPicker = false
                } label: {
                    HStack {
                        Label("All Categories", systemImage: "newspaper")
                        Spacer()
                        if viewModel.selectedCategory == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .foregroundStyle(.primary)

                ForEach(NewsCategory.allCases) { category in
                    Button {
                        Task {
                            await viewModel.selectCategory(category)
                        }
                        showCategoryPicker = false
                    } label: {
                        HStack {
                            Label(category.displayName, systemImage: category.icon)
                            Spacer()
                            if viewModel.selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showCategoryPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    NewsFeedView()
}
