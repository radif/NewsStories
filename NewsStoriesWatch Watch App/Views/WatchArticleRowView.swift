//
//  WatchArticleRowView.swift
//  NewsStoriesWatch Watch App
//
//  Created by Radif Sharafullin on 12/11/25.
//

import SwiftUI

struct WatchArticleRowView: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Thumbnail
            if let imageURL = article.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Color.gray.opacity(0.3)
                    }
                }
                .frame(height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Headline
            Text(article.displayTitle)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(3)

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
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        WatchArticleRowView(article: .preview)
    }
}
