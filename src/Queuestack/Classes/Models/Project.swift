//
//  Project.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import Foundation

struct Project: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var path: URL
    var stackDir: String
    var archiveDir: String
    var templateDir: String

    init(
        id: UUID = UUID(),
        name: String,
        path: URL,
        stackDir: String = CLIConstants.FileConventions.DefaultDirectories.stack,
        archiveDir: String = CLIConstants.FileConventions.DefaultDirectories.archive,
        templateDir: String = CLIConstants.FileConventions.DefaultDirectories.templates
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.stackDir = stackDir
        self.archiveDir = archiveDir
        self.templateDir = templateDir
    }

    var stackURL: URL {
        self.path.appendingPathComponent(self.stackDir)
    }

    var archiveURL: URL {
        self.stackURL.appendingPathComponent(self.archiveDir)
    }

    var templateURL: URL {
        self.stackURL.appendingPathComponent(self.templateDir)
    }

    /// Validates that this folder contains a .queuestack file
    var isValid: Bool {
        let configPath = self.path.appendingPathComponent(CLIConstants.FileConventions.configFileName)
        return FileManager.default.fileExists(atPath: configPath.path)
    }
}

extension Project {
    struct Error: LocalizedError {
        let message: String
        var errorDescription: String? {
            self.message
        }
    }

    /// Creates a Project from a folder URL, reading config if present
    static func from(url: URL) throws -> Project {
        let configPath = url.appendingPathComponent(CLIConstants.FileConventions.configFileName)
        guard FileManager.default.fileExists(atPath: configPath.path) else {
            throw Error(message: "Not a queuestack project: \(url.lastPathComponent)")
        }

        var stackDir = CLIConstants.FileConventions.DefaultDirectories.stack
        var archiveDir = CLIConstants.FileConventions.DefaultDirectories.archive
        var templateDir = CLIConstants.FileConventions.DefaultDirectories.templates

        // Parse .queuestack config file for custom directories
        if let configContent = try? String(contentsOf: configPath, encoding: .utf8) {
            for line in configContent.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("#") || trimmed.isEmpty { continue }

                if let value = Self.parseConfigValue(line: trimmed, key: "stack_dir") {
                    stackDir = value
                } else if let value = Self.parseConfigValue(line: trimmed, key: "archive_dir") {
                    archiveDir = value
                } else if let value = Self.parseConfigValue(line: trimmed, key: "template_dir") {
                    templateDir = value
                }
            }
        }

        return Project(
            name: url.lastPathComponent,
            path: url,
            stackDir: stackDir,
            archiveDir: archiveDir,
            templateDir: templateDir
        )
    }

    private static func parseConfigValue(line: String, key: String) -> String? {
        let pattern = #"^\s*\#(key)\s*=\s*"([^"]+)""#
            .replacingOccurrences(of: "#(key)", with: key)
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
            let valueRange = Range(match.range(at: 1), in: line) else
        {
            return nil
        }
        return String(line[valueRange])
    }
}
