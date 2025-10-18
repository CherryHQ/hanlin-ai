# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AI翰林院 (AI Hanlin Academy) is a Swift-based iOS application that serves as a comprehensive AI workstation. The app integrates 20+ AI providers including OpenAI, Claude, Qwen, DeepSeek, GLM, and others, providing chat, vision analysis, knowledge management, and specialized tool integration.

**Key Features:**
- Multi-provider AI chat with streaming responses and tool calling
- Vision analysis with camera integration and multi-modal AI models
- RAG-based knowledge management with document parsing
- Integrated tools: web search, maps, weather, calendar, health data, code execution
- Local AI model support via LLM.swift
- SwiftData + CloudKit for data persistence and sync

## Build and Development Commands

### Opening the Project
```bash
# Open the Xcode project from the repository root
open AI_HLY.xcodeproj
```

### Build Commands
- Build using Xcode's standard build system (⌘+B)
- Run on simulator or device (⌘+R)
- Clean build folder: Product → Clean Build Folder (⌘+Shift+K)

### Testing
- No unit tests are currently configured in the project
- Testing is done through manual UI testing on device/simulator

### Common Development Commands
```bash
# Clone the repository
git clone https://github.com/CherryHQ/AI_Hanlin.git
cd AI_HLY

# Open in Xcode
open AI_HLY.xcodeproj
```

### Key Dependencies (Swift Package Manager)
The project uses several external dependencies managed through SPM:
- **LLM.swift** (v1.8.0) - Core LLM integration library
- **CoreXLSX** (v0.14.2) - Excel file processing
- **LaTeXSwiftUI** (v1.5.0) - LaTeX rendering in SwiftUI
- **MarkdownUI** - Markdown rendering support
- **SwiftSoup** - HTML parsing
- **RichTextKit** - Rich text editing capabilities
- **ZIPFoundation** - Archive handling

## Architecture

### Core App Structure

The app follows a tab-based architecture with SwiftData for persistence:

1. **App Entry Point**: `AI_HLY.swift`
   - Sets up SwiftData `ModelContainer` with CloudKit integration
   - Configures all data models and preloads default data
   - Handles deep linking for VisionView

2. **Main Navigation**: `MainTabView.swift`
   - Five-tab structure: Chat List, Vision, Knowledge, Models, Settings
   - Deep link handling for external app integration

3. **Core Views**:
   - `ListView.swift` - Chat conversation management
   - `ChatView.swift` - Individual chat interface with streaming responses
   - `VisionView.swift` - Camera-based OCR and image analysis
   - `KnowledgeListView.swift` - Knowledge base management
   - `ModelsView.swift` - AI model selection and configuration
   - `SettingsView.swift` - App configuration and API key management

### Data Architecture (SwiftData)

All models are defined with `@Model` and support CloudKit sync:

- **Core Chat Models**:
  - `ChatRecords` - Conversation metadata and settings
  - `ChatMessages` - Individual messages with rich content support
  - `MemoryArchive` - Long-term conversation memory

- **Configuration Models**:
  - `AllModels` - AI model definitions with capabilities (multimodal, reasoning, tool use, etc.)
  - `APIKeys` - Encrypted API key storage for various providers
  - `SearchKeys` - Search engine API configurations
  - `ToolKeys` - Tool-specific API keys and settings

- **Knowledge Management**:
  - `KnowledgeRecords` - Knowledge base metadata
  - `KnowledgeChunk` - Chunked knowledge content for RAG

- **User Data**:
  - `UserInfo` - User preferences and settings
  - `PromptRepo` - Custom prompt templates
  - `TranslationDic` - Translation dictionaries

### Service Layer Architecture

Services are organized by functionality in `/Services`:

1. **APIServices**:
   - `APIManager.swift` - Core API communication with streaming support
   - `APIBalance.swift` - API usage tracking and billing
   - `APITest.swift` - API endpoint validation

