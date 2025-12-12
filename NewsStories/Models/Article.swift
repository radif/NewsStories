//
//  Article.swift
//  NewsStories
//
//  Created by Radif Sharafullin on 12/11/25.
//

import Foundation

// MARK: - News API Response

struct NewsResponse: Codable {
    let status: String
    let totalResults: Int
    let articles: [Article]
}

// MARK: - Article

struct Article: Codable, Identifiable, Equatable, Hashable {
    let source: Source
    let author: String?
    let title: String
    let description: String?
    let url: String
    let urlToImage: String?
    let publishedAt: String
    let content: String?

    var id: String {
        url
    }

    var imageURL: URL? {
        guard let urlToImage else { return nil }
        return URL(string: urlToImage)
    }

    var articleURL: URL? {
        URL(string: url)
    }

    var publishedDate: Date? {
        ISO8601DateFormatter().date(from: publishedAt)
    }

    var formattedDate: String {
        guard let date = publishedDate else {
            return publishedAt
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var formattedFullDate: String {
        guard let date = publishedDate else {
            return publishedAt
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var displayTitle: String {
        // NewsAPI sometimes appends source to title, clean it up
        if let range = title.range(of: " - ", options: .backwards) {
            return String(title[..<range.lowerBound])
        }
        return title
    }

    var displayContent: String {
        // NewsAPI truncates content with character count, clean it up
        guard let content else {
            return description ?? "No content available."
        }

        if let range = content.range(of: "\\[\\+\\d+ chars\\]", options: .regularExpression) {
            return String(content[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        return content
    }

    static func == (lhs: Article, rhs: Article) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Source

struct Source: Codable, Equatable, Hashable {
    let id: String?
    let name: String
}

// MARK: - News Category

enum NewsCategory: String, CaseIterable, Identifiable {
    case general
    case business
    case technology
    case entertainment
    case health
    case science
    case sports

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .general: return "newspaper"
        case .business: return "chart.line.uptrend.xyaxis"
        case .technology: return "desktopcomputer"
        case .entertainment: return "film"
        case .health: return "heart"
        case .science: return "atom"
        case .sports: return "sportscourt"
        }
    }
}
