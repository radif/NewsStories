//
//  ArticleDetailView.swift
//  NewsStories
//
//  Created by Radif Sharafullin on 12/11/25.
//

import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @Environment(\.openURL) private var openURL

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

                    // Content
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

                    Spacer(minLength: 20)

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
            openURL(url)
        } label: {
            HStack {
                Text("Read Full Article")
                    .fontWeight(.semibold)
                Image(systemName: "arrow.up.right")
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
