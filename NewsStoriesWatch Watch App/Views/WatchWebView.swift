//
//  WatchWebView.swift
//  NewsStoriesWatch Watch App
//
//  Created by Radif Sharafullin on 12/11/25.
//

import SwiftUI

/// A view that presents the article URL in a full-screen sheet
/// Note: watchOS doesn't support embedded WKWebView like iOS.
/// This view opens the URL in the system browser when tapped.
struct WatchArticleWebView: View {
    let url: URL
    let title: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "safari")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)

                Text("Open Article")
                    .font(.headline)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)

                Button {
                    openURL(url)
                } label: {
                    Label("Open in Browser", systemImage: "arrow.up.right")
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle("Article")
    }
}

#Preview {
    NavigationStack {
        WatchArticleWebView(
            url: URL(string: "https://apple.com")!,
            title: "Apple News Article"
        )
    }
}
