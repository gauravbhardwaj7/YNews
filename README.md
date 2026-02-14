# 📰 NewsApp

News app built entirely with **UIKit** and **Swift**, following clean **MVVM** architecture with separation of concerns across dedicated layers.

---

## Video
https://drive.google.com/file/d/1dXpS1HIESk3V8XEVESWhnG-o22QR0013/view

## Features

### 1. 📋 News Feed
- Articles fetched from [NewsAPI.org](https://newsapi.org)
- Displays **title**, **thumbnail image**, **source name**, and **publication date**
- **Infinite scroll** powered by a custom `Paginator` — triggers the next page when the user nears the last 3 cells
- Pull-to-refresh to reload the latest articles

### 2. 📄 Article Detail Screen
- Full article content displayed on tap
- **Share** article via the native share sheet
- **Bookmark / Unbookmark** directly from the detail screen
- **Open in Safari** for the full web experience

### 3. 🔍 Search
- Keyword search across article titles and sources
- **Debounced input** (300 ms) — network request only fires when the user pauses typing
- Resets pagination on every new query

### 4. 🔖 Bookmarks
- Save and unsave articles with a single tap
- Dedicated **Bookmarks screen** accessible from the navigation bar
- Bookmarks persist across app restarts via Core Data
- Bookmark bar button hidden automatically when there are no saved articles

### 5. 💾 Persistence — Core Data
- Articles cached locally for **offline reading** (pages 1 & 2)
- Bookmarked articles stored permanently regardless of cache policy
- Two-level **image cache** — memory (`NSCache`) + disk (`FileManager`) — so article images load instantly even offline

### 6. 📡 Offline Mode
- `NWPathMonitor`-based `NetworkMonitor` detects connectivity changes **instantly** (no failed request needed)
- Shows a **contextual banner** (cached data available) or **full-screen error** (nothing to show) depending on state
- **Pull-to-refresh is disabled** while offline
- Auto-retries silently when connection is restored

### 7. 🔔 Local Notifications
- Schedule a "Trending" push notification for any article
- Tapping the notification **deep links** directly to that article's detail screen

### 8. 🔗 Deep Linking
- `DeepLinkRouter` parses incoming notifications and stores a pending article

### 9. 🧪 Unit Tests

---

## 🏗 Architecture — MVVM + Repository Pattern

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                             │
│                                                             │
│   ViewController  ──wire──▶  NewsLayout (views)            │
│         │                    NewsStateRenderer (state→UI)   │
│         │                    NewsCollectionViewHandler      │
│         │                    DeepLinkHandler                │
│         ▼                                                   │
│   BookmarkedArticlesViewController                          │
│   NewsDetailViewController                                  │
└────────────────────┬────────────────────────────────────────┘
                     │ @Published (Combine)
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    ViewModel Layer                          │
│                                                             │
│   NewsViewModel          BookmarkViewModel                  │
│   • state: NewsViewState  • bookmarkedArticles: [Article]   │
│   • articles: [Article]   • toggle / add / remove           │
│   • isOnline: Bool                                          │
│   • paginator: Paginator                                    │
└────────────────────┬────────────────────────────────────────┘
                     │ async throws
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                   Repository Layer                          │
│                                                             │
│              NewsRepositoryImpl                             │
│            ┌──────────┴──────────┐                         │
│            ▼                     ▼                         │
│   NewsRemoteRepository    NewsLocalRepository               │
│   (URLSession + Decode)   (Core Data — pages 1 & 2)        │
│                                                             │
│              BookmarkRepository                             │
│              (Core Data — permanent)                        │
└─────────────────────────────────────────────────────────────┘
```

---



## 📂 Project Structure

```
NewsApp/
│
├── App/
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
│
├── Networking/
│   ├── NetworkMonitor.swift          # NWPathMonitor reachability
│   ├── NetworkError.swift            # Typed error enum
│   ├── NewsRemoteRepository.swift    # URLSession + NewsAPI
│   └── NewsRepositoryImpl.swift      # Online/offline routing
│
├── Persistence/
│   ├── NewsLocalRepository.swift     # Core Data cache (pages 1–2)
│   ├── BookmarkRepository.swift      # Core Data bookmarks
│   └── ArticleEntity.swift           # NSManagedObject + mapping
│
├── Models/
│   └── NewsResponse.swift            # Article, Source, NewsResponse
│
├── ViewModels/
│   ├── NewsViewModel.swift           # Pagination, state, connectivity
│   └── BookmarkViewModel.swift       # Bookmark CRUD
│
├── Views/
│   ├── News/
│   │   ├── ViewController.swift          # Lifecycle + wiring only
│   │   ├── NewsLayout.swift              # Subviews + constraints
│   │   ├── NewsStateRenderer.swift       # State → UI mutations
│   │   ├── NewsCollectionViewHandler.swift # DataSource + Delegate
│   │   └── NewsCellView.swift            # Article cell
│   │
│   ├── Bookmarks/
│   │   └── BookmarkedArticlesViewController.swift
│   │
│   ├── Detail/
│   │   └── NewsDetailViewController.swift
│   │
│   └── Shared/
│       ├── ErrorStateView.swift          # Reusable full-screen error
│       └── BannerNavigationController.swift # Offline banner in nav bar
│
├── Services/
│   ├── ImageLoader.swift             # Memory + disk image cache
│   ├── NotificationService.swift     # Local push scheduling
│   └── DeepLinkRouter.swift          # Pending article routing
│
├── DeepLinking/
│   └── DeepLinkHandler.swift         # Navigation retry logic
│
├── Pagination/
│   └── Paginator.swift               # Infinite scroll trigger
│
└── Tests/
    ├── NewsViewModelTests.swift
    ├── NewsRepositoryTests.swift
    ├── BookmarkViewModelTests.swift
    └── PaginatorTests.swift
```

---


## 🚀 Getting Started

### Prerequisites
- Xcode 15+
- iOS 15.0+ simulator or device
- A free [NewsAPI.org](https://newsapi.org) API key

### Setup

1. Clone the repository
```bash
git clone https://github.com/your-username/NewsApp.git
cd NewsApp
```

2. Open the project
```bash
open NewsApp.xcodeproj
```

3. Add your API key in `NewsRemoteRepository.swift`
```swift
.init(name: "apiKey", value: "YOUR_API_KEY_HERE")
```

4. Build and run (`Cmd + R`)

---

## ⚠️ Notes

- **NewsAPI free tier** limits results to the first 100 articles per query and restricts historical date ranges, which is why some pagination features (e.g., load-more beyond page 5) may stop early — this is an API constraint, not an app bug.
- The free tier also does not support all sorting and filtering options that would enable features like top headlines by category.

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.
