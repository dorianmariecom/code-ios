# Repository Guidelines

## Project Structure & Architecture

- `App/` contains the full app target: app lifecycle (`AppDelegate.swift`, `SceneDelegate.swift`), environment config (`AppConfig.swift`), Hotwire bridge components, and UI/navigation glue.
- `App/Assets.xcassets` stores shared assets plus per-environment app icons: `AppIcon-test`, `AppIcon-localhost`, `AppIcon-development`, `AppIcon-staging`, and `AppIcon-production`.
- `App/Base.lproj` contains storyboard resources such as `Main.storyboard` and `LaunchScreen.storyboard`.
- `App/Config*.xcconfig` selects environment-specific build settings. There is also a root `ConfigDevelopment.xcconfig`.
- `code.xcodeproj` defines a single iOS app target, `code`, with shared schemes for `test`, `localhost`, `development`, `staging`, and `production`.
- `code.entitlements` contains app capabilities; change it only when capabilities actually change.
- `fastlane/` contains release automation for TestFlight and App Store delivery.
- `builds/` contains generated archives from fastlane and should be treated as build output, not hand-edited source.

## Runtime Model

- This app is a Hotwire Native shell around `codedorian.com` environments, not a large native screen-by-screen app.
- `AppConfig.swift` switches the base domain by compile flag:
  - `test` and `localhost` -> `http://localhost:3000`
  - `development` -> `https://dev.codedorian.com`
  - `staging` -> `https://staging.codedorian.com`
  - `production` -> `https://codedorian.com`
- `AppDelegate.swift` registers Hotwire bridge components and route decision handlers.
- `SceneDelegate.swift` owns the `HotwireTabBarController`, deep-link handling, notification routing, and persisted tab/scroll restoration.
- Components such as `TabBarComponent`, `SearchComponent`, `RefreshComponent`, `ShareComponent`, and `NotificationTokenComponent` are bridge points between web content and native iOS behavior.
- When changing navigation, deep links, push notifications, or tab state, inspect `SceneDelegate.swift`, `NotificationRouter.swift`, and the relevant bridge component together. Behavior is cross-cutting.

## Build, Run, and Release Commands

- Open the project in Xcode with `open code.xcodeproj`.
- Preferred local builds use the shared environment schemes:
  - `xcodebuild -project code.xcodeproj -scheme localhost -configuration localhost build`
  - `xcodebuild -project code.xcodeproj -scheme development -configuration development build`
  - `xcodebuild -project code.xcodeproj -scheme staging -configuration staging build`
  - `xcodebuild -project code.xcodeproj -scheme production -configuration production build`
- Fastlane lanes:
  - `bundle exec fastlane ios test`
  - `bundle exec fastlane ios localhost`
  - `bundle exec fastlane ios development`
  - `bundle exec fastlane ios staging`
  - `bundle exec fastlane ios production`
- Fastlane requires App Store Connect credentials in `fastlane/.env`:
  - `ASC_KEY_ID`
  - `ASC_ISSUER_ID`
  - `ASC_KEY_CONTENT`
- `fastlane ios production` uploads to both TestFlight and App Store metadata; the other lanes upload TestFlight builds only.

## Coding Style & Implementation Conventions

- Follow standard Swift style with 4-space indentation and nearby code conventions.
- Use `PascalCase` for types and `camelCase` for methods, properties, and locals.
- Name files after the primary type or responsibility, for example `NotificationRouter.swift` or `TabBarComponent.swift`.
- Keep bridge components focused on one native capability and align their `name` with the event/component contract used by the web app.
- Prefer extending the current Hotwire-driven architecture instead of introducing parallel native navigation stacks or duplicate state containers.
- Preserve the existing environment-flag pattern (`CODE_ENV_TEST`, `CODE_ENV_LOCALHOST`, `CODE_ENV_DEVELOPMENT`, `CODE_ENV_STAGING`, `CODE_ENV_PRODUCTION`) when adding environment-specific behavior.

## Validation Expectations

- There are currently no unit test or UI test targets in the project.
- Validate changes with a targeted `xcodebuild` invocation for the affected environment, or by running the relevant shared scheme in Xcode.
- For release automation changes, verify the affected fastlane lane rather than describing hypothetical behavior.
- For deep links, notifications, tabs, or state restoration changes, include a short manual verification note in the PR.

## Commit & Pull Request Guidelines

- Keep commits short, direct, and single-purpose. Existing history uses messages like `bump to 3.6`, `fix 429 too many requests from tab bar`, and `try to fix fastlane`.
- Do not mix release/version bumps with unrelated behavior changes unless the repo is explicitly being cut for release.
- PRs should include:
  - a brief summary of the user-visible or release impact
  - the environment or scheme used for verification
  - screenshots or screen recordings for UI changes
  - manual test notes for navigation, notification, or tab behavior when relevant

## Agent-Specific Notes

- Check `git status` before editing. This repo often has generated or local Xcode changes in the worktree; do not revert unrelated user edits.
- Be careful with changes to:
  - `code.xcodeproj/project.pbxproj`
  - `code.xcodeproj/xcshareddata/xcschemes/*.xcscheme`
  - `fastlane/Fastfile`
- Those files affect release and environment behavior across the whole app.
- Do not treat `fastlane ios test` as a unit-test command. It produces and uploads a TestFlight build for the `test` environment.
