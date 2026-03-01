//
//  FileWriter.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import Foundation

/// Writes body content directly to markdown files (preserves frontmatter)
struct FileWriter {
    struct Error: LocalizedError {
        let message: String
        var errorDescription: String? {
            self.message
        }
    }

    /// Update the body of an item file, preserving frontmatter
    func updateBody(of item: Item, newBody: String) throws {
        let content = try String(contentsOf: item.filePath, encoding: .utf8)

        // Split at frontmatter delimiters
        let components = content.components(separatedBy: CLIConstants.FileConventions.frontmatterDelimiter)
        guard components.count >= 3 else {
            throw Error(message: "Invalid frontmatter in \(item.filePath.lastPathComponent)")
        }

        // Reconstruct: empty + frontmatter + new body
        let frontmatter = components[1]
        let delimiter = CLIConstants.FileConventions.frontmatterDelimiter
        let newContent = "\(delimiter)\(frontmatter)\(delimiter)\n\n\(newBody)\n"

        try newContent.write(to: item.filePath, atomically: true, encoding: .utf8)
    }

    /// Update multiple fields in the frontmatter and body
    func updateItem(at path: URL, title: String?, labels: [String]?, body: String?) throws {
        let content = try String(contentsOf: path, encoding: .utf8)

        let components = content.components(separatedBy: CLIConstants.FileConventions.frontmatterDelimiter)
        guard components.count >= 3 else {
            throw Error(message: "Invalid frontmatter in \(path.lastPathComponent)")
        }

        var frontmatterLines = components[1].components(separatedBy: .newlines)
        let existingBody = components.dropFirst(2).joined(separator: "---")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Update title if provided
        if let title {
            for i in frontmatterLines.indices {
                if frontmatterLines[i].trimmingCharacters(in: .whitespaces).hasPrefix("title:") {
                    frontmatterLines[i] = "title: \(title)"
                    break
                }
            }
        }

        // Update labels if provided
        if let labels {
            // Remove existing labels section
            var inLabels = false
            frontmatterLines = frontmatterLines.filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("labels:") {
                    inLabels = true
                    return false
                }
                if inLabels, trimmed.hasPrefix("- ") {
                    return false
                }
                if inLabels, !trimmed.isEmpty, !trimmed.hasPrefix("- ") {
                    inLabels = false
                }
                return true
            }

            // Add new labels section before status line
            if !labels.isEmpty {
                if
                    let statusIndex = frontmatterLines
                        .firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("status:") })
                {
                    var labelsSection = ["labels:"]
                    labelsSection += labels.map { "- \($0)" }
                    frontmatterLines.insert(contentsOf: labelsSection, at: statusIndex)
                }
            }
        }

        let finalBody = body ?? existingBody
        let newFrontmatter = frontmatterLines.joined(separator: "\n")
        let delimiter = CLIConstants.FileConventions.frontmatterDelimiter
        let newContent = "\(delimiter)\(newFrontmatter)\(delimiter)\n\n\(finalBody)\n"

        try newContent.write(to: path, atomically: true, encoding: .utf8)
    }
}
