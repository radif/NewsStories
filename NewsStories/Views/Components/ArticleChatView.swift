//
//  ArticleChatView.swift
//  NewsStories
//
//  Created by Radif Sharafullin on 12/11/25.
//

import SwiftUI

// MARK: - Chat Message

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp: Date

    enum Role {
        case user
        case assistant
    }

    init(role: Role, content: String) {
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

// MARK: - Article Chat View

struct ArticleChatView: View {
    let article: Article
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundStyle(.blue)
                Text("Ask about this article")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            // Messages List
            if !messages.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                            }

                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Thinking...")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.leading, 8)
                                .id("loading")
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .onChange(of: messages.count) {
                        withAnimation {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Input Field
            HStack(spacing: 8) {
                TextField("Ask a question...", text: $inputText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .focused($isInputFocused)
                    .onSubmit {
                        sendMessage()
                    }

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(inputText.isEmpty || isLoading ? .gray : .blue)
                }
                .disabled(inputText.isEmpty || isLoading)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Send Message

    private func sendMessage() {
        let question = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: question)
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        isInputFocused = false

        Task {
            do {
                let response = try await askQuestion(question)
                let assistantMessage = ChatMessage(role: .assistant, content: response)
                messages.append(assistantMessage)
            } catch {
                let errorMessage = ChatMessage(role: .assistant, content: "Sorry, I couldn't process your question. Please try again.")
                messages.append(errorMessage)
            }
            isLoading = false
        }
    }

    // MARK: - Ask Question

    private func askQuestion(_ question: String) async throws -> String {
        let prompt = """
        You are a helpful assistant answering questions about a news article. Be concise and informative.

        Article Title: \(article.title)
        Source: \(article.source.name)
        Content: \(article.content ?? article.description ?? "No content available")

        User Question: \(question)

        Please answer the question based on the article content. If the answer isn't in the article, say so.
        """

        return try await ClaudeAPIService.shared.sendMessage(prompt: prompt)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            Text(message.content)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(message.role == .user ? Color.blue : Color(.systemGray5))
                .foregroundStyle(message.role == .user ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ArticleChatView(article: .preview)
        .padding()
}
