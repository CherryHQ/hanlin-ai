# Repository Guidelines

## Project Structure & Module Organization
App sources sit in `AI_HLY/`, with `AI_HLY.swift` wiring the SwiftUI scene and model container. Domain models live in `AI_HLY/Model/`, while service logic stays under `AI_HLY/Services/` (for example, `Services/APIServices` and `Services/VisionServices`). UI flows belong in `AI_HLY/Views/` and its `Views/Components` subfolder, with localized variants alongside them in `Base.lproj` and `mul.lproj`. Version configuration JSON (such as `Resource/memoryConfig.json`) in Git, and keep secrets out of source by copying `Config.xcconfig.template` to `Config.xcconfig` locally.

## Build, Test, and Development Commands
Kick off development with `open AI_HLY.xcodeproj` to resolve packages and run previews. Scriptable builds use `xcodebuild -project AI_HLY.xcodeproj -scheme AI_HLY -destination 'platform=iOS Simulator,name=iPhone 15' build`. When tests exist, execute `xcodebuild -project AI_HLY.xcodeproj -scheme AI_HLY -destination 'platform=iOS Simulator,name=iPhone 15' test` before submitting. Re-sync Swift Package Manager dependencies with `xcodebuild -resolvePackageDependencies` after edits.

## Coding Style & Naming Conventions
Follow Swift defaults: four-space indentation, `PascalCase` for types and file names, and `lowerCamelCase` for properties, bindings, and async tasks. Collect SwiftUI state wrappers at the top of each struct and lean on small computed properties instead of sprawling view builders. Preserve the existing bilingual comments, keep localized copy in `.xcstrings`, and mirror the `Services/<Domain>Services` folder split when adding new integrations.

## Testing Guidelines
The project currently ships without automated tests; add `AI_HLYTests` or `AI_HLYUITests` targets when contributing features. Co-locate fixtures under a `Tests/Resources` folder and name XCTest cases after the component under test (e.g. `ChatViewTests`). Document manual verification steps for SwiftUI previews or simulator flows, and share simulator logs when diagnosing CloudKit or SwiftData behaviour.

## Commit & Pull Request Guidelines
Follow the Conventional Commits pattern in history (`feat:`, `fix:`, `chore:`) and scope messages to a single concern. Before opening a pull request, run the build command above and note the result in the description. Reference affected views or services, link the tracking issue, and include screenshots or recordings for UI changes. Call out any new API keys or entitlement adjustments in the PR body.

## Security & Configuration Tips
Never commit personal API keys or signing profiles; store them in your local `Config.xcconfig` and enter them through the in-app Settings screen. When adding new providers, document the required key names in `Model/APIKeys.swift` and update onboarding copy if needed. Review `AI_HLY.entitlements` and `AI-HLY-Info.plist` whenever capabilities change, and flag reviewers if a migration step or data reset is required.
