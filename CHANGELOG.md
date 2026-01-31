# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Replace colored label badges with plain comma-separated text in item list

### Fixed
- Restore column headers (Category, Title, Labels) in item list after Table-to-List migration

### Added
- Resizable column widths in item list (drag between column headers to resize)
- Initial implementation of Queuestack macOS app with three-panel UI
- Project sidebar with nested groups for organizing queuestack projects
- Item list view with filtering (Open/Closed/Templates) and local search
- Item detail view with editable markdown body and auto-save
- CLI integration layer wrapping the `qs` command-line tool
- FSEvents-based file watching for real-time updates
- New Item and Edit Item sheets with label and category management
- Global search across all projects via toolbar
- File > New Template menu command
