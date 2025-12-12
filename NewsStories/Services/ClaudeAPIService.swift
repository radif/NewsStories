//
//  ClaudeAPIService.swift
//  NewsStories
//
//  Created by Radif Sharafullin on 12/11/25.
//

import Foundation

// MARK: - Claude API Service

final class ClaudeAPIService {
    static let shared = ClaudeAPIService()

    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let session: URLSession

    private var apiKey: String {
        get throws {
            try Config.claudeAPIKey
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
            guard isOnline else {
                print("ClaudeAPIService: Device is offline")
                return false
            }
            guard let key = try? apiKey else {
                print("ClaudeAPIService: Failed to get API key from Config")
                return false
            }
            print("ClaudeAPIService: API key loaded, checking availability...")

            // Quick ping to check if API is reachable
            guard let url = URL(string: baseURL) else { return false }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(key, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.setValue("application/json", forHTTPHeaderField: "content-type")

            // Minimal request just to check auth
            let body: [String: Any] = [
                "model": "claude-3-haiku-20240307",
                "max_tokens": 1,
                "messages": [["role": "user", "content": "hi"]]
            ]

            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            do {
                let (data, response) = try await session.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    print("ClaudeAPIService: Availability check status code = \(httpResponse.statusCode)")
                    if httpResponse.statusCode != 200 {
                        if let body = String(data: data, encoding: .utf8) {
                            print("ClaudeAPIService: Error response = \(body)")
                        }
                    }
                    return httpResponse.statusCode == 200
                }
                return false
            } catch {
                print("ClaudeAPIService: Availability check error = \(error.localizedDescription)")
                return false
            }
        }
    }

    private var isOnline: Bool {
        // Simple connectivity check
        let url = URL(string: "https://api.anthropic.com")!
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5

        let semaphore = DispatchSemaphore(value: 0)
        var online = false

        let task = URLSession.shared.dataTask(with: request) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse {
                online = (200...499).contains(httpResponse.statusCode)
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()

        return online
    }

    // MARK: - Generate Summary

    func generateSummary(for article: Article) async throws -> String {
        let key = try apiKey
        guard let url = URL(string: baseURL) else {
            throw ClaudeAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let prompt = """
        Please provide a concise, engaging summary of this news article in 2-3 paragraphs. \
        Focus on the key points and make it informative for readers who want a quick overview.

        Title: \(article.title)

        Content: \(article.content ?? article.description ?? "No content available")

        Source: \(article.source.name)
        """

        let body: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": 500,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw ClaudeAPIError.unauthorized
            }
            throw ClaudeAPIError.apiError("Status code: \(httpResponse.statusCode)")
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }) else {
            throw ClaudeAPIError.noContent
        }

        return textContent.text
    }

    // MARK: - Generate News Digest

    func generateNewsDigest(for articles: [Article], maxTokens: Int = 800) async throws -> (short: String, full: String) {
        let key = try apiKey
        guard let url = URL(string: baseURL) else {
            throw ClaudeAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let articleSummaries = articles.prefix(10).map { article in
            "- \(article.title) (\(article.source.name)): \(article.description ?? "")"
        }.joined(separator: "\n")

        let prompt = """
        You are a news analyst. Based on these top news headlines, provide:

        1. FIRST: A one-sentence (max 15 words) teaser summary starting with "Today:" that captures the main theme.
        2. THEN: Write "---" on its own line as a separator.
        3. AFTER: A comprehensive 3-4 paragraph news digest covering the key stories and their significance.

        Headlines:
        \(articleSummaries)

        Format your response exactly as:
        Today: [short teaser]
        ---
        [full digest paragraphs]
        """

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
            throw ClaudeAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw ClaudeAPIError.unauthorized
            }
            throw ClaudeAPIError.apiError("Status code: \(httpResponse.statusCode)")
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }) else {
            throw ClaudeAPIError.noContent
        }

        // Parse the response to separate short and full summaries
        let fullText = textContent.text
        let parts = fullText.components(separatedBy: "---")

        if parts.count >= 2 {
            let shortSummary = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let fullSummary = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            return (shortSummary, fullSummary)
        } else {
            // Fallback if separator not found
            let lines = fullText.components(separatedBy: "\n").filter { !$0.isEmpty }
            let shortSummary = lines.first ?? "Today's top stories"
            return (shortSummary, fullText)
        }
    }

    // MARK: - Send Message (Chat)

    func sendMessage(prompt: String, maxTokens: Int = 300) async throws -> String {
        let key = try apiKey
        guard let url = URL(string: baseURL) else {
            throw ClaudeAPIError.invalidURL
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
            throw ClaudeAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw ClaudeAPIError.unauthorized
            }
            throw ClaudeAPIError.apiError("Status code: \(httpResponse.statusCode)")
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }) else {
            throw ClaudeAPIError.noContent
        }

        return textContent.text
    }
}

// MARK: - Claude API Error

enum ClaudeAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case apiError(String)
    case noContent
    case offline

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .unauthorized:
            return "Invalid API key"
        case .apiError(let message):
            return "API error: \(message)"
        case .noContent:
            return "No content in response"
        case .offline:
            return "Device is offline"
        }
    }
}

// MARK: - Claude Response Models

struct ClaudeResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeContent]
    let model: String
    let stopReason: String?
    let usage: ClaudeUsage

    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
        case usage
    }
}

struct ClaudeContent: Codable {
    let type: String
    let text: String
}

struct ClaudeUsage: Codable {
    let inputTokens: Int
    let outputTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}
