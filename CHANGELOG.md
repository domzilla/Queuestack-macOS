# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Markdown syntax highlighting in the item body editor (dark mode only, colors matched to Nova editor)

### Fixed
- Fix scroll flicker when typing space in the body editor caused by deferred text layout recalculation after markdown highlighting font-attribute changes; force synchronous layout via `ensureLayout` before propagating text to SwiftUI
- Batch markdown highlighter attribute changes in `beginEditing`/`endEditing` to reduce redundant layout passes

## [1.0.1] - 2026-02-20

### Fixed
- Empty categories not shown in New Item sheet; categories are now fetched from CLI (`qs list --categories`) and merged with item-derived counts so directory-only categories appear
- Empty labels not shown in New Item sheet; labels are now fetched from CLI (`qs list --labels`) and merged with item-derived counts so unused labels appear

## [1.0.0] - 2026-02-10

### Refactored
- Rename `SettingsManager` to `ProjectManager` and remove unused `cliBinaryPath` setting (use `CLIConstants.defaultBinaryPath` directly)
- Extract `listItems(flag:in:)` helper in `Service` to eliminate duplication across list methods
- Extract `scanItems(in:project:excluding:)` helper in `FileReader` to eliminate duplication across scan methods
- Extract `runUpdate(item:additionalArgs:in:)` helper in `Service` for update operations
- Create `UnsavedChangesAlert` view modifier to eliminate duplicated alert code in `ItemDetailView` and `ProjectSidebar`
- Create `LabelToggleButton` component to eliminate duplicated label toggle UI in sheets
- Create `CategoryPicker` component to eliminate duplicated category selection UI in sheets
- Move 1-based index conversion for attachments into `Service` layer (fixes leaky abstraction)
- Add `isNoMatchesResult` property to `CLIRunner.Result` to encapsulate CLI error handling (fixes leaky abstraction)
- Change `Item.isTemplate` from computed property to stored property set by `FileReader` (fixes model coupling to file path convention)
- Extract CLI constants to `Constants/CLIConstants.swift` with command-based structure mirroring the CLI hierarchy:
  - `CLIConstants.List`, `CLIConstants.Search`, `CLIConstants.New`, `CLIConstants.Update`, etc.
  - Each command has its own `Flag` enum showing which flags are valid for that command
  - `CLIConstants.FileConventions` for CLI-defined file conventions (extensions, delimiters, directory names)
- Extract macOS key codes to `Constants/KeyCodes.swift`
- Add local cell/column identifier constants to `SidebarOutlineView` and `AttachmentTableView`
- Extract `AttachmentNSTableView` from `AttachmentTableView.swift` into separate file
- Extract `AttachmentCellView` from `AttachmentTableView.swift` into separate file
- Extract `AttachmentRowView` from `AttachmentTableView.swift` into separate file
- Extract `ProjectAdditionError` from `SettingsManager.swift` to `Models/Errors/`
- Extract `FocusedWindowStateKey` from `QueuestackApp.swift` to dedicated file
- Extract `Notification.Name` extensions to `Constants/NotificationNames.swift`
- Extract `NSPasteboard.PasteboardType` extension to `Constants/PasteboardTypes.swift`

### Added
- "Check for Updates…" menu item in app menu via Sparkle integration
- URL format validation for attachment URLs (accepts only http/https schemes)
- Duplicate project detection when adding projects via file picker
- Unified project validation with error feedback for both file picker and drag & drop
- Quick Look preview for attachments: press Space bar to toggle; arrow keys navigate while panel is open
- Attachment support in item detail view with URL and file attachment management
- Global search scope filter (Open/Closed/Template) with segmented control below search field

### Fixed
- Item rename showing spurious file-not-found error; CLI output parsing now correctly extracts path from "Updated item:" message
- Default window size too small on first launch; set to 1100x700 with proper sidebar column width
- Quick Look panel now resizes properly when navigating between attachments of different sizes
- Global search now triggers on typing with 300ms debounce instead of requiring Enter key
- Search results persist in sidebar while query text exists (clearing field returns to project outline)
- Selecting search results within the same project now works correctly

### Changed
- Group renaming now uses inline editing instead of a popup dialog
- Disable window tabbing; app uses separate windows instead of tabs
- Quick Look preview now shows single item at a time (Finder-like behavior) instead of multi-item panel with navigation arrows
- Attachment list refactored to NSTableView for native keyboard navigation and Quick Look integration
- Item list header reordered: search field on top, filter segmented control below
- Global search now uses native `.searchable` modifier with sidebar placement; results display inline in sidebar
- Project sidebar now uses NSOutlineView for native drag & drop support (reorder, move between groups, drop folders from Finder)
- Attachment list now supports Finder-like multi-selection (Cmd+Click toggle, Shift+Click range)
- Single click selects attachment, double-click opens it, click empty space deselects
- Context menu on attachments: Show in Finder, Copy File Path/URL, Delete
- Cmd+Backspace deletes selected attachments
- File picker now supports multiple selection
- Drag and drop files onto attachments section to add them
- Single-item mutations use incremental refresh instead of full list reload
- Per-item serial refresh queues using AsyncStream prevent race conditions between FSEvents and manual refreshes
- Stale refresh detection skips redundant refreshes when file modification date unchanged
- Updated attachment path resolution for qs 0.5.0 (attachments now in `{item-stem}.attachments/` directory)
- Item deletion now also trashes the attachments directory if it exists
- Selection uses native macOS selection colors
- Removed inline trash button, document icon, and focus ring from attachment rows
- Split state architecture: AppServices (shared) and WindowState (per-window) for multi-window support
- Body editing state managed at WindowState level for cleaner architecture
- Body saves on Cmd+S, item switch, or view disappear instead of auto-save while typing
- Show unsaved indicator (orange dot) with discard button when body has pending changes
- Confirmation dialog (Save/Discard/Cancel) when switching items or projects with unsaved changes
- Always reload project items on selection to ensure fresh data from external changes
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
