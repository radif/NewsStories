//
//  WatchNewsAPIService.swift
//  NewsStoriesWatch Watch App
//
//  Created by Radif Sharafullin on 12/11/25.
//

import Foundation

// MARK: - Watch News API Error

enum WatchNewsAPIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case apiError(String)
    case rateLimited
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return error.localizedDescription
        case .decodingError:
            return "Parse error"
        case .apiError(let message):
            return message
        case .rateLimited:
            return "Rate limited"
        case .unauthorized:
            return "Invalid API key"
        }
    }
}

// MARK: - Watch News API Service

final class WatchNewsAPIService {
    private let baseURL = "https://newsapi.org/v2"
    private let session: URLSession

    private var apiKey: String {
        get throws {
            try WatchConfig.newsAPIKey
        }
    }

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchTopHeadlines(
        category: NewsCategory? = nil,
        page: Int = 1,
        pageSize: Int = 10
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
            throw WatchNewsAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw WatchNewsAPIError.networkError(URLError(.badServerResponse))
            }

            switch httpResponse.statusCode {
            case 200:
                break
            case 401:
                throw WatchNewsAPIError.unauthorized
            case 429:
                throw WatchNewsAPIError.rateLimited
            default:
                throw WatchNewsAPIError.apiError("Error: \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            let newsResponse = try decoder.decode(NewsResponse.self, from: data)

            let filteredArticles = newsResponse.articles.filter { article in
                !article.title.contains("[Removed]")
            }

            return NewsResponse(
                status: newsResponse.status,
                totalResults: newsResponse.totalResults,
                articles: filteredArticles
            )
        } catch let error as WatchNewsAPIError {
            throw error
        } catch let error as DecodingError {
            throw WatchNewsAPIError.decodingError(error)
        } catch {
            throw WatchNewsAPIError.networkError(error)
        }
    }
}
