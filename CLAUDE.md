# NewsStories - Development Guidelines

## Project Overview
A News Reader iOS application for the Rox take-home interview project. Fetches and displays articles from NewsAPI.org.

## API Configuration

### NewsAPI (News Feed)
- **Base URL**: `https://newsapi.org/v2`
- **Endpoint**: `/top-headlines`
- **API Key**: Stored in `Config/Secrets.plist`

### Claude API (AI Summaries)
- **Base URL**: `https://api.anthropic.com/v1/messages`
- **Model**: `claude-3-haiku-20240307`
- **API Key**: Stored in `Services/ClaudeAPIService.swift`

## Architecture
This project follows **MVVM (Model-View-ViewModel)** architecture with a clean separation of concerns:

```
NewsStories/
├── Config/           # Configuration (Secrets.plist, Config.swift)
├── Models/           # Data models (Article, NewsResponse, Source)
├── Services/         # Network layer
│   ├── NewsAPIService.swift    # News feed API
│   └── ClaudeAPIService.swift  # AI summaries API
├── ViewModels/       # Business logic (NewsFeedViewModel)
└── Views/            # SwiftUI views
    ├── NewsFeedView.swift
    ├── ArticleDetailView.swift
    └── Components/   # Reusable UI components (ArticleRowView, WebView)
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

## Claude API Integration (AI Summaries)

### How It Works
1. When `ArticleDetailView` loads, it checks Claude API availability
2. Availability check: Validates connectivity + API key with minimal request
3. If available: Generates a 2-3 paragraph summary using `claude-3-haiku`
4. If unavailable: Falls back to original article content

### Request Format
```json
{
  "model": "claude-3-haiku-20240307",
  "max_tokens": 500,
  "messages": [
    {
      "role": "user",
      "content": "Please provide a concise summary..."
    }
  ]
}
```

### Response Handling
```swift
struct ClaudeResponse: Codable {
    let content: [ClaudeContent]  // Extract text from first content block
}
```

### UI States
- **Loading**: Purple box with spinner + "Generating AI Summary..."
- **Success**: Purple box with sparkles icon + generated summary
- **Fallback**: Original article content (no special styling)

### Error Handling
- Network errors → Fallback to original content
- Invalid API key → Fallback to original content
- Timeout (30s) → Fallback to original content
- All failures are silent (logged to console only)

## Code Style
- Use Swift's native concurrency (async/await)
- Prefer composition over inheritance
- Keep views small and focused
- Use SwiftUI previews for rapid development

## Testing Considerations
- ViewModels should be testable with dependency injection
- Service layer uses protocol for mockability
- ClaudeAPIService uses singleton pattern for simplicity
