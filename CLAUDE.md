# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- **Build**: `swift build` (debug) or `swift build -c release`
- **Lint/Check**: `make check`
- **Format**: `make format`
- **Run/Relaunch app**: `./Scripts/compile_and_run.sh` (builds, packages, relaunches, and verifies running). Add `--wait` if another instance is compiling.
- **Manual relaunch command**: `pkill -x CodexBar || pkill -f CodexBar.app || true; open -n CodexBar.app`
- **Run all tests (sharded)**: `make test`
- **Run specific tests**: `swift test --filter <TestName>`
- **Run TTY tests**: `swift test --filter TTYIntegrationTests`
- **Run Live Account tests**: `LIVE_TEST=1 swift test --filter LiveAccountTests`

## High-Level Architecture & Structure

- `Sources/CodexBar`: Swift 6 AppKit/SwiftUI menu bar app (views, menu controllers, app delegate, settings pane, custom rendering).
- `Sources/CodexBarCore`: Target containing usage parsing logic, credentials/storage managers, status/refresh loop, and the core config framework.
- `Sources/CodexBarCLI`: Terminal-based `codexbar` utility.
- `Sources/CodexBarClaudeWatchdog` & `CodexBarClaudeWebProbe`: Helper helper daemons for Claude CLI and browser integration.
- `Sources/CodexBarWidget`: WidgetKit extensions.
- `Tests/CodexBarTests`: Test suite covering usage parsing, status probes, and widget layouts.

## Development & Code Guidelines

- **Swift Concurrency**: Do not use sibling `async let` tasks when one is required and another is optional. Prefer sequential awaits or `withThrowingTaskGroup` to explicitly handle or ignore optional failures.
- **SwiftUI & Observation**: Favor modern `@Observable` models with `@State` ownership and `@Bindable` in views. Avoid legacy `ObservableObject`, `@ObservedObject`, or `@StateObject` patterns.
- **Keychain and UI Prompts**: Live provider probes, browser-cookie imports, and Keychain reads must not be run by default in tests. Use stubs, test stores, or `KeychainNoUIQuery` to prevent blocking macOS Keychain permission alerts.
- **Adhoc Signing Keychain Reset**: Since ad-hoc code signatures change on every compilation, developers can run `./Scripts/compile_and_run.sh --clear-adhoc-keychain` to reset CodexBar-owned keychain items if they get stuck.
- **CI / AppKit Menu Testing**: AppKit status bar menu tests are brittle in headless CI. Test via data-driven models/states (like `MenuDescriptor`, `ProvidersPane`, etc.) rather than constructing live `NSStatusBar` or `NSMenu` objects.
- **Style Rules**: Keep `self` references explicit. Lines should be styled using `swiftformat` (4-space indents, 120-character limit). Run `make check` before completion to ensure no lint/format errors.
- **Provider Siloing**: Keep provider data strictly isolated. Never display identity or plan fields of one provider using source fields from another.
