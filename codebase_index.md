# Thnk iOS App - Codebase Index

## Project Overview
This is a Swift iOS application called "thnk" that appears to be an emotional analysis app with voice recording capabilities and AI-powered insights.

**Total Swift Code**: 2,376 lines across 16 files

## Project Structure

### Root Directory
```
.
├── CLAUDE.md               # Claude AI documentation
├── README.md              # Project documentation
├── index.html             # Web interface
├── privacy.html           # Privacy policy
├── .github/workflows/     # GitHub Actions CI/CD
└── thnk/                  # Main iOS app source
```

### Swift App Structure (`./thnk/`)

#### App Core (`./thnk/App/`)
- `ThnkApp.swift` - Main app entry point and Core Data persistence
- `ContentView.swift` - Root view controller

#### Models (`./thnk/Models/`)
- `AnalysisResult.swift` - Data model for AI analysis results
- `EmotionalEntry.swift` - Core emotional data entry model
- `EmotionPattern.swift` - Pattern analysis and trajectory models

#### Services (`./thnk/Services/`)
- `AudioManager.swift` - Audio recording and playback management
- `ClaudeService.swift` - Integration with Claude AI API
- `PatternService.swift` - Emotional pattern analysis service
- `SpeechService.swift` - Speech-to-text conversion service

#### Views (`./thnk/Views/`)
- `AnalysisView.swift` - Display analysis results and emotion indicators
- `LoadingSplashView.swift` - Loading screen
- `ProcessingView.swift` - Processing state UI
- `RecordingView.swift` - Voice recording interface
- `ShareSheet.swift` - Social sharing functionality
- `SplashView.swift` - App splash screen
- `SuggestionView.swift` - AI suggestions display

#### Resources (`./thnk/Resources/`)
- `Assets.xcassets/` - App icons and image assets
- `appicons/` - Additional icon resources

#### Core Data (`./thnk/Core Data/`)
- `ThnkDataModel.xcdatamodeld/` - Core Data model definition

## Key Swift Language Constructs

### Structs
- `ThnkApp` - Main app struct
- `ContentView` - Root view
- `LoadingSplashView` - Loading UI
- `AnalysisView` - Analysis display
- `EmotionIndicator` - Emotion visualization
- `ShareSheet` - Sharing interface
- `ProcessingView` - Processing UI
- `SplashView` - Splash screen
- `SuggestionView` - Suggestions UI
- `RecordingView` - Recording interface
- `EmotionPattern` - Emotion data model
- `EmotionalTrajectory` - Emotion tracking
- `PatternAnalysis` - Analysis model
- `AnalysisResult` - Result data model

### Classes (ObservableObject)
- `PersistenceController` - Core Data management
- `AudioManager` - Audio handling
- `PatternService` - Pattern analysis
- `ClaudeService` - AI service integration
- `SpeechService` - Speech processing

### Enums
- `ClaudeServiceError` - Error handling for AI service
- `SpeechServiceError` - Speech service error handling

## Key Technologies & Frameworks
- **SwiftUI** - Primary UI framework
- **Core Data** - Data persistence
- **AVFoundation** - Audio recording/playback
- **Speech** - Speech-to-text conversion
- **Combine** - Reactive programming
- **Foundation** - Core Swift framework

## External Dependencies
- **Claude AI API** - Emotional analysis and insights
- **GitHub Actions** - CI/CD pipeline
- **Xcode Project** - iOS development environment

## File Types by Count
- Swift files: 16
- JSON files: 3 (Asset catalog configurations)
- HTML files: 2 (Web interface and privacy)
- Markdown files: 2 (Documentation)
- YAML files: 2 (GitHub workflows)

## Development Environment
- **IDE**: Xcode project with workspace configuration
- **Version Control**: Git repository
- **CI/CD**: GitHub Actions for static site deployment
- **Platform**: iOS (Swift/SwiftUI)

---
*Index generated automatically - Last updated: $(date)*