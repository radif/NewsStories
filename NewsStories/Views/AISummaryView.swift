//
//  AISummaryView.swift
//  NewsStories
//
//  Created by Radif Sharafullin on 12/12/25.
//

import SwiftUI

struct AISummaryView: View {
    let fullSummary: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(.purple)

                    Text("AI News Digest")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.bottom, 8)

                // Full Summary
                Text(fullSummary)
                    .font(.body)
                    .lineSpacing(6)
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("AI Summary")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - AI Summary Row View (for the feed)

struct AISummaryRowView: View {
    let state: AISummaryState
    let shortSummary: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.purple)

                Text("AI News Digest")
                    .font(.headline)
                    .foregroundStyle(.purple)

                Spacer()

                if case .loading = state {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if case .checking = state {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            // Content
            switch state {
            case .checking:
                Text("Checking AI availability...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            case .loading:
                Text("Generating AI Summary...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            case .loaded:
                if let summary = shortSummary {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }

                HStack {
                    Spacer()
                    Text("Tap to read more")
                        .font(.caption)
                        .foregroundStyle(.purple)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.purple)
                }

            default:
                EmptyView()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview("Summary View") {
    NavigationStack {
        AISummaryView(fullSummary: """
        Today's news is dominated by significant developments in technology and global affairs.

        The tech sector saw major announcements from leading companies, with new product launches and strategic partnerships making headlines. Analysts are particularly focused on the implications for market dynamics.

        Meanwhile, international developments continue to shape the geopolitical landscape, with diplomatic efforts underway on multiple fronts. Economic indicators suggest a period of transition as markets respond to these changes.
        """)
    }
}

#Preview("Row Loading") {
    AISummaryRowView(state: .loading, shortSummary: nil)
        .padding()
}

#Preview("Row Loaded") {
    AISummaryRowView(
        state: .loaded(short: "Today: Tech giants announce major AI breakthroughs", full: ""),
        shortSummary: "Today: Tech giants announce major AI breakthroughs while markets respond to economic shifts."
    )
    .padding()
}
