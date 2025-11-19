# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AI翰林院 (AI Hanlin Academy) is a next-generation iOS AI mobile workstation built with SwiftUI, SwiftData, and CloudKit. It integrates 20+ AI service providers, features a comprehensive tool ecosystem, and provides multi-modal AI capabilities including vision analysis, knowledge management (RAG), and real-time streaming interactions.

**Key Technologies:**
- Swift 5.9+ with SwiftUI for UI
- SwiftData + CloudKit for data persistence and sync
- Async/await for streaming API responses
- Swift Package Manager for dependencies
- iOS 18.0+ minimum deployment target

## Common Development Commands

### Building and Running
```bash
# Open project in Xcode
open AI_HLY.xcodeproj

# Build: Cmd+B in Xcode
# Run: Cmd+R in Xcode
# Clean build folder: Cmd+Shift+K
```

### Development Setup
1. Clone the repository and open `AI_HLY.xcodeproj`
2. Copy `Config.xcconfig.template` to `Config.xcconfig` (if needed for API keys)
3. Select your development team in Xcode signing settings
4. Modify Bundle Identifier if needed: `com.aihanlin.AI-HLY`
5. Build and run on simulator or device

### Testing
This project currently uses manual testing on devices/simulators. No formal XCTest suites are configured.

## Architecture Overview

### Three-Layer Architecture

```
┌─────────────────────────────────┐
│   UI Layer (SwiftUI Views)      │
│   ChatView, KnowledgeListView, ModelsView, etc. │
├─────────────────────────────────┤
│   Service Layer                 │
│   APIManager, Tools, Services   │
├─────────────────────────────────┤
│   Data Layer (SwiftData)        │
│   Models + CloudKit Sync        │
└─────────────────────────────────┘
```

### Critical Files and Their Roles

**Application Entry:**
- [AI_HLY.swift](AI_HLY/AI_HLY.swift) - App entry point, SwiftData container setup, CloudKit configuration
- [MainTabView.swift](AI_HLY/MainTabView.swift) - Four-tab navigation (List, Knowledge, Models, Settings)

**Main Views (Large Files):**
- [ChatView.swift](AI_HLY/ChatView.swift) (~179KB) - Main chat interface with streaming responses, tool result display
- [KnowledgeListView.swift](AI_HLY/KnowledgeListView.swift) - Knowledge base management UI
- [ModelsView.swift](AI_HLY/ModelsView.swift) - AI model catalog and selection
- [SettingsView.swift](AI_HLY/SettingsView.swift) - Settings hub

**Core Service Layer:**
- [Services/APIServices/APIManager.swift](AI_HLY/Services/APIServices/APIManager.swift) (~251KB) - **Central API orchestrator**
  - Handles streaming responses from 20+ AI providers
  - Defines `StreamData` struct (consolidates all response types: content, reasoning, toolContent, images, audio, etc.)
  - Manages tool execution and coordination
  - Implements memory operations (save/retrieve/update)

- [Services/ChatServices/ChatTools.swift](AI_HLY/Services/ChatServices/ChatTools.swift) - **Tool registry and metadata**
  - Bilingual tool descriptions (Chinese/English)
  - Tool definitions for memory, maps, weather, calendar, health, code execution, canvas, etc.
  - Dynamic tool enabling based on settings

**Tool Implementations:**
- [Services/ChatServices/WebSearchTool.swift](AI_HLY/Services/ChatServices/WebSearchTool.swift) - Multi-search-engine integration (7 providers)
- [Services/ChatServices/WebReadTool.swift](AI_HLY/Services/ChatServices/WebReadTool.swift) - Web content extraction with SwiftSoup
- [Services/ChatServices/MapServices.swift](AI_HLY/Services/ChatServices/MapServices.swift) (~52KB) - Location, POI search, navigation
- [Services/ChatServices/WeatherServices.swift](AI_HLY/Services/ChatServices/WeatherServices.swift) - QWeather + OpenWeather integration
- [Services/ChatServices/CalendarService.swift](AI_HLY/Services/ChatServices/CalendarService.swift) - EventKit integration
- [Services/ChatServices/HealthServices.swift](AI_HLY/Services/ChatServices/HealthServices.swift) (~28KB) - HealthKit data read/write
- [Services/ChatServices/CodeServices.swift](AI_HLY/Services/ChatServices/CodeServices.swift) - Piston API code execution
- [Services/ChatServices/CanvasServices.swift](AI_HLY/Services/ChatServices/CanvasServices.swift) - Canvas creation and management
- [Services/ChatServices/TextToSpeech.swift](AI_HLY/Services/ChatServices/TextToSpeech.swift) - System TTS + API integration
- [Services/ChatServices/FileContentExtraction.swift](AI_HLY/Services/ChatServices/FileContentExtraction.swift) - Document parsing (PDF, Office, Markdown)

**Data Models (SwiftData):**
All models in [Model/](AI_HLY/Model/) directory support CloudKit sync:
- [ChatRecords.swift](AI_HLY/Model/ChatRecords.swift) - Conversation metadata
- [ChatMessages.swift](AI_HLY/Model/ChatMessages.swift) - Individual messages
- [AllModels.swift](AI_HLY/Model/AllModels.swift) - AI model definitions
- [APIKeys.swift](AI_HLY/Model/APIKeys.swift) - Encrypted API credentials
- [KnowledgeRecords.swift](AI_HLY/Model/KnowledgeRecords.swift) - Knowledge base metadata
- [KnowledgeChunk.swift](AI_HLY/Model/KnowledgeChunk.swift) - Vectorized knowledge chunks
- [MemoryArchive.swift](AI_HLY/Model/MemoryArchive.swift) - Long-term memory storage
- [PromptRepo.swift](AI_HLY/Model/PromptRepo.swift) - Prompt templates

