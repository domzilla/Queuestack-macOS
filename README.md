# Queuestack for Mac

A native macOS app for [queuestack](https://github.com/domzilla/queuestack) — the minimal, plain-text task and issue tracker.

Brings all your queuestack projects together in one place. Browse, search, create, and edit items across projects without touching the terminal. Your items stay as Markdown files on disk, readable and editable by any tool.

## Requirements

- **macOS 26.2** or later
- **[queuestack CLI](https://github.com/domzilla/queuestack)** must be installed:

```bash
brew tap domzilla/tap
brew install queuestack
```

The app calls the `qs` binary for every operation (list, create, update, search, close, reopen). Without it, nothing works.

## Features

- **All projects in one place** — organize multiple queuestack projects into nested groups
- **Filter and search** — filter by status (Open / Closed / Templates), search across all projects
- **Edit in place** — edit item body, labels, categories, and attachments directly
- **Real-time sync** — picks up external changes (CLI, editor, other apps) instantly
- **Templates** — create and instantiate item templates
- **Attachments** — attach files or URLs, preview with Quick Look
- **Multi-window** — open multiple windows, each with independent state
- **Auto-updates** — built-in update mechanism via Sparkle

## How It Works

The app is a thin GUI layer over the `qs` CLI. It does **not** reimplement any business logic:

| Operation | How |
|-----------|-----|
| List, search, create, update, close, reopen | Calls `qs` commands |
| Edit item body | Writes directly to the Markdown file |
| Detect external changes | Watches the project directory via FSEvents |

This means your data is always plain Markdown — the same files the CLI, `grep`, `git`, and your editor see.

## License

MIT
