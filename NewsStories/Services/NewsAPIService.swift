//
//  NewsAPIService.swift
//  NewsStories
//
//  Created by Radif Sharafullin on 12/11/25.
//

import Foundation

// MARK: - News API Error

enum NewsAPIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case apiError(String)
    case rateLimited
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to parse server response"
        case .apiError(let message):
            return message
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .unauthorized:
            return "Invalid API key"
        }
    }
}

// MARK: - News API Service Protocol

protocol NewsAPIServiceProtocol {
    func fetchTopHeadlines(
        category: NewsCategory?,
        page: Int,
        pageSize: Int
    ) async throws -> NewsResponse
}

// MARK: - News API Service

final class NewsAPIService: NewsAPIServiceProtocol {
    private let baseURL = "https://newsapi.org/v2"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    private var apiKey: String {
        get throws {
            try Config.newsAPIKey
        }
    }

    func fetchTopHeadlines(
        category: NewsCategory? = nil,
        page: Int = 1,
        pageSize: Int = 20
    ) async throws -> NewsResponse {
        let key = try apiKey
        var components = URLComponents(string: "\(baseURL)/top-headlines")

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "apiKey", value: key),
            URLQueryItem(name: "country", value: "us"),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pageSize", value: String(pageSize))
        ]

        if let category {
            queryItems.append(URLQueryItem(name: "category", value: category.rawValue))
        }

        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw NewsAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NewsAPIError.networkError(URLError(.badServerResponse))
            }

            switch httpResponse.statusCode {
            case 200:
                break
            case 401:
                throw NewsAPIError.unauthorized
            case 429:
                throw NewsAPIError.rateLimited
            default:
                if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                    throw NewsAPIError.apiError(errorResponse.message)
                }
                throw NewsAPIError.apiError("Server error: \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            let newsResponse = try decoder.decode(NewsResponse.self, from: data)

            // Filter out articles with "[Removed]" title (deleted articles)
            let filteredArticles = newsResponse.articles.filter { article in
                !article.title.contains("[Removed]")
            }

            return NewsResponse(
                status: newsResponse.status,
                totalResults: newsResponse.totalResults,
                articles: filteredArticles
            )
        } catch let error as NewsAPIError {
            throw error
        } catch let error as DecodingError {
            throw NewsAPIError.decodingError(error)
        } catch {
            throw NewsAPIError.networkError(error)
        }
    }
}

// MARK: - API Error Response

private struct APIErrorResponse: Codable {
    let status: String
    let code: String
    let message: String
}