**UI Components:**
- [Views/Components/ChatViewComponents.swift](AI_HLY/Views/Components/ChatViewComponents.swift) (~226KB) - Chat UI elements
- [Views/Components/APISettingView.swift](AI_HLY/Views/Components/APISettingView.swift) - API key configuration UI
- [Views/Components/QuickToolsView.swift](AI_HLY/Views/Components/QuickToolsView.swift) - Tool shortcuts UI

**Resource Files:**
- [Resource/Localizable.xcstrings](AI_HLY/Resource/Localizable.xcstrings) (~130KB) - Multi-language translations
- [Resource/UpdateNotes.json](AI_HLY/Resource/UpdateNotes.json) - Version history
- [Resource/Refinement.json](AI_HLY/Resource/Refinement.json) - Response refinement prompts

## Key Architectural Patterns

### 1. Streaming API Pattern
All AI provider interactions use async/await streaming via URLSession:
```swift
// In APIManager.swift
struct StreamData {
    var content: String
    var reasoning: String
    var toolContent: [(name: String, input: String, result: String)]
    var images: [UIImage]
    var audio: Data?
    // ... 20+ more response types
}
```

### 2. Tool System Architecture
- Tools are registered in `ChatTools.swift` with bilingual metadata
- Each tool has a corresponding service implementation in `Services/ChatServices/`
- `APIManager` orchestrates tool execution based on AI provider responses
- Tools are dynamically enabled/disabled via settings

### 3. SwiftData + CloudKit Integration
- All `@Model` classes automatically sync via CloudKit with `.automatic` configuration
- ModelContainer initialized in `AppDataManager` singleton
- Cascade delete relationships maintain data integrity
- No manual sync code required - SwiftData handles everything

### 4. Multi-Provider AI Support
The app supports 20+ AI providers with a unified abstraction:
- Provider-specific endpoints configured in `APIManager`
- Model capabilities tracked in `AllModels` (multimodal, reasoning, tool use, etc.)
- Provider logos stored in `Assets.xcassets`
- Automatic format conversion for different API schemas

### 5. RAG (Retrieval-Augmented Generation)
Knowledge base workflow:
1. Document upload → `FileContentExtraction.swift` parses content
2. Content chunked into semantic segments → `KnowledgeChunk` models
3. Each chunk vectorized (1024-dimensional embeddings)
4. Query → Similarity search in `KnowledgeAPI.swift`
5. Top-K chunks injected into conversation context

### 6. Deep Linking
- Vision tab deep links and the `AI-Hanlin://` scheme were removed along with the vision flow, so no `onOpenURL` handler remains

## Development Guidelines

### Adding a New AI Provider
1. Add provider metadata to `AllModels.swift` preload data
2. Update `APIManager.swift` with provider-specific endpoint and request format
3. Add provider logo to `Assets.xcassets`
4. Test streaming response handling

### Adding a New Tool
1. Define tool metadata in `ChatTools.swift`:
   - Tool name, description (Chinese + English)
   - Input schema (parameters)
   - Settings requirements
2. Implement tool logic in new service file under `Services/ChatServices/`
3. Register tool execution handler in `APIManager.swift`
4. Add UI configuration in `SettingsView.swift` if needed
5. Update `Localizable.xcstrings` for any new strings

### Adding a New Data Model
1. Create `@Model` class in `Model/` directory
2. Define properties and relationships
3. Add to `AppDataManager.modelContainer` configuration in `AI_HLY.swift`
4. Implement preload logic in `Services/DataServices/PreLoad.swift` if needed
5. Create corresponding UI views in `Views/Components/`

### Modifying Large Files
**Important:** `ChatView.swift` (179KB) and `APIManager.swift` (251KB) are monolithic files handling complex real-time interactions. When modifying:
- Search for specific functions/sections rather than reading entire file
- Test streaming behavior thoroughly after changes
- Be cautious with state management in SwiftUI views
- Verify CloudKit sync still works after model changes

### Working with Localization
- All user-facing strings should be in `Localizable.xcstrings`
- Use bilingual descriptions for tool metadata (Chinese first, then English)
- Tool descriptions automatically select language based on system locale

### Security Considerations
- API keys stored encrypted in `APIKeys` model
- Never commit `Config.xcconfig` with real API keys (use template)
- Use `Config.xcconfig.template` as reference
- Validate tool inputs to prevent injection attacks
- Sanitize web content before display

## Common Tasks

### Debugging Streaming Issues
1. Check `APIManager.swift` for provider-specific response parsing
2. Verify `StreamData` struct is properly updated
3. Test with different models/providers to isolate issue
4. Check network logs in Console app for raw API responses

### Updating Model Capabilities
1. Modify model definitions in `AllModels.swift` preload section
2. Update UI filters in `ModelsView.swift`
3. Test capability detection in model selection flows

### Adding Dependency
1. Use Swift Package Manager in Xcode: File → Add Package Dependency
2. Update documentation if adding major framework
3. Test build on clean environment

## Performance Notes

- **Large file sizes:** Some views (ChatView 179KB) contain significant logic; consider refactoring into smaller components if performance degrades
- **Streaming optimization:** StreamData struct consolidates 20+ response types for efficient updates
- **Memory management:** `SystemOptimizer.swift` handles device capability detection
- **CloudKit sync:** Background sync minimizes UI impact; check network availability before large operations

## Additional Resources

- Main repository documentation: [README.md](README.md)
- AI agents documentation: [AGENTS.md](AGENTS.md)
- MIT License: [LICENSE](LICENSE)
- Version history: [Resource/UpdateNotes.json](AI_HLY/Resource/UpdateNotes.json)
