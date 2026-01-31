# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Attachment support in item detail view with URL and file attachment management

### Changed
- Body editing state managed at AppState level for cleaner architecture
- Body saves on Cmd+S, item switch, or view disappear instead of auto-save while typing
- Show unsaved indicator (orange dot) with discard button when body has pending changes
- Confirmation dialog (Save/Discard/Cancel) when switching items with unsaved changes
- Incremental item refresh on file changes instead of full list reload
- Replace colored label badges with plain comma-separated text in item list
- Use SwiftUI Table for item list (native resizable columns, headers, selection)
- Initial implementation of Queuestack macOS app with three-panel UI
- Project sidebar with nested groups for organizing queuestack projects
- Item list view with filtering (Open/Closed/Templates) and local search
- Item detail view with editable markdown body
- CLI integration layer wrapping the `qs` command-line tool
- FSEvents-based file watching for real-time updates
- New Item and Edit Item sheets with label and category management
- Global search across all projects via toolbar
- File > New Template menu command
