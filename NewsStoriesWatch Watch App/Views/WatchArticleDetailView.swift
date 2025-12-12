//
//  WatchArticleDetailView.swift
//  NewsStoriesWatch Watch App
//
//  Created by Radif Sharafullin on 12/11/25.
//

import SwiftUI

struct WatchArticleDetailView: View {
    let article: Article
    @State private var aiSummary: String?
    @State private var isLoadingSummary = false
    @State private var isClaudeAvailable = false
    @State private var showChat = false
    @State private var showFullArticle = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // Featured Image
                if let imageURL = article.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            Color.gray.opacity(0.3)
                                .overlay {
                                    ProgressView()
                                }
                        }
                    }
                    .frame(height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Headline
                Text(article.displayTitle)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)

                // Source and Date
                HStack {
                    Text(article.source.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(article.formattedDate)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Divider()

                // Content Section
                contentSection

                // Chat Button (if Claude available)
                if isClaudeAvailable {
                    Button {
                        showChat = true
                    } label: {
                        Label("Ask AI", systemImage: "bubble.left.and.bubble.right")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }

                // Read Full Article Button
                Button {
                    showFullArticle = true
                } label: {
                    Label("Full Article", systemImage: "doc.text")
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Article")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showChat) {
            WatchArticleChatView(article: article)
        }
        .sheet(isPresented: $showFullArticle) {
            WatchFullArticleView(article: article)
        }
        .task {
            await loadAISummary()
        }
    }

    // MARK: - Content Section

    @ViewBuilder
    private var contentSection: some View {
        if isLoadingSummary {
            VStack(spacing: 8) {
                ProgressView()
                Text("AI Summary...")
                    .font(.caption2)
                    .foregroundStyle(.purple)
            }
            .frame(maxWidth: .infinity)
            .padding()
        } else if let summary = aiSummary {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                        .font(.caption)
                    Text("AI Summary")
                        .font(.caption2)
                        .foregroundStyle(.purple)
                }

                Text(summary)
                    .font(.caption)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(8)
            .background(Color.purple.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Text(article.displayContent)
                .font(.caption)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Load AI Summary

    private func loadAISummary() async {
        isLoadingSummary = true

        let isAvailable = await WatchClaudeAPIService.shared.isAvailable
        isClaudeAvailable = isAvailable

        guard isAvailable else {
            isLoadingSummary = false
            return
        }

        do {
            let summary = try await WatchClaudeAPIService.shared.generateSummary(for: article)
            aiSummary = summary
        } catch {
            print("Watch: Failed to generate AI summary: \(error.localizedDescription)")
        }

        isLoadingSummary = false
    }
}

// MARK: - Full Article View

struct WatchFullArticleView: View {
    let article: Article
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Title
                Text(article.displayTitle)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)

                // Source and Date
                HStack {
                    Text(article.source.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(article.formattedFullDate)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                if let author = article.author {
                    Text("By \(author)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Full Content
                Text(article.displayContent)
                    .font(.caption)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                // Description (if different from content)
                if let description = article.description,
                   description != article.content {
                    Divider()
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Full Article")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WatchArticleDetailView(article: .preview)
    }
}
