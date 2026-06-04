# Tick

A native, local-first macOS task manager. SwiftUI + SwiftData, MVVM, glassy aesthetic.

## Status

Phase 3 scaffold. Buildable hello-world shell (sidebar + Today/Upcoming smart views + task model + notification permission flow). Features land iteratively after this.

## Requirements

- macOS 15 (Sequoia) or later
- Xcode 16+ (full Xcode, not just Command Line Tools)
- [XcodeGen](https://github.com/yonsei/XcodeGen) to generate the `.xcodeproj` from `project.yml`

## First-time setup

1. Install full **Xcode** from the Mac App Store, then activate the toolchain:
   ```sh
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -license accept
   ```
2. Install Homebrew (if needed) and XcodeGen:
   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   brew install xcodegen
   ```
3. Generate and open the project:
   ```sh
   xcodegen generate
   open Tick.xcodeproj
   ```

> The `.xcodeproj` is **not** committed — it's regenerated from `project.yml`. Whenever you add/remove files or change build settings, edit `project.yml` and re-run `xcodegen generate`.

## Architecture

- **Models/** — SwiftData `@Model` entities (`Project`, `TaskItem`, `Reminder`, `Priority`). CloudKit-compatible (no unique constraints, defaulted scalars, optional inverse relationships). Sync is OFF in V1.
- **ViewModels/** — `@Observable` view models: actions, validation, transient edit state. Lists are read in views via `@Query`.
- **Views/** — SwiftUI. `NavigationSplitView` shell, sidebar, shared task list, smart views.
- **Services/** — `NotificationManager` (UserNotifications) and `TaskScheduler` (complete/snooze/reschedule domain ops).
- **Shared/** — theme tokens and date helpers.

## Key decisions

- **SwiftData** as source of truth; `@Query` in views, thin `@Observable` view models.
- **CloudKit-compatible model from day 1**, sync disabled in V1 (flip a flag + add entitlements to enable).
- **App Sandbox + Hardened Runtime** on (App Store door kept open).
- **Swift 5 language mode** now; Swift 6 strict-concurrency hardening pass later.
