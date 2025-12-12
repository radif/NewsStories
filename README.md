# NewsStories

A News Reader iOS application built with SwiftUI that fetches and displays articles from NewsAPI.org.

## Screenshots

*Screenshots to be added after implementation*

## Setup Instructions

1. Clone the repository
2. Open `NewsStories.xcodeproj` in Xcode 15+
3. Build and run on iOS 17+ simulator or device

**Note**: The API key is already configured in the app. No additional setup required.

## Architecture

### MVVM Pattern

The app follows the **Model-View-ViewModel (MVVM)** architecture pattern:

```
NewsStories/
├── App/
│   └── NewsStoriesApp.swift      # App entry point
├── Models/
│   └── Article.swift             # Data models (Article, Source, NewsResponse)
├── Services/
│   └── NewsAPIService.swift      # Network layer with async/await
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

## Technical Details

### API Integration

- **Endpoint**: `https://newsapi.org/v2/top-headlines`
- **Parameters**:
  - `country=us` (default)
  - `category` (optional filter)
  - `page` & `pageSize` (pagination)
- **Error Handling**: Network errors, API errors, and parsing errors handled gracefully

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
4. **API Key Security**: Key is hardcoded. Production would use secure storage or backend proxy

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
