//
//  WatchDigestChatView.swift
//  NewsStoriesWatch Watch App
//
//  Created by Radif Sharafullin on 12/12/25.
//

import SwiftUI

// MARK: - Watch Digest Chat Message

struct WatchDigestChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: Role
    let content: String

    enum Role {
        case user
        case assistant
    }
}

// MARK: - Watch Digest Chat View

struct WatchDigestChatView: View {
    let digestSummary: String
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [WatchDigestChatMessage] = []
    @State private var isLoading = false
    @State private var inputText = ""

    private let quickQuestions = [
        "Tell me more",
        "Key takeaways?",
        "What's trending?",
        "Any concerns?"
    ]

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 8) {
                        // Quick Questions
                        if messages.isEmpty {
                            Text("Ask about today's news")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ForEach(quickQuestions, id: \.self) { question in
                                Button {
                                    sendQuestion(question)
                                } label: {
                                    Text(question)
                                        .font(.caption)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(.purple)
                                .disabled(isLoading)
                            }
                        }

                        // Custom Input (voice/scribble/text)
                        customInputSection

                        // Messages
                        ForEach(messages) { message in
                            WatchDigestMessageBubble(message: message)
                        }

                        // Loading
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Thinking...")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Ask Another
                        if !messages.isEmpty && !isLoading {
                            Divider()

                            // Custom Input again
                            customInputSection

                            Text("Or quick questions:")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            ForEach(quickQuestions.prefix(2), id: \.self) { question in
                                Button {
                                    sendQuestion(question)
                                } label: {
                                    Text(question)
                                        .font(.caption2)
                                }
                                .buttonStyle(.bordered)
                                .tint(.purple)
                            }
                        }

                        // Scroll anchor
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding(.horizontal)
                }
                .onChange(of: messages.count) {
                    withAnimation {
                        proxy.scrollTo("bottom")
                    }
                }
            }
            .navigationTitle("Ask AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Custom Input Section

    @ViewBuilder
    private var customInputSection: some View {
        HStack {
            TextField("Ask anything...", text: $inputText)
                .font(.caption2)

            Button {
                guard !inputText.isEmpty else { return }
                let question = inputText
                inputText = ""
                sendQuestion(question)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(.purple)
            }
            .disabled(inputText.isEmpty || isLoading)
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color.purple.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Send Question

    private func sendQuestion(_ question: String) {
        let userMessage = WatchDigestChatMessage(role: .user, content: question)
        messages.append(userMessage)
        isLoading = true

        Task {
            do {
                let response = try await askQuestion(question)
                let assistantMessage = WatchDigestChatMessage(role: .assistant, content: response)
                messages.append(assistantMessage)
            } catch {
                let errorMessage = WatchDigestChatMessage(role: .assistant, content: "Sorry, couldn't process that.")
                messages.append(errorMessage)
            }
            isLoading = false
        }
    }

    private func askQuestion(_ question: String) async throws -> String {
        let prompt = """
        Answer briefly (2-3 sentences max) about today's news digest.

        Today's News Digest:
        \(digestSummary)

        Question: \(question)
        """

        return try await WatchClaudeAPIService.shared.sendMessage(prompt: prompt, maxTokens: 150)
    }
}

// MARK: - Watch Digest Message Bubble

struct WatchDigestMessageBubble: View {
    let message: WatchDigestChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            Text(message.content)
                .font(.caption2)
                .padding(8)
                .background(message.role == .user ? Color.purple : Color.gray.opacity(0.3))
                .foregroundStyle(message.role == .user ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

#Preview {
    WatchDigestChatView(digestSummary: """
    Today's headlines focus on technology and global markets.
    Major tech companies announced new AI features.
    """)
}
