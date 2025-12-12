//
//  ArticleRowView.swift
//  NewsStories
//
//  Created by Radif Sharafullin on 12/11/25.
//

import SwiftUI

struct ArticleRowView: View {
    let article: Article

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail
            AsyncImage(url: article.imageURL) { phase in
                switch phase {
                case .empty:
                    thumbnailPlaceholder
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    thumbnailPlaceholder
                @unknown default:
                    thumbnailPlaceholder
                }
            }
            .frame(width: 100, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Article Info
            VStack(alignment: .leading, spacing: 6) {
                Text(article.displayTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(3)
                    .foregroundStyle(.primary)

                Spacer()

                HStack {
                    Text(article.source.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(article.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var thumbnailPlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .overlay {
                Image(systemName: "newspaper")
                    .font(.title2)
                    .foregroundStyle(.gray.opacity(0.5))
            }
    }
}

// MARK: - Preview

#Preview {
    List {
        ArticleRowView(article: .preview)
        ArticleRowView(article: .previewNoImage)
    }
    .listStyle(.plain)
}

// MARK: - Preview Data

extension Article {
    static var preview: Article {
        Article(
            source: Source(id: "cnn", name: "CNN"),
            author: "John Doe",
            title: "Breaking News: Major Tech Company Announces Revolutionary Product",
            description: "A major tech company has announced a new product that promises to revolutionize the industry.",
            url: "https://example.com/article",
            urlToImage: "https://picsum.photos/400/300",
            publishedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)),
            content: "Full article content goes here..."
        )
    }

    static var previewNoImage: Article {
        Article(
            source: Source(id: "bbc", name: "BBC News"),
            author: nil,
            title: "Another Headline Without an Image - BBC News",
            description: "This article doesn't have a thumbnail image.",
            url: "https://example.com/article2",
            urlToImage: nil,
            publishedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-7200)),
            content: nil
        )
    }
}
