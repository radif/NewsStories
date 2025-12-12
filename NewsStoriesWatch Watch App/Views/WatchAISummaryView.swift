//
//  WatchAISummaryView.swift
//  NewsStoriesWatch Watch App
//
//  Created by Radif Sharafullin on 12/12/25.
//

import SwiftUI

struct WatchAISummaryView: View {
    let fullSummary: String
    @Environment(\.dismiss) private var dismiss
    @State private var speechService = WatchSpeechService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.purple)

                    Text("AI Digest")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.purple)

                    Spacer()

                    // Speaker Button
                    if WatchSpeechService.isAvailable {
                        Button {
                            speechService.toggle(fullSummary)
                        } label: {
                            Image(systemName: speechService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2")
                                .font(.caption)
                                .foregroundStyle(speechService.isSpeaking ? .purple : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Full Summary
                Text(fullSummary)
                    .font(.caption2)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal)
        }
        .navigationTitle("AI Summary")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onDisappear {
            speechService.stop()
        }
    }
}

// MARK: - Watch AI Summary Row View

struct WatchAISummaryRowView: View {
    let state: WatchAISummaryState
    let shortSummary: String?
    let fullSummary: String?
    var onSpeakerTap: (() -> Void)? = nil
    var isSpeaking: Bool = false

    init(state: WatchAISummaryState, shortSummary: String?, fullSummary: String? = nil, onSpeakerTap: (() -> Void)? = nil, isSpeaking: Bool = false) {
        self.state = state
        self.shortSummary = shortSummary
        self.fullSummary = fullSummary
        self.onSpeakerTap = onSpeakerTap
        self.isSpeaking = isSpeaking
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundStyle(.purple)

                Text("AI Digest")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.purple)

                Spacer()

                if case .loading = state {
                    ProgressView()
                        .scaleEffect(0.6)
                } else if case .checking = state {
                    ProgressView()
                        .scaleEffect(0.6)
                } else if case .loaded = state, WatchSpeechService.isAvailable, fullSummary != nil {
                    Button {
                        onSpeakerTap?()
                    } label: {
                        Image(systemName: isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2")
                            .font(.caption2)
                            .foregroundStyle(isSpeaking ? .purple : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Content
            switch state {
            case .checking:
                Text("Checking...")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

            case .loading:
                Text("Generating AI Summary...")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

            case .loaded:
                if let summary = shortSummary {
                    Text(summary)
                        .font(.caption2)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }

            default:
                EmptyView()
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.purple.opacity(0.15))
        )
    }
}

#Preview("Summary View") {
    NavigationStack {
        WatchAISummaryView(fullSummary: """
        Today's headlines focus on technology and global markets.

        Major tech companies announced new AI features, while economic indicators show mixed signals across regions.
        """)
    }
}

#Preview("Row Loading") {
    WatchAISummaryRowView(state: .loading, shortSummary: nil)
        .padding()
}

#Preview("Row Loaded") {
    WatchAISummaryRowView(
        state: .loaded(short: "Today: Tech and markets dominate", full: ""),
        shortSummary: "Today: Tech and markets dominate headlines",
        fullSummary: "Full summary here"
    )
    .padding()
}
