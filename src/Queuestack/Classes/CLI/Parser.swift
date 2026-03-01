//
//  Parser.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import Foundation

/// Parses YAML frontmatter and CLI output
struct Parser {
    struct Error: LocalizedError {
        let message: String
        var errorDescription: String? {
            self.message
        }
    }

    // MARK: - Frontmatter Parsing

    struct ParsedItem {
        let id: String
        let title: String
        let author: String
        let createdAt: Date
        let status: Item.Status
        let labels: [String]
        let attachments: [String]
        let body: String
    }

    /// Parse a markdown file with YAML frontmatter
    func parseMarkdownFile(content: String, filePath: URL) throws -> ParsedItem {
        let components = content.components(separatedBy: "---")

        guard components.count >= 3 else {
            throw Error(message: "Invalid frontmatter in \(filePath.lastPathComponent)")
        }

        // First component is empty (before first ---)
        // Second component is the YAML frontmatter
        // Third+ components are the body (joined back with ---)
        let yamlContent = components[1]
        let bodyContent = components.dropFirst(2).joined(separator: "---")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let frontmatter = try self.parseYAML(yamlContent)

        guard
            let id = frontmatter["id"] as? String,
            let title = frontmatter["title"] as? String else
        {
            throw Error(message: "Invalid frontmatter in \(filePath.lastPathComponent)")
        }

        let author = frontmatter["author"] as? String ?? "Unknown"
        let statusString = frontmatter["status"] as? String ?? "open"
        let status = Item.Status(rawValue: statusString) ?? .open
        let labels = frontmatter["labels"] as? [String] ?? []
        let attachments = frontmatter["attachments"] as? [String] ?? []

        var createdAt = Date()
        if let dateString = frontmatter["created_at"] as? String {
            createdAt = self.parseDate(dateString) ?? Date()
        }

        return ParsedItem(
            id: id,
            title: title,
            author: author,
            createdAt: createdAt,
            status: status,
            labels: labels,
            attachments: attachments,
            body: bodyContent
        )
    }

    /// Extract category from file path (subdirectory name under queuestack/)
    func extractCategory(from filePath: URL, project: Project) -> String? {
        let relativePath = filePath.path.replacingOccurrences(of: project.stackURL.path + "/", with: "")
        let components = relativePath.components(separatedBy: "/")

        // If there's more than one component, the first is the category
        // (unless it's .archive or .templates)
        if components.count > 1 {
            let category = components[0]
            if category != project.archiveDir, category != project.templateDir {
                return category
            }
        }

        return nil
    }

    // MARK: - Simple YAML Parser

    private func parseYAML(_ yaml: String) throws -> [String: Any] {
        var result: [String: Any] = [:]
        var currentKey: String?
        var inArray = false
        var arrayValues: [String] = []

        for line in yaml.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            // Array item (- value)
            if trimmed.hasPrefix("- ") {
                let valueRaw = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                let value = valueRaw.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                arrayValues.append(value)
                inArray = true
                continue
            }

            // If we were collecting array values and hit a new key, save the array
            if inArray, let key = currentKey {
                result[key] = arrayValues
                arrayValues = []
                inArray = false
            }

            // Key: value pair
            if let colonIndex = trimmed.firstIndex(of: ":") {
                let key = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let valueRaw = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)

                currentKey = key

                // Empty value means array follows
                if valueRaw.isEmpty {
                    continue
                }

                // Remove quotes from value
                let value = valueRaw.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                result[key] = value
            }
        }

        // Handle trailing array
        if inArray, let key = currentKey {
            result[key] = arrayValues
        }

        return result
    }

    // MARK: - Date Parsing

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            return date
        }

        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }
}
