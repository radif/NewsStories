# NewsStories

A News Reader iOS application built with SwiftUI that fetches and displays articles from NewsAPI.org, featuring AI-powered summaries and chat using Claude API.

## Demo

Watch `demo.mp4` to see the project in action.

## Setup Instructions

### 1. Clone and Open
```bash
git clone git@github.com:radif/NewsStories.git
cd NewsStories
open NewsStories.xcodeproj
```

### 2. Configure API Keys

Create the secrets file:
```bash
cd NewsStories/Config
cp Secrets.example.plist Secrets.plist
```

Edit `Secrets.plist` and add your API keys:
```xml
<dict>
    <key>NEWS_API_KEY</key>
    <string>your_newsapi_key_here</string>
    <key>CLAUDE_API_KEY</key>
    <string>your_claude_api_key_here</string>
</dict>
```

### 3. Get API Keys

| API | Registration | Purpose |
|-----|--------------|---------|
| **NewsAPI** | [newsapi.org/register](https://newsapi.org/register) | News feed data |
| **Claude API** | [console.anthropic.com](https://console.anthropic.com/) | AI summaries & chat |

### 4. Build and Run
- Select iOS 17+ simulator or device
- Build and run (Cmd+R)

> **Note**: NewsAPI free tier only works on localhost/simulator. Claude API is optional - the app falls back to original content if unavailable.

## watchOS Companion App

The project includes a full-featured watchOS companion app that mirrors the iOS app functionality, optimized for the Apple Watch form factor.

### Features

- **News Feed**
  - Scrollable list of articles with thumbnails
  - Category filtering (General, Business, Technology, etc.)
  - Pull-to-refresh and pagination support
  - Optimized for Digital Crown navigation

- **Article Detail View**
  - Full headline and featured image
  - AI-powered summaries (purple-themed box)
  - "Full Article" button to view complete article content
  - Source name, author, and publication date

- **AI Chat**
  - Multiple input methods:
    - **Voice dictation** - speak your question
    - **Scribble** - draw letters with your finger
    - **Text input** - type using the system keyboard
  - Quick question buttons for common queries
  - Context-aware responses about the article
  - Optimized token limits for watch (200 for summaries, 150 for chat)

### Watch-Specific Optimizations

| Feature | iOS | watchOS |
|---------|-----|---------|
| Page size | 20 articles | 10 articles |
| AI summary tokens | 500 | 200 |
| AI chat tokens | 500 | 150 |
| Article view | WebView in-app | Native text content |
| Input methods | Keyboard | Voice, Scribble, Keyboard |

### Adding watchOS Target in Xcode

1. Open the project in Xcode
2. Go to **File > New > Target**
3. Select **watchOS > App** and click Next
4. Set Product Name: `NewsStoriesWatch`
5. Ensure "Watch App for Existing iOS App" is selected
6. Click Finish

### Adding Watch App Files

After creating the target, add the files from `NewsStoriesWatch Watch App/` folder:
1. In Xcode, right-click on the new watch target folder
2. Select **Add Files to "NewsStoriesWatch"**
3. Add all files from `NewsStoriesWatch Watch App/` directory
4. Ensure "Copy items if needed" is checked
5. Make sure the watch target is selected

### Copy Secrets.plist to Watch App

Copy `NewsStories/Config/Secrets.plist` to `NewsStoriesWatch Watch App/Config/` to share API keys.

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
        ├── ArticleRowView.swift  # Feed item cell
        ├── WebView.swift         # In-app browser for articles
        └── ArticleChatView.swift # AI chat about articles

NewsStoriesWatch Watch App/
├── NewsStoriesWatchApp.swift     # Watch app entry point
├── Config/
│   ├── WatchConfig.swift         # Configuration reader
│   └── Secrets.plist             # API keys (copy from iOS app)
├── Models/
│   └── Article.swift             # Shared data models
├── Services/
│   ├── WatchNewsAPIService.swift # News API client
│   └── WatchClaudeAPIService.swift # Claude API client
├── ViewModels/
│   └── WatchNewsFeedViewModel.swift
└── Views/
    ├── WatchNewsFeedView.swift   # Watch news list
    ├── WatchArticleRowView.swift # Watch list item
    ├── WatchArticleDetailView.swift # Watch article detail
    └── WatchArticleChatView.swift # Watch AI chat
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

- [x] **AI Chat About Articles**
  - Interactive chat to ask questions about the article
  - Context-aware responses based on article content
  - Blue-themed chat UI with message bubbles
  - Only visible when Claude API is available

- [x] **watchOS Companion App**
  - Full news feed with category filtering
  - Article detail with AI summaries
  - AI chat with voice, scribble, and text input
  - Full article content viewer
  - Optimized UI and reduced token limits for watch

## Technical Details

### API Integration

#### NewsAPI (News Feed)
- **Endpoint**: `https://newsapi.org/v2/top-headlines`
- **Parameters**:
  - `country=us` (default)
  - `category` (optional filter)
  - `page` & `pageSize` (pagination)
- **Error Handling**: Network errors, API errors, and parsing errors handled gracefully

#### Claude API (AI Features)
- **Endpoint**: `https://api.anthropic.com/v1/messages`
- **Model**: `claude-3-haiku-20240307` (fast, cost-effective)
- **Features**:
  - Availability check before generating (connectivity + auth validation)
  - 30-second timeout for requests
  - Graceful fallback to original content on failure
- **AI Summary Flow**:
  1. Check if device is online
  2. Validate API key with minimal request
  3. Generate 2-3 paragraph summary of article
  4. Display in purple-themed box or fallback to original
- **AI Chat Flow**:
  1. User types question in chat input
  2. Send question with article context to Claude
  3. Display response in chat bubble
  4. Maintain conversation history within session

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
- watchOS 10.0+
- Xcode 15.0+
- Swift 5.9+

## Dependencies

**None** - Built entirely with native Apple frameworks:
- SwiftUI
- Foundation (URLSession)
- WebKit (iOS only, for in-app browser)
- WatchKit (watchOS only)

## License

This project was created for interview purposes.
