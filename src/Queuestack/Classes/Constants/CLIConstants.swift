//
//  CLIConstants.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 04/02/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import Foundation

/// Constants for the queuestack CLI tool (`qs`)
/// Structure mirrors the CLI command hierarchy
nonisolated(unsafe) enum CLIConstants {
    /// Default path to the qs binary
    static let defaultBinaryPath = "/opt/homebrew/bin/qs"

    // MARK: - File Conventions

    /// File and directory conventions defined by the CLI
    enum FileConventions {
        /// Markdown file extension (without dot)
        static let markdownExtension = "md"

        /// Markdown file extension (with dot)
        static let markdownExtensionWithDot = ".md"

        /// YAML frontmatter delimiter
        static let frontmatterDelimiter = "---"

        /// Queuestack project configuration file name
        static let configFileName = ".queuestack"

        /// Attachment directory suffix (appended to item stem)
        static let attachmentDirectorySuffix = ".attachments"

        /// Default directory names for queuestack projects
        enum DefaultDirectories {
            static let stack = "queuestack"
            static let archive = ".archive"
            static let templates = ".templates"
        }

        /// URL scheme prefixes for URL attachments
        enum URLScheme {
            static let http = "http://"
            static let https = "https://"
        }
    }

    // MARK: - Commands

    /// `qs list` command
    enum List {
        static let command = "list"

        enum Flag {
            static let open = "--open"
            static let closed = "--closed"
            static let templates = "--templates"
            static let labels = "--labels"
            static let categories = "--categories"
            static let noInteractive = "--no-interactive"
        }
    }

    /// `qs search` command
    enum Search {
        static let command = "search"

        enum Flag {
            static let fullText = "--full-text"
            static let closed = "--closed"
            static let noInteractive = "--no-interactive"
        }

        enum ExitCode {
            /// Returned when no matches found
            static let noMatches: Int32 = 1
        }
    }

    /// `qs new` command
    enum New {
        static let command = "new"

        enum Flag {
            static let label = "--label"
            static let category = "--category"
            static let asTemplate = "--as-template"
            static let noInteractive = "--no-interactive"
        }
    }

    /// `qs update` command
    enum Update {
        static let command = "update"

        enum Flag {
            static let id = "--id"
            static let title = "--title"
            static let label = "--label"
            static let removeLabel = "--remove-label"
            static let category = "--category"
            static let removeCategory = "--remove-category"
        }
    }

    /// `qs close` command
    enum Close {
        static let command = "close"

        enum Flag {
            static let id = "--id"
        }
    }

    /// `qs reopen` command
    enum Reopen {
        static let command = "reopen"

        enum Flag {
            static let id = "--id"
        }
    }

    /// `qs attachments` command
    enum Attachments {
        static let command = "attachments"

        /// `qs attachments add` subcommand
        enum Add {
            static let subcommand = "add"

            enum Flag {
                static let id = "--id"
            }
        }

        /// `qs attachments remove` subcommand
        enum Remove {
            static let subcommand = "remove"

            enum Flag {
                static let id = "--id"
            }
        }
    }
}
