# NewsStories - Development Guidelines

## Project Overview
A News Reader iOS application for the Rox take-home interview project. Fetches and displays articles from NewsAPI.org.

## API Configuration
- **Base URL**: `https://newsapi.org/v2`
- **Endpoint**: `/top-headlines`
- **API Key**: `34ae7bc139e34e0fb44de558e563bb04`

## Architecture
This project follows **MVVM (Model-View-ViewModel)** architecture with a clean separation of concerns:

```
NewsStories/
├── Models/           # Data models (Article, NewsResponse, Source)
├── Services/         # Network layer (NewsAPIService)
├── ViewModels/       # Business logic (NewsFeedViewModel)
├── Views/            # SwiftUI views
│   ├── NewsFeedView.swift
│   ├── ArticleDetailView.swift
│   └── Components/   # Reusable UI components
└── Utilities/        # Helpers (DateFormatter, ImageCache)
```

## Key Technical Decisions

### Networking
- Native `URLSession` with async/await
- No third-party dependencies for networking
- Proper error handling with custom error types

### Image Loading
- `AsyncImage` for simple async image loading
- Placeholder images for missing thumbnails

### State Management
- `@Observable` macro (iOS 17+) for ViewModels
- Proper loading, error, and empty states

### Pagination
- Infinite scroll with page-based pagination
- NewsAPI uses `page` and `pageSize` parameters

## API Usage Notes

### Top Headlines Endpoint
```
GET https://newsapi.org/v2/top-headlines
Parameters:
- apiKey: required
- country: us (default)
- category: business, entertainment, general, health, science, sports, technology
- page: pagination (starts at 1)
- pageSize: results per page (max 100, default 20)
```

### Response Structure
```json
{
  "status": "ok",
  "totalResults": 38,
  "articles": [
    {
      "source": { "id": "...", "name": "..." },
      "author": "...",
      "title": "...",
      "description": "...",
      "url": "...",
      "urlToImage": "...",
      "publishedAt": "2024-01-01T12:00:00Z",
      "content": "..."
    }
  ]
}
```

## Code Style
- Use Swift's native concurrency (async/await)
- Prefer composition over inheritance
- Keep views small and focused
- Use SwiftUI previews for rapid development

## Testing Considerations
- ViewModels should be testable with dependency injection
- Service layer uses protocol for mockability
