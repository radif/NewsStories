//
//  WatchClaudeAPIService.swift
//  NewsStoriesWatch Watch App
//
//  Created by Radif Sharafullin on 12/11/25.
//

import Foundation

// MARK: - Watch Claude API Service

final class WatchClaudeAPIService {
    static let shared = WatchClaudeAPIService()

    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let session: URLSession

    private var apiKey: String {
        get throws {
            try WatchConfig.claudeAPIKey
        }
    }

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15 // Shorter timeout for watch
        config.timeoutIntervalForResource = 20
        self.session = URLSession(configuration: config)
    }

    // MARK: - Timeout Helper

    private func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw WatchClaudeAPIError.timeout
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    // MARK: - Check Availability

    var isAvailable: Bool {
        get async {
            guard let key = try? apiKey, !key.isEmpty else {
                print("WatchClaude: Failed to get API key")
                return false
            }

            // On watch, just verify we have a valid API key format
            // Skip the network check to avoid blocking - we'll handle errors during actual requests
            let isValidKeyFormat = key.hasPrefix("sk-ant-")
            print("WatchClaude: API key valid format = \(isValidKeyFormat)")
            return isValidKeyFormat
        }
    }

    // MARK: - Generate Summary

    func generateSummary(for article: Article) async throws -> String {
        let key = try apiKey
        guard let url = URL(string: baseURL) else {
            throw WatchClaudeAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let prompt = """
        Summarize this news article in 2-3 brief sentences for a smartwatch display.

        Title: \(article.title)
        Content: \(article.content ?? article.description ?? "No content")
        """

        let body: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": 200,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WatchClaudeAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw WatchClaudeAPIError.apiError("Status: \(httpResponse.statusCode)")
        }

        let claudeResponse = try JSONDecoder().decode(WatchClaudeResponse.self, from: data)

        guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }) else {
            throw WatchClaudeAPIError.noContent
        }

        return textContent.text
    }

    // MARK: - Generate News Digest

    func generateNewsDigest(for articles: [Article], maxTokens: Int = 400) async throws -> (short: String, full: String) {
        let key = try apiKey
        guard let url = URL(string: baseURL) else {
            throw WatchClaudeAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let articleSummaries = articles.prefix(5).map { article in
            "- \(article.title)"
        }.joined(separator: "\n")

        let prompt = """
        Based on these headlines, provide:
        1. A short teaser (max 10 words) starting with "Today:"
        2. Write "---" as separator
        3. A brief 2 paragraph digest

        Headlines:
        \(articleSummaries)

        Format:
        Today: [teaser]
        ---
        [digest]
        """

        let body: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": maxTokens,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("WatchClaude: Starting digest request...")

        // Use timeout wrapper to prevent hanging
        let (data, response) = try await withTimeout(seconds: 15) { [session] in
            try await session.data(for: request)
        }

        print("WatchClaude: Digest request completed")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WatchClaudeAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw WatchClaudeAPIError.apiError("Status: \(httpResponse.statusCode)")
        }

        let claudeResponse = try JSONDecoder().decode(WatchClaudeResponse.self, from: data)

        guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }) else {
            throw WatchClaudeAPIError.noContent
        }

        let fullText = textContent.text
        let parts = fullText.components(separatedBy: "---")

        if parts.count >= 2 {
            let shortSummary = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let fullSummary = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            return (shortSummary, fullSummary)
        } else {
            let lines = fullText.components(separatedBy: "\n").filter { !$0.isEmpty }
            let shortSummary = lines.first ?? "Today's news"
            return (shortSummary, fullText)
        }
    }

    // MARK: - Send Message (Chat)

    func sendMessage(prompt: String, maxTokens: Int = 150) async throws -> String {
        let key = try apiKey
        guard let url = URL(string: baseURL) else {
            throw WatchClaudeAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": maxTokens,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Use timeout wrapper to prevent hanging
        let (data, response) = try await withTimeout(seconds: 15) { [session] in
            try await session.data(for: request)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WatchClaudeAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw WatchClaudeAPIError.apiError("Status: \(httpResponse.statusCode)")
        }

        let claudeResponse = try JSONDecoder().decode(WatchClaudeResponse.self, from: data)

        guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }) else {
            throw WatchClaudeAPIError.noContent
        }

        return textContent.text
    }
}

// MARK: - Watch Claude API Error

enum WatchClaudeAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case noContent
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response"
        case .apiError(let msg): return msg
        case .noContent: return "No content"
        case .timeout: return "Request timed out"
        }
    }
}

// MARK: - Watch Claude Response Models

struct WatchClaudeResponse: Codable {
    let content: [WatchClaudeContent]
}

struct WatchClaudeContent: Codable {
    let type: String
    let text: String
}
