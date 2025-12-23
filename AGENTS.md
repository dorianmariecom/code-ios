# Repository Guidelines

## Project Structure & Module Organization
- `App/` holds the Swift app source, UI components, and configuration (`*.swift`, `Info.plist`).
- `App/Assets.xcassets` contains app icons and image assets.
- `App/Base.lproj` contains localization resources.
- `App/Config*.xcconfig` and root `ConfigDevelopment.xcconfig` define build-time settings per environment.
- `code.xcodeproj` is the Xcode project; `code.entitlements` defines entitlements.
- `fastlane/` contains CI/release automation.

## Build, Test, and Development Commands
- `open code.xcodeproj` opens the project in Xcode to build/run locally.
- `bundle exec fastlane ios test` builds and uploads a TestFlight build for the test config.
- `bundle exec fastlane ios development` builds and uploads TestFlight for development.
- `bundle exec fastlane ios staging` and `bundle exec fastlane ios production` target staging/production.

## Coding Style & Naming Conventions
- Swift code uses standard 4-space indentation and Swift API Design Guidelines.
- Types use `PascalCase`; functions/variables use `camelCase`.
- Files are named for their primary type (example: `TabBarComponent.swift`).
- No formatter or linter is configured; keep style consistent with nearby files.

## Testing Guidelines
- No unit/UI test targets are present in the repo; add them under a `*Tests` target if needed.
- Use Xcode’s Test action for local validation once tests exist.
- The `fastlane ios test` lane is for TestFlight builds, not unit tests.

## Commit & Pull Request Guidelines
- Commit messages in history are short and direct (examples: `bump to 2.10`, `try to fix fastlane`).
- Keep commits single-purpose and mention environment or feature when relevant.
- PRs should include a brief description, linked issue (if any), and screenshots for UI changes.
- Note the fastlane lane or Xcode configuration used for verification.

## Configuration Tips
- Choose the correct `Config*.xcconfig` for the target environment.
- Update `code.entitlements` only when capabilities change.
