# File Statistics - Thnk iOS App Codebase

## Overview
- **Total Lines**: 2,376 (Swift code only)
- **Total Files**: 16 Swift files
- **Average File Size**: ~148 lines per file

## Import Dependencies Summary
```
Foundation: 7 files (Models + Services)
SwiftUI: 8 files (App + Views)
CoreData: 3 files (App + Models)
AVFoundation: 2 files (Services)
Combine: 1 file (AudioManager)
Speech: 1 file (SpeechService)
UIKit: 2 files (AudioManager, ShareSheet)
```

## File Structure Analysis

### Large Files (>200 lines likely)
- ClaudeService.swift - Contains error enum at line 337+
- AnalysisView.swift - Contains EmotionIndicator at line 205+

### Medium Files (50-200 lines likely)
- Most service and view files
- Model files with multiple structs

### Small Files (<50 lines likely)
- Simple view files
- Basic model definitions

## Component Distribution

### Services (4 files)
- AudioManager.swift - Audio recording/playback
- ClaudeService.swift - AI integration (largest service file)
- PatternService.swift - Pattern analysis
- SpeechService.swift - Speech-to-text

### Views (7 files)
- AnalysisView.swift - Complex view with sub-components
- LoadingSplashView.swift - Simple loading UI
- ProcessingView.swift - Processing state
- RecordingView.swift - Recording interface
- ShareSheet.swift - UIKit bridge
- SplashView.swift - Launch screen
- SuggestionView.swift - AI suggestions

### Models (3 files)
- AnalysisResult.swift - AI analysis data
- EmotionalEntry.swift - Core Data entity
- EmotionPattern.swift - Pattern data (multiple structs)

### App Core (2 files)
- ThnkApp.swift - App entry + Core Data
- ContentView.swift - Root navigation

## Framework Usage Patterns

### SwiftUI Adoption
- 8/16 files use SwiftUI
- Primary UI framework
- Modern declarative approach

### Core Data Integration
- 3/16 files use Core Data
- Centralized in app core and models
- Persistence layer for emotional data

### AVFoundation Usage
- 2/16 files use AVFoundation
- Audio recording (AudioManager)
- Speech processing (SpeechService)

### Combine Framework
- 1/16 files explicitly import Combine
- Used in AudioManager for reactive audio handling
- ObservableObject pattern throughout services

## Error Handling
- 2 custom error enums identified
- ClaudeServiceError (line 337)
- SpeechServiceError (line 142)
- LocalizedError conformance for user-friendly messages

## Architecture Patterns
- **MVVM**: Models, Views, Services separation
- **ObservableObject**: Reactive state management
- **Dependency Injection**: Services injected into views
- **Protocol-Oriented**: Error protocols, View protocol