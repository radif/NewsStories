//
//  ArticleDetailView.swift
//  NewsStories
//
//  Created by Radif Sharafullin on 12/11/25.
//

import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @State private var showWebView = false
    @State private var aiSummary: String?
    @State private var isLoadingSummary = false
    @State private var useAISummary = false
    @State private var isClaudeAvailable = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Featured Image
                featuredImage

                VStack(alignment: .leading, spacing: 12) {
                    // Headline
                    Text(article.displayTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .fixedSize(horizontal: false, vertical: true)

                    // Source and Date
                    HStack {
                        Label(article.source.name, systemImage: "newspaper")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(article.formattedFullDate)
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }

                    Divider()

                    // Author
                    if let author = article.author, !author.isEmpty {
                        Label(author, systemImage: "person")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // AI Summary or Original Content
                    contentSection

                    Spacer(minLength: 20)

                    // Chat about article (only if Claude API is available)
                    if isClaudeAvailable {
                        ArticleChatView(article: article)
                    }

                    // Read Full Article Button
                    if let url = article.articleURL {
                        readFullArticleButton(url: url)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let url = article.articleURL {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showWebView) {
            if let url = article.articleURL {
                ArticleWebView(url: url, title: article.source.name)
            }
        }
        .task {
            await loadAISummary()
        }
    }

    // MARK: - Content Section

    @ViewBuilder
    private var contentSection: some View {
        if isLoadingSummary {
            // Loading AI Summary
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                    Text("Generating AI Summary...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else if let summary = aiSummary, useAISummary {
            // AI Summary
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                    Text("AI Summary")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.purple)
                }

                Text(summary)
                    .font(.body)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            // Original Content
            originalContent
        }
    }

    @ViewBuilder
    private var originalContent: some View {
        Text(article.displayContent)
            .font(.body)
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)

        // Description (if different from content)
        if let description = article.description,
           description != article.content {
            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Load AI Summary

    private func loadAISummary() async {
        isLoadingSummary = true

        // Check if Claude API is available
        let isAvailable = await ClaudeAPIService.shared.isAvailable
        isClaudeAvailable = isAvailable

        guard isAvailable else {
            isLoadingSummary = false
            useAISummary = false
            return
        }

        do {
            let summary = try await ClaudeAPIService.shared.generateSummary(for: article)
            aiSummary = summary
            useAISummary = true
        } catch {
            print("Failed to generate AI summary: \(error.localizedDescription)")
            useAISummary = false
        }

        isLoadingSummary = false
    }

    // MARK: - Featured Image

    @ViewBuilder
    private var featuredImage: some View {
        AsyncImage(url: article.imageURL) { phase in
            switch phase {
            case .empty:
                imagePlaceholder
                    .overlay {
                        ProgressView()
                    }
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                imagePlaceholder
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                            Text("Image unavailable")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
            @unknown default:
                imagePlaceholder
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.15))
    }

    // MARK: - Read Full Article Button

    private func readFullArticleButton(url: URL) -> some View {
        Button {
            showWebView = true
        } label: {
            HStack {
                Text("Read Full Article")
                    .fontWeight(.semibold)
                Image(systemName: "book")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.bottom)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ArticleDetailView(article: .preview)
    }
}

#Preview("No Image") {
    NavigationStack {
        ArticleDetailView(article: .previewNoImage)
    }
}
