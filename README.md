# NewsStories

A News Reader iOS application built with SwiftUI that fetches and displays articles from NewsAPI.org.

## Screenshots

*Screenshots to be added after implementation*

## Setup Instructions

1. Clone the repository
2. Open `NewsStories.xcodeproj` in Xcode 15+
3. Configure the API key:
   ```bash
   cd NewsStories/Config
   cp Secrets.example.plist Secrets.plist
   ```
4. Edit `Secrets.plist` and replace `YOUR_API_KEY_HERE` with your NewsAPI key
5. Build and run on iOS 17+ simulator or device

**Get an API Key**: Register at [NewsAPI.org](https://newsapi.org/register) for a free key.

## API Key Security

The API key is stored securely using a plist-based configuration system:

```
NewsStories/Config/
├── Config.swift          # Reads secrets from plist at runtime
├── Secrets.plist         # Contains actual API key (gitignored)
└── Secrets.example.plist # Template for setup
```

**How it works:**
- `Secrets.plist` is excluded from git via `.gitignore`
- `Config.swift` loads the plist at runtime and provides type-safe access
- If the plist is missing or malformed, the app throws a descriptive error

**For reviewers:** The `Secrets.plist` file is included in this submission with a valid API key for testing purposes.

## Architecture

### MVVM Pattern

The app follows the **Model-View-ViewModel (MVVM)** architecture pattern:

```
NewsStories/
├── App/
│   └── NewsStoriesApp.swift      # App entry point
├── Config/
│   ├── Config.swift              # Runtime configuration reader
│   ├── Secrets.plist             # API keys (gitignored)
│   └── Secrets.example.plist     # Template for setup
├── Models/
│   └── Article.swift             # Data models (Article, Source, NewsResponse)
├── Services/
│   ├── NewsAPIService.swift      # News API client with async/await
│   └── ClaudeAPIService.swift    # Claude AI API for summaries
├── ViewModels/
│   └── NewsFeedViewModel.swift   # Business logic & state management
└── Views/
    ├── ContentView.swift         # Root navigation
    ├── NewsFeedView.swift        # Article list with pagination
    ├── ArticleDetailView.swift   # Full article display
    └── Components/
        └── ArticleRowView.swift  # Feed item cell
```

### Why MVVM?

1. **Separation of Concerns**: Views handle UI, ViewModels handle business logic, Models hold data
2. **Testability**: ViewModels can be unit tested independently
3. **SwiftUI Compatibility**: Works naturally with SwiftUI's reactive data binding
4. **Scalability**: Easy to add features without touching existing code

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Native URLSession | Avoid dependencies, async/await provides clean API |
| @Observable macro | Modern iOS 17+ approach, cleaner than ObservableObject |
| AsyncImage | Built-in SwiftUI component for async image loading |
| Protocol-based Service | Enables dependency injection and mocking for tests |
| Plist-based Secrets | Secure API key storage, easily gitignored, no hardcoded keys |

## Implemented Features

### Core Requirements

- [x] **News Feed View**
  - Displays list of articles from top-headlines endpoint
  - Shows headline, source name, formatted date, thumbnail
  - Loading state with progress indicator
  - Error state with retry option
  - Empty state handling
  - Infinite scroll pagination

- [x] **Article Detail View**
  - Full headline display
  - Featured image (when available)
  - Source name and formatted publication date
  - Article content/description
  - "Read Full Article" button linking to original
  - Back navigation to feed

### Extra Credit

- [x] **Category Filtering**
  - Filter by: General, Business, Technology, Entertainment, Health, Science, Sports
  - Visual indicator of selected category
  - Smooth category switching with loading states

- [x] **AI-Powered Article Summaries**
  - Automatic AI summary generation using Claude API (claude-3-haiku model)
  - Shows loading spinner while generating summary
  - Graceful fallback to original content if API unavailable or device offline
  - Visual distinction with purple-themed summary box

## Technical Details

### API Integration

#### NewsAPI (News Feed)
- **Endpoint**: `https://newsapi.org/v2/top-headlines`
- **Parameters**:
  - `country=us` (default)
  - `category` (optional filter)
  - `page` & `pageSize` (pagination)
- **Error Handling**: Network errors, API errors, and parsing errors handled gracefully

#### Claude API (AI Summaries)
- **Endpoint**: `https://api.anthropic.com/v1/messages`
- **Model**: `claude-3-haiku-20240307` (fast, cost-effective)
- **Features**:
  - Availability check before generating (connectivity + auth validation)
  - 30-second timeout for requests
  - Graceful fallback to original content on failure
- **Flow**:
  1. Check if device is online
  2. Validate API key with minimal request
  3. Generate 2-3 paragraph summary of article
  4. Display in purple-themed box or fallback to original

### State Management

```swift
enum ViewState {
    case idle
    case loading
    case loaded
    case error(String)
    case empty
}
```

### Pagination

- Page-based infinite scroll
- Loads next page when reaching end of list
- Prevents duplicate API calls during loading

## Shortcuts & Production Considerations

### Current Shortcuts

1. **Image Caching**: Using `AsyncImage` which has basic caching. Production would use a robust caching library like Kingfisher or SDWebImage
2. **Error Messages**: Simplified error messages. Production would have localized, user-friendly messages
3. **Offline Support**: No offline caching. Production would cache articles for offline reading

### Production Improvements

- Add unit tests for ViewModels and Services
- Implement proper image caching with disk persistence
- Add pull-to-refresh functionality
- Implement article bookmarking/saving
- Add search functionality
- Implement proper analytics/logging
- Add accessibility support (VoiceOver, Dynamic Type)
- Localization support

## Challenges & Solutions

### Challenge 1: NewsAPI Free Tier Limitations
The free tier only allows requests from localhost/simulator. Handled by clearly documenting this requirement.

### Challenge 2: Pagination Edge Cases
NewsAPI doesn't return explicit "hasMore" flag. Solved by comparing fetched articles count against totalResults.

### Challenge 3: Missing Article Data
Some articles have null images or descriptions. Handled with optional chaining and placeholder UI.

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Dependencies

**None** - Built entirely with native Apple frameworks:
- SwiftUI
- Foundation (URLSession)

## License

This project was created for interview purposes.