2. **ChatServices** - Tool ecosystem:
   - `ChatTools.swift` - Tool registration and orchestration
   - `ToolsAPI.swift` - Tool execution framework
   - `WebSearchTool.swift` - Multi-provider web search
   - `WebReadTool.swift` - Web content extraction
   - `MapServices.swift` - Location and mapping integration
   - `WeatherServices.swift` - Weather data integration
   - `CalendarService.swift` - Calendar integration
   - `HealthServices.swift` - HealthKit integration
   - `CodeServices.swift` - Code analysis and execution
   - `CanvasServices.swift` - Drawing and visual tools
   - `TextToSpeech.swift` - Voice synthesis

3. **Specialized Services**:
   - `ModelServices` - Model management and local inference
   - `KnowledgeServices` - RAG implementation and knowledge retrieval
   - `VisionServices` - Image analysis and OCR
   - `DataServices` - Data preloading and system optimization

### Key Architectural Patterns

1. **Streaming Response Handling**:
   - `StreamData` struct defines all possible streaming content types
   - `APIManager` handles async streaming with tool orchestration
   - Real-time UI updates via `@Published` properties

2. **Tool System Architecture**:
   - Tools are registered in `ChatTools.swift` with metadata
   - `ToolsAPI.swift` provides execution framework
   - Tools can return structured data (locations, images, documents, etc.)

3. **Model Capability System**:
   - `AllModels` defines capabilities per model (multimodal, reasoning, tool use)
   - Dynamic UI adaptation based on model capabilities
   - Support for both cloud and local models

4. **Multi-Provider Integration**:
   - Supports 20+ AI providers (OpenAI, Claude, Qwen, DeepSeek, etc.)
   - Unified API abstraction in `APIManager`
   - Provider-specific icon and branding support

5. **Data Persistence**:
   - All models use SwiftData with CloudKit sync
   - App data manager handles preloading and initialization
   - Data preloading occurs in `AppDataManager.preloadDataIfNeeded()`

## Development Workflow

### Adding New AI Models
1. Add model definition in `AllModels.swift` with capabilities
2. Implement API integration in `APIManager.swift`
3. Add provider icon to Assets.xcassets
4. Update `ModelsView.swift` for UI support

### Adding New Tools
1. Implement tool logic in appropriate service file under `ChatServices/`
2. Register tool in `ChatTools.swift` with metadata
3. Add API key configuration if needed in `APIKeys.swift`
4. Update settings UI in `SettingsView.swift`

### Working with SwiftData
- All models support CloudKit sync automatically
- Use `@Query` for reactive data binding
- Preload default data in `AppDataManager.preloadDataIfNeeded()`
- Handle data migrations in model definitions

### UI Component Patterns
- Reusable components are in `/Views/Components/`
- Follow SwiftUI best practices with `@StateObject` and `@ObservedObject`
- Support both light and dark themes
- Extensive use of SF Symbols for icons

## Resource Management

- **Assets**: Extensive icon library for 20+ AI providers with dark mode variants
- **Localization**: Multi-language support via Localizable.xcstrings
- **Configuration Files**: JSON configs for memory system and refinement prompts
- **Launch Screen**: Storyboard-based launch screen with localization

## Important Notes for Development

### Requirements
- iOS 18.0+
- Xcode 15.0+
- Swift 5.9+
- macOS 14.0+ for development

### Deep Linking
- App supports `AI-Hanlin://` URL scheme for external integrations
- Configured in `AI-HLY-Info.plist`
- Handles deep links to VisionView for OCR functionality

### API Key Management
- API keys are stored encrypted using SwiftData
- Multiple provider support requires proper key configuration
- Keys are managed through `APIKeys.swift` model and `SettingsView.swift` UI

### Performance Considerations
- Heavy use of async/await for API calls
- Streaming responses for real-time chat experience
- Local model inference available via LLM.swift for offline usage
- SwiftData with CloudKit for cross-device sync