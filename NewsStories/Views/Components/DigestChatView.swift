//
//  DigestChatView.swift
//  NewsStories
//
//  Created by Radif Sharafullin on 12/12/25.
//

import SwiftUI

// MARK: - Digest Chat Message

struct DigestChatMessage: Identifiable, Equatable {
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

// MARK: - Digest Chat View

struct DigestChatView: View {
    let digestSummary: String
    @State private var messages: [DigestChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundStyle(.purple)
                Text("Ask about today's news")
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
                                DigestMessageBubble(message: message)
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
                TextField("Ask about today's news...", text: $inputText)
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
                        .foregroundStyle(inputText.isEmpty || isLoading ? .gray : .purple)
                }
                .disabled(inputText.isEmpty || isLoading)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Send Message

    private func sendMessage() {
        let question = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }

        let userMessage = DigestChatMessage(role: .user, content: question)
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        isInputFocused = false

        Task {
            do {
                let response = try await askQuestion(question)
                let assistantMessage = DigestChatMessage(role: .assistant, content: response)
                messages.append(assistantMessage)
            } catch {
                let errorMessage = DigestChatMessage(role: .assistant, content: "Sorry, I couldn't process your question. Please try again.")
                messages.append(errorMessage)
            }
            isLoading = false
        }
    }

    // MARK: - Ask Question

    private func askQuestion(_ question: String) async throws -> String {
        let prompt = """
        You are a helpful news analyst assistant. Answer questions about today's news digest. Be concise and informative.

        Today's News Digest:
        \(digestSummary)

        User Question: \(question)

        Please answer based on the digest. If the answer isn't covered in the digest, acknowledge that and provide general context if appropriate.
        """

        return try await ClaudeAPIService.shared.sendMessage(prompt: prompt)
    }
}

// MARK: - Digest Message Bubble

struct DigestMessageBubble: View {
    let message: DigestChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            Text(message.content)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(message.role == .user ? Color.purple : Color(.systemGray5))
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
    DigestChatView(digestSummary: """
    Today's headlines focus on technology and global markets.

    Major tech companies announced new AI features, while economic indicators show mixed signals across regions.
    """)
    .padding()
}
