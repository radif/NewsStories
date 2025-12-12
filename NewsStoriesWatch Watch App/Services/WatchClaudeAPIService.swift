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
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Check Availability

    var isAvailable: Bool {
        get async {
            guard let key = try? apiKey else {
                print("WatchClaude: Failed to get API key")
                return false
            }

            guard let url = URL(string: baseURL) else { return false }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(key, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.setValue("application/json", forHTTPHeaderField: "content-type")

            let body: [String: Any] = [
                "model": "claude-3-haiku-20240307",
                "max_tokens": 1,
                "messages": [["role": "user", "content": "hi"]]
            ]

            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            do {
                let (_, response) = try await session.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    return httpResponse.statusCode == 200
                }
                return false
            } catch {
                print("WatchClaude: Availability check error: \(error.localizedDescription)")
                return false
            }
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
}

// MARK: - Watch Claude API Error

enum WatchClaudeAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case noContent

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response"
        case .apiError(let msg): return msg
        case .noContent: return "No content"
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
