//
//  WatchArticleChatView.swift
//  NewsStoriesWatch Watch App
//
//  Created by Radif Sharafullin on 12/11/25.
//

import SwiftUI

// MARK: - Watch Chat Message

struct WatchChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: Role
    let content: String

    enum Role {
        case user
        case assistant
    }
}

// MARK: - Watch Article Chat View

struct WatchArticleChatView: View {
    let article: Article
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [WatchChatMessage] = []
    @State private var isLoading = false
    @State private var inputText = ""

    private let quickQuestions = [
        "Summarize this",
        "Key points?",
        "Why important?",
        "What's next?"
    ]

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 8) {
                        // Quick Questions
                        if messages.isEmpty {
                            Text("Ask about this article")
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
                                .disabled(isLoading)
                            }
                        }

                        // Custom Input (voice/scribble/text)
                        customInputSection

                        // Messages
                        ForEach(messages) { message in
                            WatchMessageBubble(message: message)
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
            .navigationTitle("AI Chat")
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
                    .foregroundStyle(.blue)
            }
            .disabled(inputText.isEmpty || isLoading)
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Send Question

    private func sendQuestion(_ question: String) {
        let userMessage = WatchChatMessage(role: .user, content: question)
        messages.append(userMessage)
        isLoading = true

        Task {
            do {
                let response = try await askQuestion(question)
                let assistantMessage = WatchChatMessage(role: .assistant, content: response)
                messages.append(assistantMessage)
            } catch {
                let errorMessage = WatchChatMessage(role: .assistant, content: "Sorry, couldn't process that.")
                messages.append(errorMessage)
            }
            isLoading = false
        }
    }

    private func askQuestion(_ question: String) async throws -> String {
        let prompt = """
        Answer briefly (2-3 sentences max) about this news article.

        Article: \(article.title)
        Content: \(article.content ?? article.description ?? "")

        Question: \(question)
        """

        return try await WatchClaudeAPIService.shared.sendMessage(prompt: prompt, maxTokens: 150)
    }
}

// MARK: - Watch Message Bubble

struct WatchMessageBubble: View {
    let message: WatchChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            Text(message.content)
                .font(.caption2)
                .padding(8)
                .background(message.role == .user ? Color.blue : Color.gray.opacity(0.3))
                .foregroundStyle(message.role == .user ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

#Preview {
    WatchArticleChatView(article: .preview)
}
